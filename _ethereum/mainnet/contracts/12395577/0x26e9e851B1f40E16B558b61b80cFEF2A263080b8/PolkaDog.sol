// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "./ERC20.sol";
import "./ERC20PresetMinterPauser.sol";
import "./IPolkaDog.sol";

contract PolkaDog is IPolkaDog, ERC20PresetMinterPauser {
    
    uint public constant override INITIAL_SUPPLY = 200_000_000 * DECIMAL_MULTIPLIER;
    uint public constant override MAX_SUPPLY = 1_000_000_000 * DECIMAL_MULTIPLIER;
    uint private constant DECIMAL_MULTIPLIER = 10**18;

    constructor() ERC20PresetMinterPauser("PolkaDog", "PDOG") public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function _mint(address account, uint amount) internal virtual override {
        require(totalSupply().add(amount) <= MAX_SUPPLY, "PolkaDog: MAX_SUPPLY");
        super._mint(account, amount);
    }
}