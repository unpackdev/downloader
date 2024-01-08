// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract GSCToken is ERC20, Ownable {
    constructor(address _owner, string memory name, string memory symble) ERC20(name, symble) {
        uint8 decimals = 18;
        uint256 initialSupply = 2000000000 * (10 ** uint256(decimals));
        // The initialSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.  Or the owner.
        _mint(_owner, initialSupply);
    }
//    function burn(uint256 _amount) public onlyOwner {
//        _burn(msg.sender, _amount);
//    }
}
