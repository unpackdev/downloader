// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./Utils.sol";
import "./IERC20.sol";

interface IPolygonMigration {
    function migrate(uint256 amount) external;

    function unmigrate(uint256 amount) external;
}

contract PolygonMigrator {
    address public immutable MATIC;
    address public immutable POL;

    constructor(address _matic, address _pol) public {
        MATIC = _matic;
        POL = _pol;
    }

    function swapOnPolygonMigrator(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    ) internal {
        _swapOnPolygonMigrator(fromToken, toToken, fromAmount, exchange);
    }

    function buyOnPolygonMigrator(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    ) internal {
        _swapOnPolygonMigrator(fromToken, toToken, fromAmount, exchange);
    }

    function _swapOnPolygonMigrator(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    ) internal {
        if (address(fromToken) == MATIC) {
            require(address(toToken) == POL, "Destination token should be POL");
            Utils.approve(exchange, address(fromToken), fromAmount);
            IPolygonMigration(exchange).migrate(fromAmount);
        } else if (address(fromToken) == POL) {
            require(address(toToken) == MATIC, "Destination token should be MATIC");
            Utils.approve(exchange, address(fromToken), fromAmount);
            IPolygonMigration(exchange).unmigrate(fromAmount);
        }
    }
}
