pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./SUKUPriceOracleInterface.sol";
import "./ETHChainLinkPriceOracle.sol";
import "./CErc20.sol";

contract SUKUETHPriceOracle is ETHChainLinkPriceOracle, PriceOracle, SUKUPriceOracleInterface {
    mapping(address => uint) prices;
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    address public admin;

    constructor(
        address priceFeedETH_USD_,
        address priceFeedUSDC_USD_,
        address priceFeedHBAR_USD_
    ) public ETHChainLinkPriceOracle(priceFeedETH_USD_, priceFeedUSDC_USD_, priceFeedHBAR_USD_) {
        admin = msg.sender;
    }

    /// @dev Get the underlying price of a CToken contract
    function getUnderlyingPrice(CToken cToken) public view returns (uint) {
        if (compareStrings(cToken.symbol(), "sETH")) {
            return getETH_USDPrice();
        } else if (compareStrings(cToken.symbol(), "sUSDC")) {
            return getUSDC_USDPrice();
        } else if (compareStrings(cToken.symbol(), "sWHBAR")) {
            return getHBAR_USDPrice();
        } else {
            return prices[address(CErc20(address(cToken)).underlying())];
        }
    }

    /// @dev Set the price of an underlying asset based on the CToken contract address
    function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) public onlyAdmin {
        address asset = address(CErc20(address(cToken)).underlying());
        emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }

    /// @dev Set the price of an underlying asset
    function setDirectPrice(address asset, uint price) public onlyAdmin {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    /// @dev Obtain the price of an underlying asset
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    /// @dev Determine if two strings are equal
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /// @dev Update the admin address
    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}
