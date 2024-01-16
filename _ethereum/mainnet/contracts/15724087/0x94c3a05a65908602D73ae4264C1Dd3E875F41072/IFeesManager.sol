// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC20Upgradeable.sol";

/**
 * @dev {IFeesManager} interface:
 */
interface IFeesManager {
    function receiveFees(
        address erc11554k,
        uint256 id,
        IERC20Upgradeable asset,
        uint256 _salePrice
    ) external;

    function calculateTotalFee(
        address erc11554k,
        uint256 id,
        uint256 _salePrice
    ) external returns (uint256);

    function payGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address payer
    ) external;

    function refundGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address recipient
    ) external;

    function moveFeesBetweenGuardians(address guardianFrom, address guardianTo)
        external;
}
