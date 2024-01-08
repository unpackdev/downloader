// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "./FixedPoint.sol";
import "./SafeMath.sol";

interface ExpiringContractInterface {
    function expirationTimestamp() external view returns (uint256);
}

abstract contract LongShortPairFinancialProductLibrary {
    function percentageLongCollateralAtExpiry(int256 expiryPrice) public view virtual returns (uint256);
}
