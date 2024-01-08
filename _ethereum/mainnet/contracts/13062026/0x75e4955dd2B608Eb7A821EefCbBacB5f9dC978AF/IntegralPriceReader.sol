// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IIntegralFactory.sol';
import 'IIntegralPair.sol';
import 'IIntegralOracle.sol';
import 'IntegralOracleV3.sol';
import 'IntegralOracle.sol';

import 'OracleLibrary.sol';
import 'UniswapV2OracleLibrary.sol';

contract IntegralPriceReader {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;

    address public factory;
    address public owner;
    mapping(address => bool) public isOracleV3;

    event SetOracleV3(address oracle, bool isV3);
    event OwnerSet(address newOwner);

    constructor(address _factory) {
        factory = _factory;
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, 'PR_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setOracleV3(address oracle, bool isV3) external {
        require(msg.sender == owner, 'PR_FORBIDDEN');
        require(oracle != address(0), 'PR_INVALID_ORACLE');
        isOracleV3[oracle] = isV3;

        emit SetOracleV3(oracle, isV3);
    }

    function getOracle(address token0, address token1) public view returns (address oracle) {
        require(token0 != address(0) && token1 != address(0), 'PR_INVALID_TOKEN');
        address pair = IIntegralFactory(factory).getPair(token0, token1);
        require(pair != address(0), 'PR_PAIR_NOT_FOUND');
        oracle = IIntegralPair(pair).oracle();
    }

    function getPrice(address token0, address token1) external view returns (uint256 price) {
        address oracle = getOracle(token0, token1);
        if (isOracleV3[oracle]) {
            price = _getPriceV3(IntegralOracleV3(oracle));
        } else {
            price = _getPriceV2(IntegralOracle(oracle));
        }
    }

    function _getPriceV2(IntegralOracle oracle) internal view returns (uint256 price) {
        address uniswapPair = oracle.uniswapPair();
        require(uniswapPair != address(0), 'PR_INVALID_UN_PAIR');

        (uint256 multiplier, uint256 divider) = _getPriceMultipliers(oracle.xDecimals(), oracle.yDecimals());

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(uniswapPair).getReserves();
        price = reserve1.mul(ONE).mul(multiplier).div(reserve0).div(divider);
    }

    function _getPriceV3(IntegralOracleV3 oracle) internal view returns (uint256 price) {
        address uniswapPair = oracle.uniswapPair();
        require(uniswapPair != address(0), 'PR_INVALID_UNV3_PAIR');

        (uint256 multiplier, uint256 divider) = _getPriceMultipliers(oracle.xDecimals(), oracle.yDecimals());
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapPair).slot0();
        price = (uint256(sqrtPriceX96)**2).mul(ONE).mul(multiplier).div(divider) >> 192;
    }

    function _getPriceMultipliers(uint8 xDecimals, uint8 yDecimals)
        internal
        pure
        returns (uint256 multiplier, uint256 divider)
    {
        if (xDecimals > yDecimals) {
            multiplier = 10**(xDecimals - yDecimals);
            divider = 1;
        } else {
            multiplier = 1;
            divider = 10**(yDecimals - xDecimals);
        }
    }
}
