/**
 * Shopping Cart Pipeline Web Application
 * =====================================
 *
 * This JavaScript file handles the web application functionality for
 * sending shopping cart data to the AWS Kinesis pipeline via API Gateway.
 *
 * Features:
 * - Form validation and data processing
 * - Real-time API communication
 * - User feedback and status updates
 * - Response logging and error handling
 * - CORS-compatible requests
 *
 * Data Flow:
 * Web Form → JavaScript → API Gateway → Lambda → Kinesis → Firehose → S3
 *
 * Author: AWS Kinesis Pipeline Team
 */

// =============================================================================
// CONFIGURATION
// =============================================================================
// API Gateway endpoint URL - update this with your actual endpoint
// This URL is automatically updated by the Makefile when running 'make update-api-url'
const API_GATEWAY_URL =
  "https://2bvwwdltca.execute-api.ap-southeast-2.amazonaws.com/$default/submit";

// =============================================================================
// DOM ELEMENT REFERENCES
// =============================================================================
// Cache DOM elements for better performance
const cartForm = document.getElementById("cartForm"); // Main form element
const clearBtn = document.getElementById("clearBtn"); // Clear form button
const statusDisplay = document.getElementById("statusDisplay"); // Status message area
const responseLog = document.getElementById("responseLog"); // Response log area

// =============================================================================
// APPLICATION INITIALIZATION
// =============================================================================
// Initialize the application when DOM is fully loaded
document.addEventListener("DOMContentLoaded", function () {
  initializeApp();
});

/**
 * Initialize the web application
 * Sets up event listeners and initial state
 */
function initializeApp() {
  // Add event listeners for user interactions
  cartForm.addEventListener("submit", handleFormSubmit); // Form submission
  clearBtn.addEventListener("click", clearForm); // Clear form

  // Add real-time input validation
  addInputValidation();

  // Set initial status message
  updateStatus("Ready to send data to API Gateway", "info");
}

// =============================================================================
// FORM VALIDATION
// =============================================================================
/**
 * Add real-time validation to form inputs
 * Validates user input as the user types
 */
function addInputValidation() {
  const userIdInput = document.getElementById("userId");
  const productIdsInput = document.getElementById("productIds");

  // User ID validation - must be numeric only
  userIdInput.addEventListener("input", function () {
    const value = this.value.trim();
    if (value && !/^\d+$/.test(value)) {
      this.setCustomValidity("User ID should contain only numbers");
    } else {
      this.setCustomValidity(""); // Clear validation message
    }
  });

  // Product IDs validation - allow letters, numbers, commas, and spaces
  productIdsInput.addEventListener("input", function () {
    const value = this.value.trim();
    if (value && !/^[A-Za-z0-9,\s]+$/.test(value)) {
      this.setCustomValidity(
        "Product IDs should contain only letters, numbers, and commas"
      );
    } else {
      this.setCustomValidity(""); // Clear validation message
    }
  });
}

// =============================================================================
// FORM SUBMISSION HANDLING
// =============================================================================
/**
 * Handle form submission and send data to API Gateway
 *
 * @param {Event} event - Form submission event
 */
async function handleFormSubmit(event) {
  event.preventDefault(); // Prevent default form submission

  // =============================================================================
  // FORM DATA EXTRACTION
  // =============================================================================
  // Get form data using FormData API
  const formData = new FormData(cartForm);
  const userId = formData.get("userId").trim();
  const productIdsText = formData.get("productIds").trim();
  const eventType = formData.get("eventType");

  // =============================================================================
  // INPUT VALIDATION
  // =============================================================================
  // Validate required fields - only User ID is required
  if (!userId) {
    updateStatus("Please enter a User ID", "error");
    return;
  }

  // =============================================================================
  // PRODUCT IDS PROCESSING
  // =============================================================================
  // Parse product IDs - allow empty array for optional products
  // Split by comma, trim whitespace, and filter out empty values
  const productIds = productIdsText
    ? productIdsText
        .split(",")
        .map((id) => id.trim())
        .filter((id) => id)
    : [];

  // =============================================================================
  // PAYLOAD PREPARATION
  // =============================================================================
  // Prepare the data payload for API Gateway
  // This structure matches what the Lambda function expects
  const payload = {
    user_id: parseInt(userId), // Convert to integer
    product_ids: productIds, // Array of product IDs (can be empty)
    event: eventType, // Cart event type
    timestamp: new Date().toISOString(), // Current timestamp
    source: "web-app", // Source identifier
  };

  // =============================================================================
  // API COMMUNICATION
  // =============================================================================
  // Show loading state to user
  updateStatus("Sending data to API Gateway...", "info");
  setLoadingState(true);

  try {
    // Send data to API Gateway using fetch API
    const response = await sendToApiGateway(payload);

    // Handle response based on success/failure
    if (response.success) {
      // console.log("Response:", response);
      // console.log("Recommendations:", response.data.recommendations);
      // console.log("Recommendations data:", response.data);
      updateStatus(
        "Data sent successfully! Check the response log for details.",
        "success"
      );
      addResponseLog("SUCCESS", response.data, "success");
      if (response.data.recommendations) {
        renderRecommendations(response.data.recommendations);
      }
    } else {
      updateStatus(
        "Failed to send data. Check the response log for details.",
        "error"
      );
      addResponseLog("ERROR", response.error, "error");
    }
  } catch (error) {
    // Handle network or other errors
    updateStatus("Network error. Please try again.", "error");
    addResponseLog("ERROR", error.message, "error");
  } finally {
    // Always restore loading state
    setLoadingState(false);
  }
}

