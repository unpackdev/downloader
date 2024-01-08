// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "./ERC20.sol";
import "./ERC20PresetMinterPauser.sol";
import "./IBEP20Ownable.sol";
import "./IPETRO.sol";

contract PETRO is IPETRO, IBEP20Ownable, ERC20PresetMinterPauser {
    
    uint public constant override INITIAL_SUPPLY = 20_000_000 * DECIMAL_MULTIPLIER;
    uint public constant override MAX_SUPPLY = 20_000_000 * DECIMAL_MULTIPLIER;
    uint private constant DECIMAL_MULTIPLIER = 10**18;

    constructor() ERC20PresetMinterPauser("PETRO", "PETRO") public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function _mint(address account, uint amount) internal virtual override {
        require(totalSupply().add(amount) <= MAX_SUPPLY, "PETRO: MAX_SUPPLY");
        super._mint(account, amount);
    }

    function getOwner() external view override returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }
}