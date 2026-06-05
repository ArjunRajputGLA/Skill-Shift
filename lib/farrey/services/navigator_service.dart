import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/farrey_navigator_models.dart';
import '../models/farrey_models.dart';

class NavigatorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Stream the active navigator plan for a user (Legacy/Fallback)
  Stream<FarreyNavigatorModel?> getActiveNavigator(String uid) {
    return _db
        .collection('farrey_navigator')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return FarreyNavigatorModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    });
  }

  // Get all navigators for a user
  Stream<List<FarreyNavigatorModel>> getAllNavigators(String uid) {
    return _db
        .collection('farrey_navigator')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => FarreyNavigatorModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get specific navigator by ID
  Stream<FarreyNavigatorModel?> getNavigatorById(String navigatorId) {
    return _db
        .collection('farrey_navigator')
        .doc(navigatorId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return FarreyNavigatorModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // Delete a navigator
  Future<void> deleteNavigator(String navigatorId) async {
    final batch = _db.batch();
    
    batch.delete(_db.collection('farrey_navigator').doc(navigatorId));
    
    final tasks = await _db.collection('navigator_tasks').where('navigatorId', isEqualTo: navigatorId).get();
    for (var doc in tasks.docs) {
      batch.delete(doc.reference);
    }
    
    final phases = await _db.collection('navigator_roadmap').where('navigatorId', isEqualTo: navigatorId).get();
    for (var doc in phases.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Stream roadmap phases
  Stream<List<FarreyRoadmapModel>> getRoadmap(String navigatorId) {
    return _db
        .collection('navigator_roadmap')
        .where('navigatorId', isEqualTo: navigatorId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => FarreyRoadmapModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  // Stream today's tasks
  Stream<List<FarreyTaskModel>> getTodayTasks(String navigatorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _db
        .collection('navigator_tasks')
        .where('navigatorId', isEqualTo: navigatorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FarreyTaskModel.fromMap(doc.data(), doc.id))
          .where((task) {
            if (task.date == null) return false;
            return task.date!.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
                   task.date!.isBefore(endOfDay.add(const Duration(seconds: 1)));
          })
          .toList();
    });
  }

  // Call the cloud function to generate plan
  Future<String> generateNavigatorPlan({
    required String goalTitle,
    required String currentLevel,
    required String availableHours,
    DateTime? targetDate,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateFarreyNavigatorPlan',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      
      final result = await callable.call({
        'goalTitle': goalTitle,
        'currentLevel': currentLevel,
        'availableHours': availableHours,
        'targetDateStr': targetDate?.toIso8601String(),
      });
      return result.data['navigatorId'] as String;
    } catch (e) {
      throw Exception('Failed to generate plan: $e');
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted, String navigatorId) async {
    await _db.collection('navigator_tasks').doc(taskId).update({'completed': isCompleted});

    // Recalculate progress
    final tasksSnap = await _db.collection('navigator_tasks').where('navigatorId', isEqualTo: navigatorId).get();
    if (tasksSnap.docs.isNotEmpty) {
      int total = tasksSnap.docs.length;
      int completed = tasksSnap.docs.where((d) => d.data()['completed'] == true).length;
      double progress = completed / total;
      await _db.collection('farrey_navigator').doc(navigatorId).update({'progress': progress});
    }
  }

  // Get Recommended Notes
  Stream<List<FarreyNoteModel>> getRecommendedNotes() {
    // For now we fetch random/top notes. In the future this can filter by current roadmap phase topic.
    return _db
        .collection('farrey_notes')
        .orderBy('averageRating', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FarreyNoteModel.fromMap(doc.data(), doc.id)).toList());
  }
}
