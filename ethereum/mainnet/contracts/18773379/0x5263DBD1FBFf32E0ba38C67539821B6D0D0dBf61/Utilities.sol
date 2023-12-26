// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./Strings.sol";

import "./IPool.sol";

library Utilities {
    function nameMaker(IPool _pool, uint256 factoryCount, bool fullName) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    fullName ? "Maverick Position-" : "MP-",
                    IERC20Metadata(address(_pool.tokenA())).symbol(),
                    "-",
                    IERC20Metadata(address(_pool.tokenB())).symbol(),
                    "-",
                    Strings.toString(factoryCount)
                )
            );
    }
}
