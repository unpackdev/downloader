/**


                                    



*/

import "./ERC20.sol";
import "./Ownable.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract NancyPelosiINU is ERC20, Ownable {
    uint256 totalSupply_ = 200000000_000000000;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor() ERC20("NancyPelosiINU", "PELOSI") {
        _createInitialSupply(msg.sender, totalSupply_);
        _createInitialSupply(address(DEAD), totalSupply_);
        _createInitialSupply(address(this), totalSupply_);
        _burn(address(this), totalSupply_);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
