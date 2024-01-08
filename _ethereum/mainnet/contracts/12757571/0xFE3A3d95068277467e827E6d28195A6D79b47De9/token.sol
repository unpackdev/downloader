// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";

contract DogFundMeToken is ERC20{
    address _owner;
    uint _initialSupply;
    bool poolFunded = false;
    
    modifier onlyOwner(){
        require(msg.sender == _owner);
        _;
    }

    constructor(uint256 initialSupply) ERC20('DogFundMe', 'DFM'){
        _owner = msg.sender;
        _initialSupply = initialSupply;
        
        _mint(_owner, initialSupply);
    }
}