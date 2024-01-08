// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "./PoolTokenV2.sol";

/**
 * @dev Proxy contract to test internal variables and functions
 *      Should not be used other than in test files!
 */
contract TestPoolTokenV2 is PoolTokenV2 {
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function testMint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function testBurn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function testTransfer(
        address from,
        address to,
        uint256 amount
    ) public {
        testBurn(from, amount);
        testMint(to, amount);
    }
}
