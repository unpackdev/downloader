// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC721.sol";

abstract contract Rbm is IERC721 {
    function walletOfOwner(address _owner) public view virtual returns(uint256[] memory);
    function walletOfOwnerRange(address _owner, uint256 _startIndex, uint256 _endIndex) public view virtual returns(uint256[] memory);
}