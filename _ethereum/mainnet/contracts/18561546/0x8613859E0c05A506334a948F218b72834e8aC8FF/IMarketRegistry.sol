// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IMarketRegistry {
    function getLoanActivateLimit() external view returns (uint256);

    function getLTVPercentage() external view returns (uint256);

    function isWhitelistedForActivation(address) external returns (bool);

    function getMinLoanAmountAllowed() external view returns (uint256);

    function getMultiCollateralLimit() external view returns (uint256);
}
