// SPDX-License-Identifier: MIT

/*
 _____ _ _       _     _     _____     _
|  ___| (_) __ _| |__ | |_  |_   _|__ | | _____ _ __
| |_  | | |/ _` | '_ \| __|   | |/ _ \| |/ / _ \ '_ \
|  _| | | | (_| | | | | |_    | | (_) |   <  __/ | | |
|_|   |_|_|\__, |_| |_|\__|   |_|\___/|_|\_\___|_| |_|
           |___/

*/

pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

contract FlightToken is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _amount
    ) ERC20(_name, _symbol) {
        _mint(_msgSender(), _amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        _burn(_msgSender(), _amount);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
