// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";

import "./UniswapV2Helper.sol";
import "./Common.sol";

/// @title Transformable contract
/// @dev Implements a price oracle that computes the price and transforms the contract accordingly,
/// @notice Please note that the price if once met the threshold needs to be above the threshold
/// for a number of minutes for the transformation to happen
abstract contract Transformable {
    /// @notice Thrown when price of token is less than 1 dollar
    error PriceTooLow();
    /// @notice Thrown when second update is called in less than PRICE_TRANSFORMATION_INTERVAL
    error PeriodNotOver();

    uint256 public constant PRICE_TRANSFORMATION_INTERVAL = 2 minutes;
    uint256 private immutable ONE_USDT;
    uint256 private immutable ONE_NOTHING;
    uint256 private _initBlock;
    address private immutable NOTHING;
    address private immutable BASE_TOKEN;
    IUniswapV2Factory public immutable FACTORY;
    IERC20Metadata private immutable USDT;

    /// @dev Emitted when transform is initiated
    event TransformInitiated();
    /// @dev Emitted when transform is finalized
    event Transformed();

    /// @dev Constructor
    /// @param baseToken The address of the baseToken token
    /// @param usdt The total the usdt token
    /// @param factory The uniswap factory contract address
    /// @param oneNothing The one nothing token amount
    constructor(
        IERC20Metadata baseToken,
        IERC20Metadata usdt,
        IUniswapV2Factory factory,
        uint256 oneNothing
    ) {
        if (
            address(baseToken) == address(0) ||
            address(usdt) == address(0) ||
            address(factory) == address(0)
        ) {
            revert ZeroAddress();
        }
        NOTHING = address(this);
        BASE_TOKEN = address(baseToken);
        USDT = usdt;
        ONE_USDT = 10 ** USDT.decimals();
        ONE_NOTHING = oneNothing;
        FACTORY = factory;
    }

    /// @dev Initiates the transform process, only called when token price reaches 1 dollar
    function _initTransform() internal {
        uint256 priceUSDT = _getPrice();

        if (priceUSDT < ONE_USDT) {
            revert PriceTooLow();
        }
        _initBlock = block.timestamp;
        emit TransformInitiated();
    }

    /// @dev Finalizes the transform process, only called after a period of PRICE_TRANSFORMATION_INTERVAL when
    /// transform is initiated
    function _finalizeTransform() internal returns (bool) {
        uint256 blockTimestampPrev = _initBlock;

        uint256 timeElapsed = block.timestamp - blockTimestampPrev;

        if (timeElapsed < PRICE_TRANSFORMATION_INTERVAL) {
            revert PeriodNotOver();
        }
        uint256 priceUSDT = _getPrice();

        if (priceUSDT >= ONE_USDT) {
            emit Transformed();
            return true;
        }
        
        _initBlock = 0;
        return false;
    }

    /// @dev Gives the current price of token
    function _getPrice() private view returns (uint256 priceUSDT) {
        address[] memory path = new address[](3);
        path[0] = NOTHING;
        path[1] = BASE_TOKEN;
        path[2] = address(USDT);
        priceUSDT = UniswapV2Helper.getAmountsOut(FACTORY, ONE_NOTHING, path)[
            path.length - 1
        ];
    }
}
