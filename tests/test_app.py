import pytest
from app import app
from unittest.mock import patch

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'online'
    assert data['provisioned_by'] == 'Terraform'

@patch('app.check_db_status')
def test_health_endpoint_success(mock_db, client):
    mock_db.return_value = "Connected! PostgreSQL version: 15.1"
    
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['database'] == "Connected! PostgreSQL version: 15.1"
    assert data['service'] == "active"

@patch('app.check_db_status')
def test_health_endpoint_failure(mock_db, client):
    mock_db.return_value = "Connection failed! Check Security Groups/RDS status."
    response = client.get('/health')
    assert response.status_code == 500
    data = response.get_json()
    assert "Connection failed" in data['database']