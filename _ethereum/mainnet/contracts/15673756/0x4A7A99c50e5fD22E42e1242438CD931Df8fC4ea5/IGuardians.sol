// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IERC11554K.sol";

/**
 * @dev {IGuardians} interface:
 */
interface IGuardians {
    function controllerStoreItem(
        address collection,
        address mintAddress,
        uint256 id,
        address guardian,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount,
        uint256 numItems,
        address feePayer
    ) external;

    function controllerTakeItemOut(
        address guardian,
        address collection,
        uint256 id,
        uint256 numItems,
        address from
    ) external;

    function shiftGuardianFeesOnTokenMove(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function isAvailable(address guardian) external view returns (bool);

    function guardianInfo(address guardian)
        external
        view
        returns (
            bytes32,
            string memory,
            string memory,
            string memory,
            string memory,
            bool,
            bool
        );

    function guardianWhitelist(address guardian, address user)
        external
        view
        returns (bool);

    function delegated(address guardian) external view returns (address);

    function getRedemptionFee(address guardian, uint256 classID)
        external
        view
        returns (uint256);

    function getMintingFee(address guardian, uint256 classID)
        external
        view
        returns (uint256);

    function isClassActive(address guardian, uint256 classID)
        external
        view
        returns (bool);

    function minStorageTime() external view returns (uint256);

    function stored(
        address guardian,
        address collection,
        uint256 id
    ) external view returns (uint256);

    function whereItemStored(address collection, uint256 id)
        external
        view
        returns (address);

    function itemGuardianClass(address collection, uint256 id)
        external
        view
        returns (uint256);

    function guardianFeePaidUntil(
        address user,
        address collection,
        uint256 id
    ) external view returns (uint256);

    function isFeeAboveMinimum(
        uint256 guardianFeeAmount,
        uint256 numItems,
        address guardian,
        uint256 guardianClassIndex
    ) external view returns (bool);

    function getGuardianFeeRateByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) external view returns (uint256);

    function getGuardianFeeRate(address guardian, uint256 guardianClassIndex)
        external
        view
        returns (uint256);
}
