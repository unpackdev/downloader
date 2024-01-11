// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract KRIL is ERC20,ERC20Burnable,Ownable {

    uint256 maxSupply =     1000000000000000000000000000;
    uint256 initialSupply = 100000000000000000000000000;

    mapping(address=>bool) _minters;

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _minters[msg.sender] = true;
    }

    function mint(uint256 amount) public {
        require(_minters[msg.sender],"You are not allowed to Mint");
        require(amount + totalSupply() <= maxSupply,"Max Supply Reached");
        _mint(msg.sender, amount);
    }

    function setMinter(address _address,bool _enable) public onlyOwner {
        _minters[_address] = _enable;
    }

}