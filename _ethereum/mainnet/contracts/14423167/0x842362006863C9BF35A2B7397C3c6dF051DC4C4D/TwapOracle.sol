// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import "./ITwapOracle.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./UniswapV2OracleLibrary.sol";

contract TwapOracle is ITwapOracle {
    using SafeMath for uint256;
    using SafeMath for int256;
    uint8 public immutable override xDecimals;
    uint8 public immutable override yDecimals;
    int256 public immutable override decimalsConverter;
    address public override owner;
    address public override uniswapPair;

    constructor(uint8 _xDecimals, uint8 _yDecimals) {
        require(_xDecimals <= 75 && _yDecimals <= 75, 'TO4F');
        if (_yDecimals > _xDecimals) {
            require(_yDecimals - _xDecimals <= 18, 'TO47');
        } else {
            require(_xDecimals - _yDecimals <= 18, 'TO47');
        }
        owner = msg.sender;
        xDecimals = _xDecimals;
        yDecimals = _yDecimals;
        decimalsConverter = (10**(18 + _xDecimals - _yDecimals)).toInt256();

        emit OwnerSet(msg.sender);
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TO00');
        require(_owner != address(0), 'TO02');
        require(_owner != owner, 'TO01');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    function setUniswapPair(address _uniswapPair) external override {
        require(msg.sender == owner, 'TO00');
        require(_uniswapPair != uniswapPair, 'TO01');
        require(_uniswapPair != address(0), 'TO02');
        require(isContract(_uniswapPair), 'TO0B');
        uniswapPair = _uniswapPair;

        IUniswapV2Pair pairContract = IUniswapV2Pair(_uniswapPair);
        require(
            IERC20(pairContract.token0()).decimals() == xDecimals &&
                IERC20(pairContract.token1()).decimals() == yDecimals,
            'TO45'
        );

        (uint112 reserve0, uint112 reserve1, ) = pairContract.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'TO1F');
        emit UniswapPairSet(_uniswapPair);
    }

    // based on: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2OracleLibrary.sol
    function getPriceInfo() public view override returns (uint256 priceAccumulator, uint32 priceTimestamp) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
        priceAccumulator = pair.price0CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();

        // uint32 can be cast directly until Sun, 07 Feb 2106 06:28:15 GMT
        priceTimestamp = uint32(block.timestamp);
        if (blockTimestampLast != priceTimestamp) {
            // allow overflow to stay consistent with Uniswap code and save some gas
            uint32 timeElapsed = priceTimestamp - blockTimestampLast;
            priceAccumulator += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
        }
    }

    function decodePriceInfo(bytes memory data) internal pure returns (uint256 price) {
        assembly {
            price := mload(add(data, 32))
        }
    }

    function getSpotPrice() external view override returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(uniswapPair).getReserves();
        return uint256(reserve1).mul(uint256(decimalsConverter)).div(uint256(reserve0));
    }

    function getAveragePrice(uint256 priceAccumulator, uint32 priceTimestamp) public view override returns (uint256) {
        (uint256 currentPriceAccumulator, uint32 currentPriceTimestamp) = getPriceInfo();

        require(priceTimestamp < currentPriceTimestamp, 'TO20');

        // timeElapsed = currentPriceTimestamp - priceTimestamp (overflow is desired)
        // averagePrice = (currentPriceAccumulator - priceAccumulator) / timeElapsed
        // return value = (averagePrice * decimalsConverter) / 2**112
        return
            ((currentPriceAccumulator - priceAccumulator) / (currentPriceTimestamp - priceTimestamp)).mul(
                uint256(decimalsConverter)
            ) >> 112;
    }

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256 yAfter) {
        int256 xAfterInt = xAfter.toInt256();
        int256 xBeforeInt = xBefore.toInt256();
        int256 yBeforeInt = yBefore.toInt256();
        int256 averagePriceInt = decodePriceInfo(data).toInt256();

        int256 yTradedInt = xAfterInt.sub(xBeforeInt).mul(averagePriceInt);

        // yAfter = yBefore - yTraded = yBefore - ((xAfter - xBefore) * price)
        // we are multiplying yBefore by decimalsConverter to push division to the very end
        int256 yAfterInt = yBeforeInt.mul(decimalsConverter).sub(yTradedInt).div(decimalsConverter);
        require(yAfterInt >= 0, 'TO27');
        yAfter = uint256(yAfterInt);
    }

    function tradeY(
        uint256 yAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256 xAfter) {
        int256 yAfterInt = yAfter.toInt256();
        int256 xBeforeInt = xBefore.toInt256();
        int256 yBeforeInt = yBefore.toInt256();
        int256 averagePriceInt = decodePriceInfo(data).toInt256();

        int256 xTradedInt = yAfterInt.sub(yBeforeInt).mul(decimalsConverter);

        // xAfter = xBefore - xTraded = xBefore - ((yAfter - yBefore) * price)
        // we are multiplying xBefore by averagePriceInt to push division to the very end
        int256 xAfterInt = xBeforeInt.mul(averagePriceInt).sub(xTradedInt).div(averagePriceInt);
        require(xAfterInt >= 0, 'TO28');

        xAfter = uint256(xAfterInt);
    }

    function depositTradeXIn(
        uint256 xLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256) {
        if (xBefore == 0 || yBefore == 0) {
            return 0;
        }

        // ratio after swap = ratio after second mint
        // (xBefore + xIn) / (yBefore - xIn * price) = (xBefore + xLeft) / yBefore
        // xIn = xLeft * yBefore / (price * (xLeft + xBefore) + yBefore)
        uint256 price = decodePriceInfo(data);
        uint256 numerator = xLeft.mul(yBefore);
        uint256 denominator = price.mul(xLeft.add(xBefore)).add(yBefore.mul(uint256(decimalsConverter)));
        uint256 xIn = numerator.mul(uint256(decimalsConverter)).div(denominator);

        // Don't swap when numbers are too large. This should actually never happen.
        if (xIn.mul(price).div(uint256(decimalsConverter)) >= yBefore || xIn >= xLeft) {
            return 0;
        }

        return xIn;
    }

    function depositTradeYIn(
        uint256 yLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256) {
        if (xBefore == 0 || yBefore == 0) {
            return 0;
        }

        // ratio after swap = ratio after second mint
        // (xBefore - yIn / price) / (yBefore + yIn) = xBefore / (yBefore + yLeft)
        // yIn = price * xBefore * yLeft / (price * xBefore + yLeft + yBefore)
        uint256 price = decodePriceInfo(data);
        uint256 numerator = price.mul(xBefore).mul(yLeft);
        uint256 denominator = price.mul(xBefore).add(yLeft.add(yBefore).mul(uint256(decimalsConverter)));
        uint256 yIn = numerator.div(denominator);

        // Don't swap when numbers are too large. This should actually never happen.
        if (yIn.mul(uint256(decimalsConverter)).div(price) >= xBefore || yIn >= yLeft) {
            return 0;
        }

        return yIn;
    }
}
