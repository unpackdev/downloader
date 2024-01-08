//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;


interface IPublicSale {
    function addLiquidity() external;
    function endPublicSale() external;
    function endPrivateSale() external;
    function emergencyWithdrawFunds() external;
    function recoverERC20(address tokenAddress) external;
    function recoverLpToken(address lPTokenAddress) external;
    function addPrivateAllocations(address[] memory investors, uint256[] memory amounts) external;
    function lockCompanyTokens(address marketing, address reserve, address development) external;
    function whitelistUsers(address[] calldata users, uint256 maxEthDeposit) external;
    function getWhitelistedAmount(address user) external view returns (uint256);
    function getUserDeposits(address user) external view returns (uint256);
}