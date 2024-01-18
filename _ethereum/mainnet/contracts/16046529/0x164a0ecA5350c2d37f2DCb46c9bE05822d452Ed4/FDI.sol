//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./ERC20PresetMinterPauser.sol";

contract FDI is ERC20PresetMinterPauser, Ownable {

    string _name = "FDI";
    string _symbol = "FDI";

    constructor() ERC20PresetMinterPauser(_name, _symbol) {}

    function mint(address _to, uint256 _amount) public override {
        super.mint(_to, _amount);
    }
}