// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Context.sol";
import "./MintPass.sol";

abstract contract MintPassConsumer is Context {

    MintPass internal _mintPass;
    uint256 internal _mintPassPrice;

    function _setMintPass(address mintPassAddress) internal {
        _mintPass = MintPass(mintPassAddress);
    }

    function _setMintPassPrice(uint256 newMintPassPrice) internal {
        _mintPassPrice = newMintPassPrice;
    }

    function passMint(address to) external payable virtual;

    modifier hasMintPassPrice() {
        require(msg.value >= _mintPassPrice, "User has not passed in correct value");
        _;
    }

    modifier hasMintPass {
        require(_mintPass.balanceOf(_msgSender()) > 0, "Holder does not own a mint pass");
        _;
    }

}