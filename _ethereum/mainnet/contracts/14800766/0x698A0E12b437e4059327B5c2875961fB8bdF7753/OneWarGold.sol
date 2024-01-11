// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./IOneWarGold.sol";

contract OneWarGold is IOneWarGold, ERC20 {
    address public oneWar;

    constructor() ERC20("OneWar Gold", "GOLD") {
        oneWar = msg.sender;
    }

    function mint(address _to, uint256 _value) public override {
        require(msg.sender == oneWar, "unauthorized caller");
        _mint(_to, _value);
    }

    function burn(address _from, uint256 _value) public override {
        require(msg.sender == _from || msg.sender == oneWar, "unauthorized caller");
        _burn(_from, _value);
    }
}
