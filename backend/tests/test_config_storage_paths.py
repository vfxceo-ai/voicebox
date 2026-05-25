from pathlib import Path

from backend import config


def test_storage_path_prefers_configured_data_dir(tmp_path):
    previous_data_dir = config.get_data_dir()
    data_dir = tmp_path / "data" / "voicebox"

    try:
        config.set_data_dir(data_dir)

        sample_path = data_dir / "profiles" / "profile-id" / "sample.wav"

        assert config.to_storage_path(sample_path) == str(
            Path("profiles") / "profile-id" / "sample.wav"
        )
    finally:
        config.set_data_dir(previous_data_dir)


def test_resolve_storage_path_rebases_legacy_nested_data_dir_name(tmp_path):
    previous_data_dir = config.get_data_dir()
    data_dir = tmp_path / "data" / "voicebox"

    try:
        config.set_data_dir(data_dir)

        legacy_path = Path("voicebox") / "profiles" / "profile-id" / "sample.wav"

        assert config.resolve_storage_path(legacy_path) == (
            data_dir / "profiles" / "profile-id" / "sample.wav"
        ).resolve()
    finally:
        config.set_data_dir(previous_data_dir)
