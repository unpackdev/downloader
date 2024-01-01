// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibProtocolStorage.sol";

interface IProtocolRegistry {
    /// @dev check fundtion token enable for staking as collateral
    /// @param _tokenAddress address of the collateral token address
    /// @return bool returns true or false value

    function isTokenEnabledForCreateLoan(
        address _tokenAddress
    ) external view returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getSingleApproveToken(
        address _tokenAddress
    ) external view returns (LibProtocolStorage.Market memory);

    function isSyntheticMintOn(address _token) external view returns (bool);

    function getSingleTokenSps(
        address _tokenAddress
    ) external view returns (address[] memory);

    function isAddedSPWallet(
        address _tokenAddress,
        address _walletAddress
    ) external view returns (bool);

    function isStableApproved(address _stable) external view returns (bool);
}
