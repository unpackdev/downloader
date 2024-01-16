// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AipPool.sol";
import "./IAipPoolDeployer.sol";

contract AipPoolDeployer is IAipPoolDeployer {
    // 0: Token X, token for protection
    // 1: Token Y, protected token
    struct Parameters {
        address factory;
        address swapManager;
        address WETH9;
        address token0;
        address token1;
        uint8 frequency;
    }

    Parameters public override parameters;

    function deploy(
        address factory,
        address swapManager,
        address WETH9,
        address token0,
        address token1,
        uint8 frequency
    ) internal returns (address pool) {
        parameters = Parameters({
            factory: factory,
            swapManager: swapManager,
            WETH9: WETH9,
            token0: token0,
            token1: token1,
            frequency: frequency
        });
        pool = address(
            new AipPool{
                salt: keccak256(abi.encode(token0, token1, frequency))
            }()
        );
        delete parameters;
    }
}
