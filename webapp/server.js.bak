const express = require("express");
const path = require("path");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 3001;

const API_GATEWAY_URL = 'https://kxfso9dl0a.execute-api.ap-southeast-2.amazonaws.com/$default/submit'

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// Routes
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    message: "Shopping Cart Pipeline Web App is running",
  });
});

// Start server
app.listen(PORT, () => {
  console.log(
    `🚀 Shopping Cart Pipeline Web App running on http://localhost:${PORT}`
  );
  console.log(`📡 API Gateway URL: ${API_GATEWAY_URL}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});
