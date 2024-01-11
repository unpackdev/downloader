// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract PausableToken is ERC20Pausable, Ownable {

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // function __PausableToken_init(string memory name_, string memory symbol_) internal onlyInitializing {
    //     //__Ownable_init();
    //     __ERC20_init( name_, symbol_);
    // }

    constructor (string memory name_, string memory symbol_) 
    ERC20(name_, symbol_) {

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}