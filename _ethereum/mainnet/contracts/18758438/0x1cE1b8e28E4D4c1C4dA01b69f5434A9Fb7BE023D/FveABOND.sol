// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ERC20.sol";
import "./Ownable.sol";

contract fVEAbond is ERC20, Ownable {
    constructor(string memory _name, string memory _symbol, uint _initialSupply) ERC20(_name, _symbol) Ownable() {
        _mint(_msgSender(), _initialSupply);
    }

    function mint(uint _amount, address _receiver) external onlyOwner {
        _mint(_receiver, _amount);
    }
}
