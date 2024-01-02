// interfaces/IVestingToken.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

interface IVestingWallet {
    function getLockedBalance(address _address) external view returns(uint256);
    function getReleaseableBalance(address _address) external view returns(uint256);
    function releaseBalance() external;
}