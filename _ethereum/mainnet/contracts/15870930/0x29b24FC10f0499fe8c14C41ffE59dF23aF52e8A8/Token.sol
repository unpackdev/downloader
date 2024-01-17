// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";


contract SuperYachtCoin is  ERC20, ERC20Burnable, Pausable, Ownable  {

    constructor() ERC20("Super Yacht Coin", "SYC") {}

    bool public vestingAddressLocked;

    address public vestingAddress;

    function addVesingAddress(address _vestingAddress) public onlyOwner {
        require(!vestingAddressLocked, "vesting address is already set");
        vestingAddressLocked = true;
        vestingAddress = _vestingAddress;
    }

    // @dev                                 only vesting contract can call this method
    function mint(address _to, uint _amount) public {
        require(msg.sender == vestingAddress, "Only vesting contract can call this method");
        _mint(_to, _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
