// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./Ownable.sol";

import "./IBaseOracle.sol";

interface IStake {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract ICHIOracleAggregator is Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(uint => IBaseOracle)) public oracles; // Mapping from token to (mapping from index to oracle source)
    mapping(address => uint) public oracleCount; // Mapping from token to number of sources
    mapping(address => uint) public maxPriceDeviations; // Mapping from token to max price deviation max 1000 where 1000 = 10%
    mapping(address => mapping(uint => address)) public pairs; //mapping of Liquidity pairs
    mapping(address => mapping(uint => address)) public chainlinks; //mapping of chainlink oracles for USD pricing

    uint public constant MIN_PRICE_DEVIATION = 1; // min price deviation
    uint public constant MAX_PRICE_DEVIATION = 1e4; // max price deviation

    address public ICHI = 0x903bEF1736CDdf2A537176cf3C64579C3867A881;
    address public xICHI = 0x70605a6457B0A8fBf1EEE896911895296eAB467E;

    /// @notice Set oracle primary sources for the token
    /// @param token Token address to set oracle sources
    /// @param maxPriceDeviation Max price deviation (in 1e9) for token
    /// @param oracles_ Oracle sources for the token
    /// @param pairs_ The Liquidty Pairs
    /// @param chainlinks_ Chainlink oracles to get USD price
    function setOracles(
        address token,
        uint maxPriceDeviation,
        IBaseOracle[] memory oracles_,
        address[] memory pairs_,
        address[] memory chainlinks_
    ) external onlyOwner {
        oracleCount[token] = oracles_.length;
        require(
        maxPriceDeviation >= MIN_PRICE_DEVIATION && maxPriceDeviation <= MAX_PRICE_DEVIATION,
        'bad max deviation value'
        );
        require(oracles_.length <= 3, 'oracles length exceed 3');
        maxPriceDeviations[token] = maxPriceDeviation;
        for (uint idx = 0; idx < oracles_.length; idx++) {
            require(
                token == IBaseOracle(oracles_[idx]).getBaseToken(),
                'oracle must support token'
            );
            oracles[token][idx] = oracles_[idx];
            pairs[token][idx] = pairs_[idx];
            chainlinks[token][idx] = chainlinks_[idx];
        }
    }

    /// @notice Returs ICHI price based on oracles set min 1 oracle max 3 oracles required
    function ICHIPrice() public view returns(uint price) {
        uint count = oracleCount[ICHI];
        require(count > 0, ' no oracles set');
        uint[] memory prices = new uint[](count);

        for (uint idx = 0; idx < count; idx++) {
            try oracles[ICHI][idx].getICHIPrice(pairs[ICHI][idx],chainlinks[ICHI][idx]) returns (uint px) {
                prices[idx] = normalizedToTokens(ICHI,oracles[ICHI][idx].decimals(),px);
            } catch {}
        }

        for (uint i = 0; i < count - 1; i++) {
            for (uint j = 0; j < count - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    (prices[j], prices[j + 1]) = (prices[j + 1], prices[j]);
                }
            }
        }

        uint maxPriceDeviation = maxPriceDeviations[ICHI];

        if (count == 1) {
            price = prices[0];
        } else if (count == 2) {
            uint diff;
            if (prices[0] == prices[1]) {
                diff = 0;
            } else if (prices[0] > prices[1]) {
                diff = prices[0].mul(1e4).div(prices[1]).sub(1e4);
            } else {
                diff = prices[1].mul(1e4).div(prices[0]).sub(1e4);
            }
            require(
                diff <= maxPriceDeviation,
                'too much deviation (2 valid sources)'
            );
            price = prices[0].add(prices[1]) / 2;
        } else if (count == 3) {
            bool midMinOk = prices[1].mul(1e4).div(prices[0]).sub(1e4) <= maxPriceDeviation;
            bool maxMidOk = prices[2].mul(1e4).div(prices[1]).sub(1e4) <= maxPriceDeviation;
            if (midMinOk && maxMidOk) {
                price =  prices[1]; // if 3 valid sources, and each pair is within thresh, return median
            } else if (midMinOk) {
                price = prices[0].add(prices[1]) / 2; // return average of pair within thresh
            } else if (maxMidOk) {
                price =  prices[1].add(prices[2]) / 2; // return average of pair within thresh
            } else {
                revert('too much deviation (3 valid sources)');
            }
        } else {
            revert('more than 3 valid oracles not supported');
        }
    }

    /// @notice xICHIPrice() returns the price of ICHI * ratio of xichi/ichi
    function xICHIPrice() public view returns(uint price) {
        IStake stake = IStake(xICHI);
        IERC20 ichiToken = IERC20(ICHI);

        uint256 xICHI_totalICHI = ichiToken.balanceOf(address(stake));
        uint256 xICHI_total = stake.totalSupply();
        price = xICHI_totalICHI.mul(ICHIPrice()).div(xICHI_total);
    }

    /**
     @notice converts normalized precision 18 amounts to token native precision amounts, truncates low-order values
     @param token ERC20 token contract
     @param amountNormal quantity in precision-18
     @param amountTokens quantity scaled to token decimals()
     */    
    function normalizedToTokens(address token, uint256 decimals, uint256 amountNormal) private view returns(uint256 amountTokens) {
        IERC20 t = IERC20(token);
        uint256 nativeDecimals = t.decimals();

        if(nativeDecimals == decimals) return amountNormal;
        return amountNormal / ( 10 ** (decimals - nativeDecimals));
    }
}