// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC20Proxied.sol";

import "./IMapleTokenInitializer.sol";

contract MapleTokenInitializer is IMapleTokenInitializer, ERC20Proxied {

    uint256 internal constant INITIAL_MINT_MIGRATOR = 10_000_000e18;
    uint256 internal constant INITIAL_MINT_TREASURY = 1_000_000e18;

    function initialize(address migrator_, address treasury_) external {
        name     = "Maple Token";
        symbol   = "MPL";
        decimals = 18;

        emit Initialized(migrator_, treasury_);

        _mint(migrator_, INITIAL_MINT_MIGRATOR);
        _mint(treasury_, INITIAL_MINT_TREASURY);
    }

}
