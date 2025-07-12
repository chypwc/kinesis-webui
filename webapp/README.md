# 🛒 Shopping Cart Pipeline Web Application

A modern web application for sending shopping cart data to AWS Kinesis via API Gateway.

## 🚀 Features

- **Modern UI**: Clean, responsive design with gradient backgrounds and smooth animations
- **Form Validation**: Real-time validation for user ID and product IDs
- **Real-time Feedback**: Live status updates and response logging
- **Multiple Event Types**: Support for add, remove, update, and checkout events
- **Error Handling**: Comprehensive error handling and user feedback

## 📋 Data Structure

The application sends the following data structure to your API Gateway:

```json
{
  "user_id": 12345,
  "product_ids": ["PROD001", "PROD002", "PROD003"],
  "event": "add_to_cart",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "source": "web-app"
}
```

## 🛠️ Installation & Setup

### Prerequisites
- Node.js (v14 or higher)
- npm or yarn

### Installation

1. **Install dependencies:**
   ```bash
   cd webapp
   npm install
   ```

2. **Start the development server:**
   ```bash
   npm start
   ```

3. **Open your browser:**
   Navigate to `http://localhost:3000`

## 🔧 Configuration

### API Gateway URL
Update the API Gateway URL in `js/app.js`:

```javascript
const API_GATEWAY_URL = 'https://your-api-gateway-url.execute-api.region.amazonaws.com/stage/submit';
```

### Environment Variables
You can set the following environment variables:
- `PORT`: Server port (default: 3000)

## 🎯 Usage

1. **Enter User ID**: A numeric identifier for the user
2. **Enter Product IDs**: Comma-separated list of product identifiers
3. **Select Event Type**: Choose the type of cart event
4. **Submit**: Click "Send to Pipeline" to send data to API Gateway

## 📊 Response Logging

The application logs all API responses in the right panel, showing:
- ✅ Success responses with Kinesis record details
- ❌ Error responses with detailed error messages
- 📊 Response timestamps and data

## 🎨 Customization

### Styling
- Modify `css/styles.css` to customize the appearance
- Uses CSS Grid and Flexbox for responsive design
- Includes smooth animations and hover effects

### Functionality
- Extend `js/app.js` to add new features
- Add new form fields by updating the HTML and JavaScript
- Implement additional validation rules

## 🔗 Integration with AWS Pipeline

This web app integrates with your existing AWS infrastructure:

```
Web App → API Gateway → Lambda → Kinesis → Firehose → S3
```

## 🚀 Deployment

### Local Development
```bash
npm run dev  # Uses nodemon for auto-reload
```

### Production
```bash
npm start
```

## 📱 Responsive Design

The application is fully responsive and works on:
- Desktop computers
- Tablets
- Mobile phones

## 🔒 Security Notes

- The web app sends data to your API Gateway endpoint
- No sensitive data is stored locally
- All communication uses HTTPS (in production)
- Consider adding authentication for production use

## 🐛 Troubleshooting

### Common Issues

1. **CORS Errors**: Ensure your API Gateway allows requests from your domain
2. **Network Errors**: Check your internet connection and API Gateway URL
3. **Validation Errors**: Ensure user ID is numeric and product IDs are properly formatted

### Debug Mode
Open browser developer tools to see detailed network requests and responses.

## 📄 License

MIT License - feel free to modify and use as needed.
