def test_register_and_login_flow(client):
    payload = {
        "name": "Ada Lovelace",
        "email": "ada@example.com",
        "password": "StrongPass123!",
    }

    register_response = client.post("/auth/register", json=payload)
    assert register_response.status_code == 201, register_response.text
    body = register_response.json()
    assert body["user"]["email"] == payload["email"]
    assert "access_token" in body
    assert "refresh_token" in body

    login_response = client.post(
        "/auth/login",
        json={"email": payload["email"], "password": payload["password"]},
    )
    assert login_response.status_code == 200, login_response.text
    login_body = login_response.json()
    assert "access_token" in login_body
    assert "refresh_token" in login_body


def test_profile_requires_authentication(client):
    client.post(
        "/auth/register",
        json={
            "name": "Ada Lovelace",
            "email": "ada@example.com",
            "password": "StrongPass123!",
        },
    )

    login_response = client.post(
        "/auth/login",
        json={"email": "ada@example.com", "password": "StrongPass123!"},
    )
    token = login_response.json()["access_token"]

    profile_response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert profile_response.status_code == 200, profile_response.text
    assert profile_response.json()["email"] == "ada@example.com"
