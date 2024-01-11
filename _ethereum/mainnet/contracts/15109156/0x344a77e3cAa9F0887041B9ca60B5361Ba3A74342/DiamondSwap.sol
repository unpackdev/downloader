// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
contract DiamondSwap {
    function buyNFT(address gemSwapAddress, bytes calldata callData) external payable {
        (bool success, ) = gemSwapAddress.delegatecall(callData);
        require(success);
    }
}