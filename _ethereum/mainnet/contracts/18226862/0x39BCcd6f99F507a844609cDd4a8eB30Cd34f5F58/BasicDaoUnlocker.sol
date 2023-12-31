// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AutomationCompatible.sol";
import "./LibBitmap.sol";

import "./D4AEnums.sol";
import "./IPDProtocolReadable.sol";
import "./IPDBasicDao.sol";

contract BasicDaoUnlocker is AutomationCompatibleInterface {
    using LibBitmap for LibBitmap.Bitmap;

    error NoUpkeepNeeded();
    error InvalidLength();

    address public immutable PROTOCOL;

    LibBitmap.Bitmap internal _daoIndexesUnlocked;

    constructor(address protocol) {
        PROTOCOL = protocol;
    }

    function checkUpkeep(bytes memory) public view returns (bool upkeepNeeded, bytes memory performData) {
        uint256 latestDaoIndex = IPDProtocolReadable(PROTOCOL).getLastestDaoIndex(uint8(DaoTag.BASIC_DAO));
        uint256[] memory daoIndexes = new uint256[](latestDaoIndex + 1);
        bytes32[] memory daoIds = new bytes32[](latestDaoIndex + 1);
        uint256 counter;
        for (uint256 i; i < latestDaoIndex; ++i) {
            if (_daoIndexesUnlocked.get(i)) continue;
            bytes32 daoId = IPDProtocolReadable(PROTOCOL).getDaoId(uint8(DaoTag.BASIC_DAO), i);

            if (daoId != 0x0 && IPDBasicDao(PROTOCOL).ableToUnlock(daoId) && !IPDBasicDao(PROTOCOL).isUnlocked(daoId)) {
                upkeepNeeded = true;
                daoIndexes[counter] = i;
                daoIds[counter] = daoId;
                counter++;
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            mstore(daoIndexes, counter)
            mstore(daoIds, counter)
        }
        performData = abi.encode(daoIndexes, daoIds);
    }

    function performUpkeep(bytes calldata performData) external {
        (bool upkeepNeeded,) = checkUpkeep(new bytes(0));
        if (!upkeepNeeded) revert NoUpkeepNeeded();

        (uint256[] memory daoIndexes, bytes32[] memory daoIds) = abi.decode(performData, (uint256[], bytes32[]));
        if (daoIndexes.length != daoIds.length) revert InvalidLength();

        uint256 length = daoIndexes.length;

        for (uint256 i; i < length;) {
            _daoIndexesUnlocked.set(daoIndexes[i]);
            IPDBasicDao(PROTOCOL).unlock(daoIds[i]);
            unchecked {
                ++i;
            }
        }
    }
}
