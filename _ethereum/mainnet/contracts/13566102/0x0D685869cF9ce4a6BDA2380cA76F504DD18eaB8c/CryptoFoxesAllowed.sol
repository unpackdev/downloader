// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ICryptoFoxesSteak.sol";

// @author: miinded.com

abstract contract CryptoFoxesAllowed is Ownable {

    mapping (address => bool) public allowedContracts;

    modifier isFoxContract() {
        require(allowedContracts[_msgSender()] == true, "Not allowed");
        _;
    }
    
    modifier isFoxContractOrOwner() {
        require(allowedContracts[_msgSender()] == true || _msgSender() == owner(), "Not allowed");
        _;
    }

    function setAllowedContract(address _contract, bool _allowed) public onlyOwner {
        allowedContracts[_contract] = _allowed;
    }

}