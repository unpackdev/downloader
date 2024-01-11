// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IBentCVXStaking {
    function balanceOf(address _user) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function depositFor(address _user, uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function withdrawTo(address _recipient, uint256 _amount) external;

    function claimAll() external;

    function claimAllFor(address _user) external;
}
