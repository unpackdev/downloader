// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface ILido {
    function balanceOf(address _account) external view returns (uint256);

    function getTotalPooledEther() external view returns (uint256);

    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function submit(address _referral) external payable returns (uint256 shares);
}
