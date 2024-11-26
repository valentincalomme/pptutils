import pptutils


def test_version():
    """Check that the package has a __version__ attribute."""
    assert len(pptutils.__version__.split(".")) == 3
