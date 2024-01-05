// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.6;

import "./ERC20.sol";
import "./ERC20PresetMinterPauser.sol";

contract DSCPL is ERC20PresetMinterPauser {

    uint public constant INITIAL_SUPPLY = 60_000_000 * DECIMAL_MULTIPLIER;
    uint public constant MAX_SUPPLY = 1_460_000_000 * DECIMAL_MULTIPLIER;
    uint private constant DECIMAL_MULTIPLIER = 10**18;

    constructor(address _admin) ERC20PresetMinterPauser("DISCIPLINA", "DSCPL") public {
        _mint(_admin, INITIAL_SUPPLY);

        revokeRole(MINTER_ROLE, msg.sender);
        revokeRole(PAUSER_ROLE, msg.sender);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MINTER_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _admin);
    }

    function _mint(address account, uint amount) internal virtual override {
        require(totalSupply().add(amount) <= MAX_SUPPLY, 'DSCPL: MAX_SUPPLY');
        super._mint(account, amount);
    }
}
