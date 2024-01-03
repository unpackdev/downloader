pragma solidity ^0.7.3;

import "./SafeMathExt.sol";

contract Products {

    struct Product {
        uint256 maxLeverage;
        uint256 spread; // in basis points. 1 UNIT = 100%
        uint256 fundingRate;  // per block, in basis points. 1 UNIT = 100%. 5760 blocks in a day for 15s blocks
        bool isDisabled;
    }

    mapping(bytes32 => Product) private products;

    address public owner;
    bool private initialized;

    event ProductRegistered(bytes32 symbol, uint256 leverage, uint256 spread, uint256 fundingRate);
    event NewLeverage(bytes32 symbol, uint256 newLeverage);
    event NewSpread(bytes32 symbol, uint256 newSpread);
    event NewFundingRate(bytes32 symbol, uint256 newFundingRate);

    function initialize() public {
        require(!initialized, '!initialized');
        initialized = true;
        owner = msg.sender;
    }

    function getMaxLeverage(
        bytes32 symbol,
        bool checkDisabled
    ) external view returns (uint256) {
        Product storage product = products[symbol];
        uint256 maxLeverage = product.maxLeverage;
        _validateProduct(maxLeverage);
        require(!checkDisabled || !product.isDisabled, '!disabled');
        return maxLeverage;
    }

    function getSpread(bytes32 symbol) external view returns (uint256) {
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        return product.spread;
    }

    function getFundingRate(bytes32 symbol) external view returns (uint256) {
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        return product.fundingRate;
    }

    function getInfo(
        bytes32 symbol,
        bool checkDisabled
    ) external view returns (uint256 maxLeverage, uint256 spread, uint256 fundingRate) {
        Product memory product = products[symbol];
        _validateProduct(product.maxLeverage);
        require(!checkDisabled || !product.isDisabled, '!disabled');
        return (product.maxLeverage, product.spread, product.fundingRate);
    }

    function disable(bytes32 symbol) external onlyOwner {
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        product.isDisabled = true;
    }

    function register(
        bytes32[] calldata symbols,
        uint256[] calldata maxLeverages,
        uint256[] calldata spreads,
        uint256[] calldata fundingRates
    ) external onlyOwner {

        require(symbols.length <= 10, '!max_length');
        require(symbols.length == maxLeverages.length && maxLeverages.length == spreads.length && spreads.length == fundingRates.length, 'Products: WRONG_LENGTH');

        for (uint256 i = 0; i < symbols.length; i++) {

            bytes32 symbol = symbols[i];
            uint256 maxLeverage = maxLeverages[i];
            uint256 spread = spreads[i];
            uint256 fundingRate = fundingRates[i];

            require(spread > 0, '!spread');
            require(maxLeverage >= SafeMathExt.UNIT8, '!leverage');
            require(symbol != bytes32(0) && symbol == bytes32(bytes12(symbol)), '!symbol');
            require(products[symbol].maxLeverage == 0, '!duplicate');

            // Set product
            products[symbol] = Product(
                maxLeverage,
                spread,
                fundingRate,
                false
            );

            // Emit event
            emit ProductRegistered(
                symbol, 
                maxLeverage, 
                spread, 
                fundingRate
            );

        }

    }

    function setLeverage(bytes32 symbol, uint256 newLeverage) external onlyOwner {
        require(newLeverage >= SafeMathExt.UNIT8, '!leverage');
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        product.maxLeverage = newLeverage;
        emit NewLeverage(symbol, newLeverage);
    }

    function updateSpread(bytes32 symbol, uint256 newSpread) external onlyOwner {
        require(newSpread > 0, '!spread');
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        product.spread = newSpread;
        emit NewSpread(symbol, newSpread);
    }

    function updateFundingRate(bytes32 symbol, uint256 newFundingRate) external onlyOwner {
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        product.fundingRate = newFundingRate;
        emit NewFundingRate(symbol, newFundingRate);
    }

    function _validateProduct(uint256 leverage) internal pure {
        require(leverage > 0, '!found');
    }

    /* Modifiers */

    modifier onlyOwner() {
        require(msg.sender == owner, '!authorized');
        _;
    }

}
