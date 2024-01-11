//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./AggregatorV2V3Interface.sol";
import "./IBPool.sol";
import "./IBRegistry.sol";
import "./IEurPriceFeed.sol";
import "./IXTokenWrapper.sol";

interface IDecimals {
    function decimals() external view returns (uint8);
}

/**
 * @title SmtPriceFeed
 * @author Protofire
 * @dev Contract module to retrieve SMT price per asset.
 */
contract SmtPriceFeed is Ownable {
    using SafeMath for uint256;

    uint256 public constant decimals = 18;
    uint256 public constant ONE = 10**18;
    address public immutable WETH_ADDRESS;

    /// @dev Address smt
    address public smt;
    /// @dev Address of BRegistry
    IBRegistry public registry;
    /// @dev Address of EurPriceFeed module
    IEurPriceFeed public eurPriceFeed;
    /// @dev Address of XTokenWrapper module
    IXTokenWrapper public xTokenWrapper;
    /// @dev price of SMT measured in ETH stored, used to decouple price querying and calculating
    uint256 public currentPrice;

    /**
     * @dev Emitted when `registry` address is set.
     */
    event RegistrySet(address registry);

    /**
     * @dev Emitted when `eurPriceFeed` address is set.
     */
    event EurPriceFeedSet(address eurPriceFeed);

    /**
     * @dev Emitted when `smt` address is set.
     */
    event SmtSet(address smt);

    /**
     * @dev Emitted when `xTokenWrapper` address is set.
     */
    event XTokenWrapperSet(address xTokenWrapper);

    /**
     * @dev Emitted when someone executes computePrice.
     */
    event PriceComputed(address caller, uint256 price);

    /**
     * @dev Sets the values for {registry}, {eurPriceFeed} {smt} and {xTokenWrapper}.
     *
     * Sets ownership to the account that deploys the contract.
     *
     */
    constructor(
        address _registry,
        address _eurPriceFeed,
        address _smt,
        address _xTokenWrapper,
        address _wethAddress
    ) {
        _setRegistry(_registry);
        _setEurPriceFeed(_eurPriceFeed);
        _setSmt(_smt);
        _setXTokenWrapper(_xTokenWrapper);
        WETH_ADDRESS = _wethAddress;
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function setRegistry(address _registry) external onlyOwner {
        _setRegistry(_registry);
    }

    /**
     * @dev Sets `_eurPriceFeed` as the new EurPriceFeed.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_eurPriceFeed` should not be the zero address.
     *
     * @param _eurPriceFeed The address of the EurPriceFeed.
     */
    function setEurPriceFeed(address _eurPriceFeed) external onlyOwner {
        _setEurPriceFeed(_eurPriceFeed);
    }

    /**
     * @dev Sets `_smt` as the new Smt.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_smt` should not be the zero address.
     *
     * @param _smt The address of the Smt.
     */
    function setSmt(address _smt) external onlyOwner {
        _setSmt(_smt);
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function setXTokenWrapper(address _xTokenWrapper) external onlyOwner {
        _setXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function _setRegistry(address _registry) internal {
        require(_registry != address(0), "registry is the zero address");
        emit RegistrySet(_registry);
        registry = IBRegistry(_registry);
    }

    /**
     * @dev Sets `_eurPriceFeed` as the new EurPriceFeed.
     *
     * Requirements:
     *
     * - `_eurPriceFeed` should not be the zero address.
     *
     * @param _eurPriceFeed The address of the EurPriceFeed.
     */
    function _setEurPriceFeed(address _eurPriceFeed) internal {
        require(_eurPriceFeed != address(0), "eurPriceFeed is the zero address");
        emit EurPriceFeedSet(_eurPriceFeed);
        eurPriceFeed = IEurPriceFeed(_eurPriceFeed);
    }

    /**
     * @dev Sets `_smt` as the new Smt.
     *
     * Requirements:
     *
     * - `_smt` should not be the zero address.
     *
     * @param _smt The address of the Smt.
     */
    function _setSmt(address _smt) internal {
        require(_smt != address(0), "smt is the zero address");
        emit SmtSet(_smt);
        smt = _smt;
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function _setXTokenWrapper(address _xTokenWrapper) internal {
        require(_xTokenWrapper != address(0), "xTokenWrapper is the zero address");
        emit XTokenWrapperSet(_xTokenWrapper);
        xTokenWrapper = IXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Gets the price of `_asset` in SMT.
     *
     * @param _asset address of asset to get the price.
     */
    function getPrice(address _asset) external view returns (uint256) {
        uint8 assetDecimals = IDecimals(_asset).decimals();
        return calculateAmount(_asset, 10**assetDecimals);
    }

    /**
     * @dev Gets how many SMT represents the `_amount` of `_asset`.
     *
     * @param _asset address of asset to get the amount.
     * @param _assetAmountIn amount of `_asset`.
     */
    function calculateAmount(address _asset, uint256 _assetAmountIn) public view returns (uint256) {
        // pools will include the wrapepd SMT
        address xSMT = xTokenWrapper.tokenToXToken(smt);
        address xETH = xTokenWrapper.tokenToXToken(WETH_ADDRESS);

        //if same token, didn't modify the token amount
        if (_asset == xSMT) {
            return _assetAmountIn;
        }
        
        // get amount from some of the pools
        uint256 amount = getAvgAmountFromPools(_asset, xSMT, _assetAmountIn);

        // not pool with SMT/asset pair -> calculate base on SMT/ETH pool and Asset/ETH external price feed
        if (amount == 0) {
            // pools will include the wrapepd ETH
            uint256 ethSmtAmount = getAvgAmountFromPools(xETH, xSMT, ONE);

            address assetEthFeed = eurPriceFeed.getAssetFeed(_asset);

            if (assetEthFeed != address(0)) {
                // always 18 decimals
                int256 assetEthPrice = AggregatorV2V3Interface(assetEthFeed).latestAnswer();
                if (assetEthPrice > 0) {
                    uint8 assetDecimals = IDecimals(_asset).decimals();
                    uint256 assetToEthAmount = _assetAmountIn.mul(uint256(assetEthPrice)).div(10**assetDecimals);

                    amount = assetToEthAmount.mul(ethSmtAmount).div(ONE);
                }
            }
        }

        return amount;
    }

    /**
     * @dev Gets SMT/ETH based on the last executiong of computePrice.
     *
     * To be consume by EurPriceFeed module as the `assetEthFeed` from xSMT.
     */
    function latestAnswer() external view returns (int256) {
        return int256(currentPrice);
    }

    /**
     * @dev Computes SMT/ETH based on the avg price from pools containig the pair.
     *
     * To be consume by EurPriceFeed module as the `assetEthFeed` from xSMT.
     */
    function computePrice() public {
        // pools will include the wrapepd SMT and wrapped ETH
        currentPrice =
            getAvgAmountFromPools(
                xTokenWrapper.tokenToXToken(smt),
                xTokenWrapper.tokenToXToken(WETH_ADDRESS),
                ONE
            );
        emit PriceComputed(msg.sender, currentPrice);
    }

    function getAvgAmountFromPools(
        address _assetIn,
        address _assetOut,
        uint256 _assetAmountIn
    ) internal view returns (uint256) {
        address[] memory poolAddresses = registry.getBestPoolsWithLimit(_assetIn, _assetOut, 10);

        uint256 totalAmount;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            totalAmount += calcOutGivenIn(poolAddresses[i], _assetIn, _assetOut, _assetAmountIn);
        }

        return totalAmount > 0 ? totalAmount.div(poolAddresses.length) : 0;
    }

    function calcOutGivenIn(
        address poolAddress,
        address _assetIn,
        address _assetOut,
        uint256 _assetAmountIn
    ) internal view returns (uint256) {
        IBPool pool = IBPool(poolAddress);
        uint256 tokenBalanceIn = pool.getBalance(_assetIn);
        uint256 tokenBalanceOut = pool.getBalance(_assetOut);
        uint256 tokenWeightIn = pool.getDenormalizedWeight(_assetIn);
        uint256 tokenWeightOut = pool.getDenormalizedWeight(_assetOut);

        return pool.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, _assetAmountIn, 0);
    }
}
