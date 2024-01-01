// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ICvxReward {

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);

    function getReward() external returns(bool);

    function balanceOf(address _account) external view returns(uint256);

}