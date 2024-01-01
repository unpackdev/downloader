// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// Local imports - Structs
import "./StorageTypes.sol";

// ToDo : NatSpec + Comments

library LibStartupFundsInfo {
    bytes32 internal constant STARTUP_FUNDS_INFO_STORAGE_POSITION = keccak256("angelblock.fundraising.startup.funds.info");

    struct StartupFundsInfoStorage {
        mapping(string => StorageTypes.StartupFundsInfo) startupFundsInfo;
    }

    function startupFundsInfoStorage() internal pure returns (StartupFundsInfoStorage storage sfis) {
        bytes32 position = STARTUP_FUNDS_INFO_STORAGE_POSITION;

        assembly {
            sfis.slot := position
        }

        return sfis;
    }

    function getReclaimed(string memory _raiseId) internal view returns (bool) {
        return startupFundsInfoStorage().startupFundsInfo[_raiseId].reclaimed;
    }

    function getCollateralRefunded(string memory _raiseId) internal view returns (bool) {
        return startupFundsInfoStorage().startupFundsInfo[_raiseId].collateralRefunded;
    }

    function setCollateralRefunded(string memory _raiseId, bool _collateralRefunded) internal {
        startupFundsInfoStorage().startupFundsInfo[_raiseId].collateralRefunded = _collateralRefunded;
    }

    function setReclaimed(string memory _raiseId, bool _reclaimed) internal {
        startupFundsInfoStorage().startupFundsInfo[_raiseId].reclaimed = _reclaimed;
    }
}
