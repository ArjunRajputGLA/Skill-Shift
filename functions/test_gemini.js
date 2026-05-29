const { GoogleGenerativeAI } = require("@google/generative-ai");
const API_KEY = "AIzaSyDGj4uN-m8tDuUq0Hg5C1C-IGdEqwCfBaI"; 

async function test() {
  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${API_KEY}`);
    const data = await response.json();
    console.log(data.models.map(m => m.name));
  } catch(e) {
    console.error(e);
  }
}
test();
