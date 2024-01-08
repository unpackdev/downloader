// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";

contract ElonsBoredXCoin is ERC20 {
    address  public owner;
    address  public contractAddr;

    modifier restricted() {
        // only owner can change
        require(msg.sender == owner,"Sender is not the creator!");
         _;
    }

    modifier contractValidate() {
        // only owner can change
        require(msg.sender == contractAddr,"Not the right contract!");
            _;
    }

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        owner = msg.sender;
    }

    function setContractAddr(address _cAddr)  external restricted{
        contractAddr = _cAddr;
    }

    function setOwnertAddr(address _owner)  external restricted{
        owner = _owner;
    }
    
    function ownerMint( uint256 supply) external restricted {
        _mint(msg.sender, supply*10**18);
    }

    function contractMint(address _mintAddr, uint256 supply) external contractValidate {
        _mint(_mintAddr, supply*10**18);
    }

}