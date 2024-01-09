//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                               

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./Admin.sol";

// PalPool Minimal Interface
interface IPalPool {

    function exchangeRateStored() external view returns(uint);
    function exchangeRateCurrent() external returns(uint);

}

// Paladin Controller Minimal Interface
interface IPaladinController {
    
    function palTokenToPalPool(address palToken) external view returns(address);
}

interface IChainlinkAggregator {

    function decimals() external view returns (uint8);

    function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

/** @title Price Oracle for PalTokens  */
/// @author Paladin
contract PriceOracle is Admin {
    using SafeMath for uint;

    /** @notice Decimals of the palToken */
    uint256 public constant PALTOKEN_DECIMALS = 18;
    /** @dev 1e18 mantissa used for calculations */
    uint256 internal constant MANTISSA_SCALE = 1e18;

    /** @notice Address of the PaladinController */
    IPaladinController public controller;

    // Here, the asset address used as key is the address of the PalToken, but the sources
    // are price feeds for the underlying token held by a PalPool
    // If there is no valid source for the asset, the 0x000...000 address is used
    /** @dev mapping of ETH price sources */
    mapping(address => IChainlinkAggregator) private assetsSources;
    /** @dev mapping of USD price sources */
    mapping(address => IChainlinkAggregator) private assetsUSDSources;

    /** @notice Price source for the base token (ex: ETH/USD) */
    IChainlinkAggregator public baseSource;

    /** @notice Decimals used for the base Price source */
    uint256 public baseSourceDecimals;


    // Events

    event NewBaseSource(address newBaseSource);
    event NewController(address newController);

    event AssetSourceUpdated(address indexed asset, address source, address sourceUSD);


    // Constructor
    // -> If no valid price source, use address 0x00...00
    constructor(
        address[] memory _assets,
        address[] memory _sources,
        address[] memory _sourcesUSD,
        address _controller,
        address _baseSource // Chainlink Source for ETH/USD (or any other chain base currency)
    ){
        require(_assets.length == _sources.length, "PriceOracle: inequal list sizes");
        require(_assets.length == _sourcesUSD.length, "PriceOracle: inequal list sizes");

        admin = msg.sender;

        controller = IPaladinController(_controller);

        // Add each asset of the list and the sources
        for(uint i = 0; i < _assets.length; i++){
            _updateAssetSources(_assets[i], _sources[i], _sourcesUSD[i]);
        }

        baseSource = IChainlinkAggregator(_baseSource);
        baseSourceDecimals = baseSource.decimals();
    }

    /**
    * @notice Return the ETH source price for the given asset
    * @param asset Address of the palLoan
    */
    function getAssetSource(address asset) external view returns(address){
        return address(assetsSources[asset]);
    }

    /**
    * @notice Return the USD source price for the given asset
    * @param asset Address of the palLoan
    */
    function getAssetUSDSource(address asset) external view returns(address){
        return address(assetsUSDSources[asset]);
    }

    /**
    * @dev Return the address of the PalPool linked to the PalToken. Fails if the palToken is not listed
    * @param _palToken Address of the palToken
    */
    function _getPalPool(address _palToken) internal view returns(address) {
        address _palPool = controller.palTokenToPalPool(_palToken);
        require(_palPool != address(0), "PriceOracle: palToken not listed");
        return _palPool;
    }

    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //                                                  DANGER
    //
    //   The next 4 methods use exchangeRateStored() method on the PalPool to get the rate between PalToken and 
    //   underlying token. This method uses the last updated exchangeRate, stored during the last update of the Pool
    //   In case the methods are used inside anotehr smart contract, to get the correct amounts & prices, it is 
    //   strongly advised tu update the Pool state before using this oracle (see the _updateInterest() in the
    //   PalPool contract), or use the following methods:
    //     - getUpdatedAssetPrice
    //     - getUpdatedAssetUsdPrice
    //   (this methods are using exchangeRateCurrent(), that will itself call the _updateInterest() method. The update
    //   will only be done 1 time per block by the Pool)
    //
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    /**
    * @notice Return underlying amount for a given PalToken amount, based on the last updated exchangeRate
    * @param palToken Address of the palToken
    * @param amount Amount of underlying token
    */
    function underlyingForPalToken(address palToken, uint256 amount) public view returns(uint256){
        IPalPool palPool = IPalPool(_getPalPool(palToken));

        uint256 exchangeRate = palPool.exchangeRateStored();

        return amount.mul(exchangeRate).div(MANTISSA_SCALE);
    }

    /**
    * @notice Returns PalToken amount for a given underlying amount, based on the last updated exchangeRate
    * @param palToken Address of the palToken
    * @param amount Amount of palTokens
    */
    function palTokenForUnderlying(address palToken, uint256 amount) public view returns(uint256){
        IPalPool palPool = IPalPool(_getPalPool(palToken));

        uint256 exchangeRate = palPool.exchangeRateStored();

        return amount.mul(MANTISSA_SCALE).div(exchangeRate);
    }

    /**
    * @dev Return the ETH price of the asset given, based on the ETH price source and the palToken exchangeRate.
    * If no ETH price source is set, the USD price source is used, and conversion using the base (ETH/USD) source price is used
    * @param asset Address of the palToken
    * @param exchangeRate ExchangeRate of the palToken
    * @return both the price, and the decimals for the price value
    */
    function _getAssetPrice(address asset, uint256 exchangeRate) internal view returns (uint256, uint256) {
        // If an ETH price source is available
        if(address(assetsSources[asset]) != address(0)){
            // Get the decimals from the price source
            uint256 sourceDecimals = uint256(assetsSources[asset].decimals());

            // Get a valid price from the source
            (,int256 price,,,) = assetsSources[asset].latestRoundData();

            require(price > 0, "PriceOracle: incorrect price");

            // Scale the price to the palToken, based on the exchangeRate
            // And returns the price, and the decimals for the value
            return (uint256(price).mul(exchangeRate).div(MANTISSA_SCALE), sourceDecimals);
        }
        // Else, try to use an USD price source
        else if(address(assetsUSDSources[asset]) != address(0)) {
            // Get the decimals from the price source
            uint256 sourceDecimals = uint256(assetsUSDSources[asset].decimals());

            // Get a valid price from the source
            // And from the base soruce
            (,int256 usdPrice,,,) = assetsUSDSources[asset].latestRoundData();
            (,int256 baseUsdPrice,,,) = baseSource.latestRoundData();

            require(usdPrice > 0 && baseUsdPrice > 0 , "PriceOracle: incorrect price");

            // Calculate the ETH price based on the USD price and base price
            uint256 price = uint256(usdPrice).mul(10**baseSourceDecimals).div(uint256(baseUsdPrice));

            // Scale the price to the palToken, based on the exchangeRate
            // And returns the price, and the decimals for the value
            return (uint256(price).mul(exchangeRate).div(MANTISSA_SCALE), sourceDecimals);
        }
        else{
            revert("PriceOracle: no source for asset");
        }
    }

    /**
    * @dev Return the USD price of the asset given, based on the USD price source and the palToken exchangeRate.
    * If no USD price source is set, the ETH price source is used, and conversion using the base (ETH/USD) source price is used
    * @param asset Address of the palToken
    * @param exchangeRate ExchangeRate of the palToken
    * @return both the price, and the decimals for the price value
    */
    function _getAssetUSDPrice(address asset, uint256 exchangeRate) internal view returns (uint256, uint256) {
        if(address(assetsUSDSources[asset]) != address(0)){
            // Get the decimals from the price source
            uint256 sourceDecimals = uint256(assetsUSDSources[asset].decimals());

            // Get a valid price from the source
            (,int256 price,,,) = assetsUSDSources[asset].latestRoundData();

            require(price > 0, "PriceOracle: incorrect price");

            // Scale the price to the palToken, based on the exchangeRate
            // And returns the price, and the decimals for the value
            return (uint256(price).mul(exchangeRate).div(MANTISSA_SCALE), sourceDecimals);
        }
        else if(address(assetsSources[asset]) != address(0)) {
            // Get the decimals from the price source
            uint256 sourceDecimals = uint256(assetsSources[asset].decimals());

            // Get a valid price from the source
            // And from the base soruce
            (,int256 ethPrice,,,) = assetsSources[asset].latestRoundData();
            (,int256 baseUsdPrice,,,) = baseSource.latestRoundData();

            require(ethPrice > 0 && baseUsdPrice > 0 , "PriceOracle: incorrect price");

            // Calculate the USD price based on the ETH price and base price
            uint256 price = uint256(ethPrice).mul(uint256(baseUsdPrice)).div(10**baseSourceDecimals);

            // Scale the price to the palToken, based on the exchangeRate
            // And returns the price, and the decimals for the value
            return (uint256(price).mul(exchangeRate).div(MANTISSA_SCALE), sourceDecimals);
        }
        else{
            revert("PriceOracle: no source for asset");
        }
    }


    // PalToken price in ETH
    /**
    * @dev Return the ETH price of the asset given, based on the ETH price source and the palToken exchangeRate.
    * If no ETH price source is set, the USD price source is used, and conversion using the base (ETH/USD) source price is used
    * @param asset Address of the palToken
    * @return both the price, and the decimals for the price value
    */
    function getAssetPrice(address asset) public view returns (uint256, uint256) { // returns (price, decimals)
        IPalPool palPool = IPalPool(_getPalPool(asset));

        uint256 exchangeRate = palPool.exchangeRateStored();

        return _getAssetPrice(asset, exchangeRate);
    }


    // PalToken price in USD
    /**
    * @dev Return the USD price of the asset given, based on the USD price source and the palToken exchangeRate.
    * If no USD price source is set, the ETH price source is used, and conversion using the base (ETH/USD) source price is used
    * @param asset Address of the palToken
    * @return both the price, and the decimals for the price value
    */
    function getAssetUSDPrice(address asset) public view returns (uint256, uint256) { // returns (price, decimals)
        IPalPool palPool = IPalPool(_getPalPool(asset));

        uint256 exchangeRate = palPool.exchangeRateStored();

        return _getAssetUSDPrice(asset, exchangeRate);
    }

    // PalToken price in ETH (with Pool update)
    /**
    * @dev Return the ETH price of the asset given, based on the ETH price source and the updated palToken exchangeRate.
    * If no ETH price source is set, the USD price source is used, and conversion using the base (ETH/USD) source price is used
    * @param asset Address of the palToken
    * @return both the price, and the decimals for the price value
    */
    function getUpdatedAssetPrice(address asset) public returns (uint256, uint256) { // returns (price, decimals)
        IPalPool palPool = IPalPool(_getPalPool(asset));

        // Updates the PalPool state and get the exchangeRate
        uint256 exchangeRate = palPool.exchangeRateCurrent();

        return _getAssetPrice(asset, exchangeRate);
    }


    // PalToken price in USD (with Pool update)
    /**
    * @dev Return the USD price of the asset given, based on the USD price source and the updated palToken exchangeRate.
    * If no USD price source is set, the ETH price source is used, and conversion using the base (ETH/USD) source price is used
    * @param asset Address of the palToken
    * @return both the price, and the decimals for the price value
    */
    function getUpdatedAssetUSDPrice(address asset) public returns (uint256, uint256) { // returns (price, decimals)
        IPalPool palPool = IPalPool(_getPalPool(asset));

        // Updates the PalPool state and get the exchangeRate
        uint256 exchangeRate = palPool.exchangeRateCurrent();

        return _getAssetUSDPrice(asset, exchangeRate);
    }

    /**
    * @dev Adds a new asset and sources
    * @param asset Address of the palToken
    * @param source Address of the ETH price source
    * @param sourceUSD Address of the USD price source
    */
    function _updateAssetSources(address asset, address source, address sourceUSD) internal {
        assetsSources[asset] = IChainlinkAggregator(source);
        assetsUSDSources[asset] = IChainlinkAggregator(sourceUSD);

        emit AssetSourceUpdated(asset, source, sourceUSD);
    }

    // Admin methods

    /**
    * @notice Sets a new Controller address
    * @dev Sets a new Controller address
    * @param newController Address of the new Controller
    */
    function setNewController(address newController) external adminOnly {
        require(newController != address(0));
        controller = IPaladinController(newController);

        emit NewController(newController);
    }

    /**
    * @notice Sets a new address for the base price source
    * @dev Sets a new address for the base price source
    * @param newBaseSource Address of the base price source (ex: ETH/USD)
    */
    function setNewBaseSource(address newBaseSource) external adminOnly {
        require(newBaseSource != address(0));

        baseSource = IChainlinkAggregator(newBaseSource);
        baseSourceDecimals = baseSource.decimals();

        emit NewBaseSource(newBaseSource);
    }

    /**
    * @notice Adds a new asset and sources
    * @dev Adds a new asset and sources
    * @param asset Address of the palToken
    * @param source Address of the ETH price source
    * @param sourceUSD Address of the USD price source
    */
    // -> If no valid price source, use address 0x00...00
    function updateAssetSource(address asset, address source, address sourceUSD) external adminOnly {
        _updateAssetSources(asset, source, sourceUSD);
    }

}