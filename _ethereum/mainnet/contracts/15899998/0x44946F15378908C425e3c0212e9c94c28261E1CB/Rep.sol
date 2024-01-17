// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./AccessControl.sol";

contract Rep is ERC20, AccessControl {
    
    address private _multiSig;

    constructor(address addr) ERC20("RepToken", "Rep") {
        _multiSig = addr;
    }

    modifier onlyMultisig {
        require(msg.sender == _multiSig, "Not multisig!");
        _;
    }

    function transferFromMultisig() public {

    }


    //numOfTokens is whole number
    function mint(uint256 numOfTokens) public {
        uint256 decimalPlaces = 18;
        uint256 numOfTokensToMintWithDecimalPlaces = numOfTokens*10**decimalPlaces;

        _mint(msg.sender, numOfTokensToMintWithDecimalPlaces);
    }
}