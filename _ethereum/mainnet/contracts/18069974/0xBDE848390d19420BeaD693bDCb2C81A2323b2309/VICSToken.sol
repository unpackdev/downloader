// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./RoboFiToken.sol";

contract VICSToken is RoboFiToken, Ownable {

    constructor (uint256 initAmount_) 
        RoboFiToken("RoboFi Token", "VICS", initAmount_ * 1e18, _msgSender()) {
    }

    function mint(address to, uint256 amount) public onlyOwner virtual {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
}