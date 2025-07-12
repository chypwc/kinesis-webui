// Configuration - Update this with your actual API Gateway URL
const API_GATEWAY_URL =
  "https://ainxgij6r2.execute-api.ap-southeast-2.amazonaws.com/$default/submit";

// DOM elements
const cartForm = document.getElementById("cartForm");
const clearBtn = document.getElementById("clearBtn");
const statusDisplay = document.getElementById("statusDisplay");
const responseLog = document.getElementById("responseLog");

// Initialize the application
document.addEventListener("DOMContentLoaded", function () {
  initializeApp();
});

function initializeApp() {
  // Add event listeners
  cartForm.addEventListener("submit", handleFormSubmit);
  clearBtn.addEventListener("click", clearForm);

  // Add input validation
  addInputValidation();

  // Update status
  updateStatus("Ready to send data to API Gateway", "info");
}

function addInputValidation() {
  const userIdInput = document.getElementById("userId");
  const productIdsInput = document.getElementById("productIds");

  // User ID validation
  userIdInput.addEventListener("input", function () {
    const value = this.value.trim();
    if (value && !/^\d+$/.test(value)) {
      this.setCustomValidity("User ID should contain only numbers");
    } else {
      this.setCustomValidity("");
    }
  });

  // Product IDs validation - allow empty
  productIdsInput.addEventListener("input", function () {
    const value = this.value.trim();
    if (value && !/^[A-Za-z0-9,\s]+$/.test(value)) {
      this.setCustomValidity(
        "Product IDs should contain only letters, numbers, and commas"
      );
    } else {
      this.setCustomValidity("");
    }
  });
}

async function handleFormSubmit(event) {
  event.preventDefault();

  // Get form data
  const formData = new FormData(cartForm);
  const userId = formData.get("userId").trim();
  const productIdsText = formData.get("productIds").trim();
  const eventType = formData.get("eventType");

  // Validate required fields - only User ID is required
  if (!userId) {
    updateStatus("Please enter a User ID", "error");
    return;
  }

  // Parse product IDs - allow empty array
  const productIds = productIdsText
    ? productIdsText
        .split(",")
        .map((id) => id.trim())
        .filter((id) => id)
    : [];

  // Prepare payload
  const payload = {
    user_id: parseInt(userId),
    product_ids: productIds,
    event: eventType,
    timestamp: new Date().toISOString(),
    source: "web-app",
  };

  // Show loading state
  updateStatus("Sending data to API Gateway...", "info");
  setLoadingState(true);

  try {
    // Send data to API Gateway
    const response = await sendToApiGateway(payload);

    if (response.success) {
      updateStatus(
        "Data sent successfully! Check the response log for details.",
        "success"
      );
      addResponseLog("SUCCESS", response.data, "success");
    } else {
      updateStatus(
        "Failed to send data. Check the response log for details.",
        "error"
      );
      addResponseLog("ERROR", response.error, "error");
    }
  } catch (error) {
    updateStatus("Network error. Please try again.", "error");
    addResponseLog("ERROR", error.message, "error");
  } finally {
    setLoadingState(false);
  }
}

async function sendToApiGateway(payload) {
  try {
    const response = await fetch(API_GATEWAY_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json();

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
    throw new Error(`Network error: ${error.message}`);
  }
}

function updateStatus(message, type = "info") {
  const iconMap = {
    success: "fas fa-check-circle",
    error: "fas fa-exclamation-circle",
    info: "fas fa-info-circle",
  };

  statusDisplay.innerHTML = `
        <div class="status-item">
            <i class="${iconMap[type]}"></i>
            <span>${message}</span>
        </div>
    `;
}

function addResponseLog(type, data, className) {
  const timestamp = new Date().toLocaleTimeString();
  const logEntry = document.createElement("div");
  logEntry.className = `response-item ${className}`;

  let content = "";
  if (typeof data === "object") {
    content = JSON.stringify(data, null, 2);
  } else {
    content = data;
  }

  logEntry.innerHTML = `
        <strong>[${timestamp}] ${type}:</strong><br>
        <pre>${content}</pre>
    `;

  responseLog.appendChild(logEntry);
  responseLog.scrollTop = responseLog.scrollHeight;
}

function setLoadingState(isLoading) {
  const submitBtn = cartForm.querySelector('button[type="submit"]');
  const clearBtn = document.getElementById("clearBtn");

  if (isLoading) {
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="loading"></span> Sending...';
    clearBtn.disabled = true;
  } else {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Send to Pipeline';
    clearBtn.disabled = false;
  }
}

function clearForm() {
  cartForm.reset();
  updateStatus("Form cleared. Ready to send new data.", "info");

  // Clear response log
  responseLog.innerHTML = "";
}

// Utility function to format JSON for display
function formatJSON(obj) {
  return JSON.stringify(obj, null, 2);
}

// Add some sample data functionality
function addSampleData() {
  document.getElementById("userId").value = "12345";
  document.getElementById("productIds").value = "PROD001, PROD002, PROD003";
  document.getElementById("eventType").value = "add_to_cart";
}

// Export functions for potential external use
window.CartPipeline = {
  sendToApiGateway,
  updateStatus,
  addResponseLog,
  clearForm,
  addSampleData,
};
