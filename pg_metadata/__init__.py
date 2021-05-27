__copyright__ = "Copyright 2021, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"


# noinspection PyPep8Naming
def classFactory(iface):  # pylint: disable=invalid-name
    _ = iface
    from pg_metadata.pg_metadata import PgMetadata
    return PgMetadata()
