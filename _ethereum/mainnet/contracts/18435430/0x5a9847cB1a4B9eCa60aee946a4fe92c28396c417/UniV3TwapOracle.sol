// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./SafeMath.sol";

contract UniV3TwapOracle {
    using SafeMath for uint256;

    uint8 public constant decimals = 18;
    uint256 private constant precision = 1e18; // 10 ** decimals
    // https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FixedPoint96.sol
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    address public admin;

    address public token;
    IUniswapV3Pool public uniV3Pool;
    uint32 public twapInterval;
    bool public isToken0;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewUniV3Pool(address uniV3Pool);
    event NewTwapInterval(uint32 twapInterval);

    constructor(
        address _token,
        address _uniV3Pool,
        uint32 _twapInterval
    ) public {
        admin = msg.sender;

        token = _token;
        uniV3Pool = IUniswapV3Pool(_uniV3Pool);
        twapInterval = _twapInterval;

        isToken0 = uniV3Pool.token0() == _token;
    }

    // Returns price with "precision" decimals
    // https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/OracleLibrary.sol
    function tokenPrice() public view returns (uint256 price) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = twapInterval;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = uniV3Pool.observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int56 twapIntervalInt = int56(int32(twapInterval));

        int24 arithmeticMeanTick = int24(
            tickCumulativesDelta / twapIntervalInt
        );
        // Always round to negative infinity
        if (
            tickCumulativesDelta < 0 &&
            (tickCumulativesDelta % twapIntervalInt != 0)
        ) arithmeticMeanTick--;

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);
        price =
            (FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, Q96) * precision) /
            2 ** 96;

        if (!isToken0) {
            price = precision ** 2 / price;
        }
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = uint80(block.number);
        answer = int256(tokenPrice());
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = roundId;
    }

    function setUniV3Pool(address _uniV3Pool) external onlyAdmin {
        require(_uniV3Pool != address(0), "WRONG_VALUE");
        uniV3Pool = IUniswapV3Pool(_uniV3Pool);
        isToken0 = uniV3Pool.token0() == token;
        emit NewUniV3Pool(_uniV3Pool);
    }

    function setTwapInterval(uint32 _twapInterval) external onlyAdmin {
        twapInterval = _twapInterval;
        emit NewTwapInterval(_twapInterval);
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin may call");
        _;
    }
}