// =============================================================================
// API COMMUNICATION
// =============================================================================
/**
 * Send data to API Gateway endpoint
 *
 * @param {Object} payload - Data payload to send
 * @returns {Object} Response object with success status and data
 */
async function sendToApiGateway(payload) {
  try {
    // Make HTTP POST request to API Gateway
    const response = await fetch(API_GATEWAY_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json", // Specify JSON content type
      },
      body: JSON.stringify(payload), // Convert payload to JSON string
    });

    // Parse JSON response from API Gateway
    const data = await response.json();

    // Return structured response object
    if (response.ok) {
      return {
        success: true,
        data: data,
      };
    } else {
      return {
        success: false,
        error: data,
      };
    }
  } catch (error) {
    // Handle network errors (connection issues, CORS, etc.)
    throw new Error(`Network error: ${error.message}`);
  }
}

// =============================================================================
// USER INTERFACE UPDATES
// =============================================================================
/**
 * Update the status display with a message
 *
 * @param {string} message - Status message to display
 * @param {string} type - Message type: 'success', 'error', or 'info'
 */
function updateStatus(message, type = "info") {
  // Map message types to Font Awesome icons
  const iconMap = {
    success: "fas fa-check-circle",
    error: "fas fa-exclamation-circle",
    info: "fas fa-info-circle",
  };

  // Update the status display HTML
  statusDisplay.innerHTML = `
        <div class="status-item">
            <i class="${iconMap[type]}"></i>
            <span>${message}</span>
        </div>
    `;
}

/**
 * Add a log entry to the response log
 *
 * @param {string} type - Log entry type (SUCCESS, ERROR, INFO)
 * @param {Object|string} data - Data to log
 * @param {string} className - CSS class for styling
 */
function addResponseLog(type, data, className) {
  const timestamp = new Date().toLocaleTimeString();
  const logEntry = document.createElement("div");
  logEntry.className = `response-item ${className}`;

  // Format data for display
  let content = "";
  if (typeof data === "object") {
    content = JSON.stringify(data, null, 2); // Pretty-print JSON
  } else {
    content = data;
  }

  // Create log entry HTML
  logEntry.innerHTML = `
        <strong>[${timestamp}] ${type}:</strong><br>
        <pre>${content}</pre>
    `;

  // Add to log and scroll to bottom
  responseLog.appendChild(logEntry);
  responseLog.scrollTop = responseLog.scrollHeight;
}

// =============================================================================
// LOADING STATE MANAGEMENT
// =============================================================================
/**
 * Set loading state for form buttons
 *
 * @param {boolean} isLoading - Whether to show loading state
 */
function setLoadingState(isLoading) {
  const submitBtn = cartForm.querySelector('button[type="submit"]');
  const clearBtn = document.getElementById("clearBtn");

  if (isLoading) {
    // Disable buttons and show loading spinner
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="loading"></span> Sending...';
    clearBtn.disabled = true;
  } else {
    // Restore normal button state
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Send to Pipeline';
    clearBtn.disabled = false;
  }
}

// =============================================================================
// FORM UTILITIES
// =============================================================================
/**
 * Clear the form and reset application state
 */
function clearForm() {
  cartForm.reset(); // Reset all form fields
  updateStatus("Form cleared. Ready to send new data.", "info");

  // Clear response log
  responseLog.innerHTML = "";
}

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================
/**
 * Format JSON object for display
 *
 * @param {Object} obj - Object to format
 * @returns {string} Formatted JSON string
 */
function formatJSON(obj) {
  return JSON.stringify(obj, null, 2);
}

/**
 * Add sample data to form for testing
 */
function addSampleData() {
  document.getElementById("userId").value = "12345";
  document.getElementById("productIds").value = "PROD001, PROD002, PROD003";
  document.getElementById("eventType").value = "add_to_cart";
}

function renderRecommendations(recommendations) {
  console.log("Rendering recommendations:", recommendations);
  const container = document.getElementById("recommendations");
  if (!recommendations || recommendations.length === 0) {
    container.innerHTML = "<p>No recommendations available.</p>";
    return;
  }
  // Sort by probability descending (just in case)
  recommendations.sort((a, b) => b.probability - a.probability);
  let html = "<h2>Top 10 Product Recommendations</h2>";
  html += "<ol>";
  recommendations.forEach((rec, idx) => {
    html += `<li><strong>${rec.product_name}</strong> <br/>
      <span>Department: ${rec.department}</span> <br/>
      <span>Aisle: ${rec.aisle}</span> <br/>
      <span>Score: ${rec.probability.toFixed(3)}</span>
    </li>`;
  });
  html += "</ol>";
  container.innerHTML = html;
}

// =============================================================================
// PUBLIC API
// =============================================================================
// Export functions for potential external use or testing
window.CartPipeline = {
  sendToApiGateway,
  updateStatus,
  addResponseLog,
  clearForm,
  addSampleData,
};
