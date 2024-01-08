// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract TokenDistributor is Ownable {

    using SafeERC20 for IERC20;

    constructor(address assetManager) Ownable(assetManager) {} 

    function distribute(address from, IERC20 tokenAddress, address[] calldata tos, uint[] calldata amounts) public onlyOwner {
        uint toLength = tos.length;
        for (uint i = 0; i < toLength; i++) {
            tokenAddress.safeTransferFrom(from, tos[i], amounts[i]);
        }
    }
}