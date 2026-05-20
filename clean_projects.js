const mongoose = require("mongoose");
const fs = require("fs");
const path = require("path");

// 1. Load MONGO_URI from sibling .env file
const envPath = "c:\\Build-Track\\backend\\.env";
console.log("Reading environment config from:", envPath);
if (!fs.existsSync(envPath)) {
  console.error("Error: backend .env file not found!");
  process.exit(1);
}

const envContent = fs.readFileSync(envPath, "utf8");
let mongoUri = "";
envContent.split("\n").forEach((line) => {
  if (line.startsWith("MONGO_URI=")) {
    mongoUri = line.replace("MONGO_URI=", "").trim();
  }
});

if (!mongoUri) {
  console.error("Error: MONGO_URI not found in .env file!");
  process.exit(1);
}

console.log("Found MONGO_URI. Connecting to database...");

// 2. Define schemas
const ProjectSchema = new mongoose.Schema({
  projectName: String,
  createdBy: mongoose.Schema.Types.ObjectId,
}, { timestamps: true });

const TransactionSchema = new mongoose.Schema({
  project: mongoose.Schema.Types.ObjectId,
  createdBy: mongoose.Schema.Types.ObjectId,
});

const Project = mongoose.model("Project", ProjectSchema);
const Transaction = mongoose.model("Transaction", TransactionSchema);

async function run() {
  try {
    await mongoose.connect(mongoUri);
    console.log("Connected successfully to MongoDB.");

    // Fetch all projects
    const allProjects = await Project.find({}).sort({ createdAt: -1 });
    console.log(`Total projects in database: ${allProjects.length}`);

    // Group by createdBy and projectName
    const groups = {};
    allProjects.forEach((p) => {
      if (!p.projectName) return;
      const key = `${p.createdBy.toString()}||${p.projectName.trim().toLowerCase()}`;
      if (!groups[key]) {
        groups[key] = [];
      }
      groups[key].push(p);
    });

    let duplicateCount = 0;
    for (const key of Object.keys(groups)) {
      const projects = groups[key];
      if (projects.length > 1) {
        duplicateCount++;
        const keptProject = projects[0]; // Keep the first one (most recently created because of sort)
        const duplicatesToDelete = projects.slice(1);

        console.log(`\n[Group] Name: "${keptProject.projectName}", Owner: ${keptProject.createdBy}`);
        console.log(`  -> KEEPING: ${keptProject._id} (Created: ${keptProject.createdAt})`);

        // Check if kept project has transactions
        const keptTxCount = await Transaction.countDocuments({ project: keptProject._id });
        console.log(`     Has ${keptTxCount} transactions.`);

        for (const dup of duplicatesToDelete) {
          const dupTxCount = await Transaction.countDocuments({ project: dup._id });
          console.log(`  -> DELETING DUPLICATE: ${dup._id} (Created: ${dup.createdAt}) with ${dupTxCount} transactions.`);

          if (dupTxCount > 0) {
            // Re-assign transactions to the kept project
            console.log(`     Updating ${dupTxCount} transactions to point to kept project: ${keptProject._id}...`);
            const updateRes = await Transaction.updateMany(
              { project: dup._id },
              { $set: { project: keptProject._id } }
            );
            console.log(`     Successfully updated:`, updateRes);
          }

          // Delete the duplicate project
          const deleteRes = await Project.deleteOne({ _id: dup._id });
          console.log(`     Deleted duplicate project doc:`, deleteRes);
        }
      }
    }

    console.log(`\nProcessed ${duplicateCount} groups with duplicate project records.`);
  } catch (err) {
    console.error("Error during execution:", err);
  } finally {
    await mongoose.disconnect();
    console.log("Disconnected from database.");
  }
}

run();
