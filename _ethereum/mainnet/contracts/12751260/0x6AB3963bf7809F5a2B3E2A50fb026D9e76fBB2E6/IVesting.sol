//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;


interface IVesting {
    function submit(address investor, uint256 amount, uint256 lockPercent) external;
    function submitMulti(address[] memory investors, uint256[] memory amounts, uint256 lockPercent) external;
    function setStart() external;
    function claimTgeTokens() external;
    function claimLockedTokens() external;
    function reset(address investor) external;
    function isPrivilegedInvestor(address account) external view returns (bool);
    function getReleasableLockedTokens(address investor) external view returns (uint256);
    function getUserData(address investor) external view returns (uint256 tgeAmount, uint256 releasedLockedTokens, uint256 totalLockedTokens);
}
