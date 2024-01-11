// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC721.sol";

abstract contract Rbn is IERC721 {
    function walletOfOwner(address _owner) public view virtual returns(uint256[] memory);
}