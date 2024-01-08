// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/**
 * @title ChubbyHippos contract
 * @dev Extends ERC20 Token Standard basic implementation
 */
interface IWatermelonToken {

    function init() external;

    function setNFTContractAddress(address _address) external;

    function setRate(uint rate) external;

    function reveal() external;

    function grantUpdaterRole(address _address) external;

    function revokeUpdaterRole(address _address) external;

    function grantBurnableRole(address _address) external;

    function revokeBurnableRole(address _address) external;

    function updateRewards(address from, address to) external;

    function claimReward() external;

    function burnTokens(address _address, uint amount) external;

    function burnTokensWithClaimable(address _address, uint amount) external;

    function issueTokens(address _address, uint amount) external;

    function getTotalClaimable(address _address) external view returns (uint);

    function balanceOf(address owner) external view returns (uint256);

}
