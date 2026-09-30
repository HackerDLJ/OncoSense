from app.services.longitudinal import analyze, build_baseline


def test_stable_profile_is_normal():
    history = [{
        "resting_hr": 60,
        "hrv": 55,
        "respiratory_rate": 14,
        "sleep_hours": 7.5,
        "activity_minutes": 45,
        "wrist_temperature": 36.5,
    }] * 10
    result = analyze(build_baseline(history), history[-1], persistent_days=0)
    assert result.level == "normal"
    assert result.score == 0


def test_multi_signal_persistent_change_is_flagged():
    history = [{
        "resting_hr": 60 + (i % 2),
        "hrv": 55 + (i % 2),
        "respiratory_rate": 14,
        "sleep_hours": 7.5,
        "activity_minutes": 45,
        "wrist_temperature": 36.5,
    } for i in range(14)]
    current = {
        "resting_hr": 82,
        "hrv": 30,
        "respiratory_rate": 18,
        "sleep_hours": 5.5,
        "activity_minutes": 25,
        "wrist_temperature": 36.9,
    }
    result = analyze(build_baseline(history), current, persistent_days=21)
    assert result.persistent is True
    assert result.score > 40
    assert len(result.changes) >= 3
