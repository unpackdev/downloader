// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "./ECDSAUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./FixedPoint.sol";
import "./IUniswapV2Pair.sol";

import "./OwnableUpgradeable.sol";
import "./MathUtil.sol";
import "./UniswapV2OracleLibrary.sol";

/**
 * @title PriceOracleUpgradeable
 * @dev Price oracle to calculate the mint price in ZONE. This contract is needed to avoid code size exceeds 24576 bytes
 */
contract PriceOracleUpgradeable is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using FixedPoint for *;

    // The address of the GridZone token
    address public zoneToken;

    // Flag to specify whether ZONE/ETH pool enabled
    bool public usePoolPrice;

    // LP token for ZONE/ETH
    IUniswapV2Pair public lpZoneEth;
    // ZONE reserve in ZONE/ETH
    uint256 public zoneReserveInLP;
    // ETH reserve in ZONE/ETH
    uint256 public ethReserveInLP;

    uint32  public blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    FixedPoint.uq112x112 public price0AverageLast;
    FixedPoint.uq112x112 public price1AverageLast;

    uint256 public PERIOD;

    // Events
    event SetPeriod (uint256 indexed newPeriod);
    event ActivatePoolPrice (bool newUsePoolPrice, uint256 newZoneReserveInLP, uint256 newEthReserveInLP);
    event NewZoneEthLP (address indexed newZoneEthLP);

    /**
     * @notice Initializes the contract.
     * @param _ownerAddress Address of owner
     * @param _zoneTokenAddress ZONE token address
     * @param _lpZoneEth Sushi swap LP address
     * @param _usePoolPrice Flag to specify whether ZONE/ETH pool enabled
     * @param _zoneReserveAmount ZONE reserve in ZONE/ETH
     * @param _ethReserveAmount ETH reserve in ZONE/ETH
     */
    function initialize(
        address _ownerAddress,
        address _zoneTokenAddress,
        address _lpZoneEth,
        bool _usePoolPrice,
        uint256 _zoneReserveAmount,
        uint256 _ethReserveAmount
    ) public initializer {
        require(_ownerAddress != address(0), "Owner address is invalid");
        require(_zoneTokenAddress != address(0), "ZONE token address is invalid");

        PERIOD = 24 hours;

        __Ownable_init(_ownerAddress);
        zoneToken = _zoneTokenAddress;
        _setZoneEthLP(_lpZoneEth);
        _activatePoolPrice(_usePoolPrice, _zoneReserveAmount, _ethReserveAmount);
    }

    /**
     * @dev Set the period for updating.
     */
    function setPeriod(uint256 _period) onlyOwner external {
        PERIOD = _period;
        emit SetPeriod(PERIOD);
    }

    /**
     * @dev Activate the price calculation by using ZONE/ETH SLP.
     */
    function activatePoolPrice(bool _usePoolPrice, uint256 _zoneReserveAmount, uint256 _ethReserveAmount) onlyOwner external {
        _activatePoolPrice(_usePoolPrice, _zoneReserveAmount, _ethReserveAmount);
        emit ActivatePoolPrice(usePoolPrice, zoneReserveInLP, ethReserveInLP);
    }

    function _activatePoolPrice(bool _usePoolPrice, uint256 _zoneReserveAmount, uint256 _ethReserveAmount) internal {
        if (_usePoolPrice) {
            require(address(lpZoneEth) != address(0), "Sushiswap LP token address must be valid to use the pool price");
            usePoolPrice = true;
        } else {
            require(0 < _zoneReserveAmount, "The ZONE reserve amount can not be 0");
            require(0 < _ethReserveAmount, "The ETH reserve amount can not be 0");
            usePoolPrice = false;
            zoneReserveInLP = _zoneReserveAmount;
            ethReserveInLP = _ethReserveAmount;
        }
    }

    /**
     * @dev Set the ZONE/ETH LP address.
     */
    function setZoneEthLP(address _lpZoneEth) onlyOwner external {
        _setZoneEthLP(_lpZoneEth);
        emit NewZoneEthLP(address(lpZoneEth));
    }

    function _setZoneEthLP(address _lpZoneEth) internal {
        lpZoneEth = IUniswapV2Pair(_lpZoneEth);
        if (address(lpZoneEth) != address(0)) {
            _updateFirst();
        }
    }

    function _updateFirst() internal {
        (uint112 reserve0, uint112 reserve1,) = lpZoneEth.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'No liquidity on the pool');

        price0AverageLast = FixedPoint.fraction(reserve1, reserve0);
        price1AverageLast = FixedPoint.fraction(reserve0, reserve1);

        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(lpZoneEth));
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    function update() public {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(lpZoneEth));

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        // ensure that at least one full period has passed since the last update
        require(PERIOD <= timeElapsed, 'PriceOracleUpgradeable: PERIOD_NOT_ELAPSED');

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0AverageLast = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1AverageLast = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    /**
     * @notice Get price for token from TOKEN/ETH pair
     * @param token The token
     * @return The price
     */
    function getOutAmount(address token, uint256 tokenAmount) public view returns (uint256) {
        if (address(lpZoneEth) == address(0)) {
            return 0;
        }

        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(address(lpZoneEth));

        FixedPoint.uq112x112 memory price0Average;
        FixedPoint.uq112x112 memory price1Average;
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        if (PERIOD <= timeElapsed) {
            // The average price is too old
            price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
            price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
        } else {
            price0Average = price0AverageLast;
            price1Average = price1AverageLast;
        }

        if (token == lpZoneEth.token0()) {
            return price0Average.mul(tokenAmount).decode144();
        } else {
            return price1Average.mul(tokenAmount).decode144();
        }
    }

    /**
     * @dev Take the price in ZONE for minting a token, and return it.
     */
    function mintPriceInZone(uint256 _mintPriceInEth) external returns (uint256) {
        if (_mintPriceInEth == 0) return 0;

        if (usePoolPrice && address(lpZoneEth) != address(0)) {
            uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            if (PERIOD <= timeElapsed) {
                // It's needed to update the average price
                update();
            }
            return (zoneToken == lpZoneEth.token1())
                ? price0AverageLast.mul(_mintPriceInEth).decode144()
                : price1AverageLast.mul(_mintPriceInEth).decode144();
        } else {
            if (zoneReserveInLP == 0 || ethReserveInLP == 0) return 0;
            return _mintPriceInEth.mul(zoneReserveInLP).div(ethReserveInLP);
        }
    }

    /**
     * @notice Get the fair price of a LP. We use the mechanism from Alpha Finance.
     *         Ref: https://blog.alphafinance.io/fair-lp-token-pricing/
     * @return The price in ETH
     */
    function getLPFairPrice() public view returns (uint256) {
        if (address(lpZoneEth) == address(0)) {
            return 0;
        }

        uint256 totalSupply = lpZoneEth.totalSupply();
        (uint256 r0, uint256 r1, ) = lpZoneEth.getReserves();
        uint256 sqrtR = MathUtil.sqrt(r0.mul(r1));
        uint256 p0 = 1e18; // ETH price
        uint256 p1 = getOutAmount(zoneToken, 1e18); // ZONE price in ETH
        uint256 sqrtP = MathUtil.sqrt(p0.mul(p1));
        return sqrtR.mul(sqrtP).mul(2).div(totalSupply);
    }

    uint256[39] private __gap;
}
