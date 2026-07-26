import * as admin from 'firebase-admin';
import './src/firebase'; // Initialize firebase admin
import { db } from './src/firebase';

async function checkCollections() {
  try {
    const collections = await db.listCollections();
    console.log('Available collections:');
    for (const col of collections) {
      console.log(`- ${col.id}`);
      if (col.id.toLowerCase().includes('config') || col.id.toLowerCase().includes('setting')) {
        const docs = await col.limit(5).get();
        docs.forEach(doc => {
          console.log(`  Document: ${doc.id} =>`, JSON.stringify(doc.data()));
        });
      }
    }
  } catch (error) {
    console.error('Error listing collections:', error);
  }
}

checkCollections();
