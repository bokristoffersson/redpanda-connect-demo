# Sample Data Files

This directory contains sample data files for testing the Redpanda Connect file upload demo.

## Files

### sample-orders.csv
A CSV file containing sample order data with the following fields:
- `order_id`: Unique order identifier
- `customer_id`: Customer identifier
- `product_name`: Name of the product
- `quantity`: Number of items ordered
- `price`: Price per unit
- `status`: Order status (pending, processing, shipped, delivered)

**Use case**: Demonstrates CSV parsing, transformation to JSON, and calculated fields (total_value = quantity × price).

### sample-users.json
A JSON array containing sample user data with the following fields:
- `user_id`: Unique user identifier
- `name`: User's full name
- `email`: Email address
- `signup_date`: Date of account creation
- `account_type`: Account tier (basic, standard, premium)
- `total_orders`: Total number of orders placed

**Use case**: Demonstrates JSON parsing and processing.

## How to Use

### Via Web UI
1. Open http://localhost:8085
2. Drag and drop either file onto the upload area
3. Watch the processing happen in real-time
4. View results in Redpanda Console, MinIO, and Mock API

### Via API
```bash
# Upload CSV
curl -F "file=@sample-orders.csv" http://localhost:4195/upload

# Upload JSON
curl -F "file=@sample-users.json" http://localhost:4195/upload
```

### Expected Results

After uploading `sample-orders.csv`:
- **Redpanda Console** (http://localhost:8080): 10 messages in `files.processed` topic
- **MinIO** (http://localhost:9000): JSON file in `uploads` bucket
- **Mock API** (http://localhost:9090): Webhook notification with summary

Each CSV row becomes an individual message in Redpanda, with added metadata and calculated fields.

## Creating Your Own Test Files

### CSV Files
```csv
field1,field2,field3
value1,value2,value3
value4,value5,value6
```

**Requirements**:
- First row must be headers
- Use commas as separators
- Quote fields containing commas

### JSON Files
```json
[
  {"field1": "value1", "field2": "value2"},
  {"field1": "value3", "field2": "value4"}
]
```

**Requirements**:
- Must be a valid JSON array
- Each element represents one record
- Consistent field names recommended
