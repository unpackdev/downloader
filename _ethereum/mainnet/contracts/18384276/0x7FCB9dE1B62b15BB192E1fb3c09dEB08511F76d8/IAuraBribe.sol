// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAuraBribe {
    function depositBribeERC20(bytes32 proposal, address token, uint256 amount) external;
    function isWhitelistedToken(address token) external view returns (bool);
    function setRewardForwarding(address to) external;
    function rewardForwarding(address from) external view returns (address);
}
