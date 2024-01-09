// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IStaking {
    function depositsOf(address account)
      external 
      view 
      returns (uint256[] memory);
}