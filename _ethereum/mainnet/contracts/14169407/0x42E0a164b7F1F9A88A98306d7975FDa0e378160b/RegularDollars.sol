// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//       _  _______ _____ ____    ___ _____         
//      | |/ / ____| ____|  _ \  |_ _|_   _|        
//      | ' /|  _| |  _| | |_) |  | |  | |          
//      | . \| |___| |___|  __/   | |  | |          
//      |_|\_\_____|_____|_|  _ _|___| |_|    ____  
//      |  _ \| ____/ ___| | | | |      / \  |  _ \ 
//      | |_) |  _|| |  _| | | | |     / _ \ | |_) |
//      |  _ <| |__| |_| | |_| | |___ / ___ \|  _ < 
//      |_| \_\_____\____|\___/|_____/_/   \_\_| \_\  

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";

contract RegularDollars is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool public lockedForever = false;

    constructor() ERC20("Regular Dollars", "REG") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        if (!lockedForever)
            _mint(to, amount);
        else 
            this.transfer(to,amount);
    }

    function sendFromTreasury(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        this.transfer(to,amount);
    }

    function fundTreasury(uint _amount) public onlyRole(MINTER_ROLE) {
        require(!lockedForever, 'Contract Locked!');
        mint(address(this),_amount);
    }

    function treasuryBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function lockForever() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!lockedForever, 'Contract Locked!');
        lockedForever = true;
    }
}

