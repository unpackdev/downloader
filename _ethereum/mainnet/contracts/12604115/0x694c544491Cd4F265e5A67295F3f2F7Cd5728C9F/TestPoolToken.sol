// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "./PoolToken.sol";

/**
 * @dev Proxy contract to test internal variables and functions
 *      Should not be used other than in test files!
 */
contract TestPoolToken is PoolToken {
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}
