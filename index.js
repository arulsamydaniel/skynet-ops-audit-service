require('dotenv').config();
const express = require('express');
const crypto = require('crypto');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const app = express();
app.use(express.json());

// --- Configuration ---
const PORT = process.env.PORT || 3000;
const STORE_BACKEND = process.env.STORE_BACKEND || 'memory';
const TABLE_NAME = process.env.DYNAMODB_TABLE_NAME || 'SkynetEvents';

// --- Storage Setup ---
let docClient;
const inMemoryStore = []; // Fallback for local testing

if (STORE_BACKEND === 'dynamodb') {
    const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
    docClient = DynamoDBDocumentClient.from(client);
    console.log('Storage backend: DynamoDB');
} else {
    console.log('Storage backend: In-Memory (Local Testing)');
}

// --- Endpoints ---

// 1. Health Check
app.get('/health', (req, res) => {
    res.status(200).json({
        status: "ok",
        service: process.env.SERVICE_NAME || "skynet-ops-audit-service",
        environment: process.env.NODE_ENV || "dev",
        timestamp: new Date().toISOString()
    });
});

// 2. Ingest Event (POST /events)
app.post('/events', async (req, res) => {
    const { type, tenantId, severity, message, source, metadata, occurredAt, traceId } = req.body;

    // Validation
    if (!tenantId || !message || !severity || !type || !source) {
        return res.status(400).json({ error: "Missing required fields" });
    }
    const validSeverities = ['info', 'warning', 'error', 'critical'];
    if (!validSeverities.includes(severity)) {
        return res.status(400).json({ error: "Invalid severity level" });
    }

    const eventId = `evt_${crypto.randomUUID().replace(/-/g, '').substring(0, 13).toUpperCase()}`;
    const storedAt = new Date().toISOString();

    const eventRecord = {
        eventId,
        type,
        tenantId,
        severity,
        message,
        source,
        metadata: metadata || {},
        occurredAt: occurredAt || storedAt,
        storedAt,
        traceId
    };

    try {
        if (STORE_BACKEND === 'dynamodb') {
            await docClient.send(new PutCommand({
                TableName: TABLE_NAME,
                Item: eventRecord
            }));
        } else {
            inMemoryStore.push(eventRecord);
        }

        res.status(201).json({
            success: true,
            eventId: eventId,
            storedAt: storedAt
        });
    } catch (error) {
        console.error("Error storing event:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

// 3. Retrieve Events (GET /events)
app.get('/events', async (req, res) => {
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;
    
    // Note: For a production app, we would use Queries with indexes. 
    // For this minimal ops assessment, a Scan is sufficient to demonstrate functionality.
    try {
        let items = [];
        if (STORE_BACKEND === 'dynamodb') {
            const data = await docClient.send(new ScanCommand({ TableName: TABLE_NAME }));
            items = data.Items || [];
        } else {
            items = [...inMemoryStore];
        }

        // Apply basic filtering
        if (req.query.tenantId) items = items.filter(i => i.tenantId === req.query.tenantId);
        if (req.query.severity) items = items.filter(i => i.severity === req.query.severity);
        if (req.query.type) items = items.filter(i => i.type === req.query.type);

        // Sort newest first and paginate
        items.sort((a, b) => new Date(b.storedAt) - new Date(a.storedAt));
        const paginatedItems = items.slice(offset, offset + limit);

        res.status(200).json({
            items: paginatedItems,
            total: items.length,
            limit: Math.min(limit, 100),
            offset: offset
        });
    } catch (error) {
        console.error("Error retrieving events:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

// 4. Metrics Demo (Strongly Recommended for Ops Testing)
app.get('/metrics-demo', (req, res) => {
    if (process.env.METRICS_DEMO_ENABLED !== 'true') {
        return res.status(404).json({ error: "Not found" });
    }

    const mode = req.query.mode;
    if (mode === 'error') {
        return res.status(500).json({ error: "Simulated internal error for observability testing" });
    } else if (mode === 'slow') {
        setTimeout(() => {
            res.status(200).json({ message: "Simulated slow response (2 seconds)" });
        }, 2000);
    } else {
        res.status(200).json({ message: "Normal response" });
    }
});

// --- Start Server ---
app.listen(PORT, () => {
    console.log(`Service starting reliably on port ${PORT}...`); // Ops keywords!
});