// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./ERC20.sol";

/* solium-disable */
contract TestToken is ERC20 {
    constructor() public ERC20("test", "TEST") {
        _setupDecimals(18);
    }

    /* test helper */
    function _mint_(address _to, uint _amount) external {
        _mint(_to, _amount);
    }

    function _burn_(address _from, uint _amount) external {
        _burn(_from, _amount);
    }

    function _approve_(
        address _from,
        address _to,
        uint _amount
    ) external {
        _approve(_from, _to, _amount);
    }
}
