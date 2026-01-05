/**
 * Puzzle Upload Script for Daily Doublet
 *
 * Usage:
 * 1. Install dependencies: npm install firebase-admin
 * 2. Download service account key from Firebase Console:
 *    - Go to Project Settings > Service Accounts
 *    - Click "Generate new private key"
 *    - Save as tools/service-account-key.json
 * 3. Run: node tools/upload_puzzles.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin with service account
const serviceAccountPath = path.join(__dirname, 'service-account-key.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Error: service-account-key.json not found!');
  console.error('');
  console.error('To get your service account key:');
  console.error('1. Go to Firebase Console > Project Settings > Service Accounts');
  console.error('2. Click "Generate new private key"');
  console.error('3. Save the file as tools/service-account-key.json');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function uploadPuzzles() {
  // Read CSV file
  const csvPath = path.join(__dirname, '../lib/doublet.csv');

  if (!fs.existsSync(csvPath)) {
    console.error('Error: lib/doublet.csv not found!');
    process.exit(1);
  }

  const content = fs.readFileSync(csvPath, 'utf-8');
  const lines = content.trim().split('\n');

  console.log(`Found ${lines.length} puzzles`);

  // Batch write (Firestore limit: 500 per batch)
  const batchSize = 500;
  let totalUploaded = 0;

  for (let i = 0; i < lines.length; i += batchSize) {
    const batch = db.batch();
    const chunk = lines.slice(i, i + batchSize);

    chunk.forEach((line, chunkIndex) => {
      const puzzleIndex = i + chunkIndex;
      const words = line
        .split(',')
        .map(word => word.trim().toUpperCase())
        .filter(word => word.length > 0);

      if (words.length < 2) {
        console.warn(`Skipping puzzle ${puzzleIndex}: insufficient words`);
        return;
      }

      const docRef = db.collection('puzzles').doc(puzzleIndex.toString());

      batch.set(docRef, {
        index: puzzleIndex,
        ladder: words,
        wordLength: words[0].length,
        stepCount: words.length,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      totalUploaded++;
    });

    await batch.commit();
    console.log(`Uploaded puzzles ${i} to ${Math.min(i + batchSize - 1, lines.length - 1)}`);
  }

  // Store metadata config
  await db.collection('config').doc('puzzles').set({
    totalCount: totalUploaded,
    epochDate: admin.firestore.Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('');
  console.log('='.repeat(50));
  console.log(`Upload complete! ${totalUploaded} puzzles uploaded.`);
  console.log('='.repeat(50));
  console.log('');
  console.log('Next steps:');
  console.log('1. Set up Firestore security rules in Firebase Console');
  console.log('2. Run: flutter pub get');
  console.log('3. Run: flutter run');
}

uploadPuzzles().catch(error => {
  console.error('Upload failed:', error);
  process.exit(1);
});
