// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./AggregatorV3Interface.sol";
import "./Ownable.sol";

/// @title CurrencyOracle
/// @notice This handles all the operations related currency exchange

contract CurrencyOracle is Ownable {
    event feedAddressSet(
        address indexed feedAddress,
        bytes32 indexed fromCurrency,
        bytes32 indexed toCurrency
    );

    /// @dev mapping b/w encoded bytes32 of currecies and chainLink Date Feed proxy Address
    mapping(bytes32 => address) public dataFeedAddressMapper;

    /// @notice Allows adding mapping b/w encoded bytes32 of currecies and chainLink Date Feed proxy Address
    /// @param _fromCurrency _fromCurrency
    /// @param _toCurrency _toCurrency
    /// @param _feedAddress proxyaddress of chainLinkDataFeed

    function setOracleFeedAddress(
        bytes32 _fromCurrency,
        bytes32 _toCurrency,
        address _feedAddress
    ) external onlyOwner {
        dataFeedAddressMapper[
            keccak256(abi.encodePacked(_fromCurrency, _toCurrency))
        ] = _feedAddress;
        emit feedAddressSet(_feedAddress, _fromCurrency, _toCurrency);
    }

    /// @notice to get latest price and decimals
    /// @param _fromCurrency _fromCurrency
    /// @param _toCurrency _toCurrency
    /// @return lastestPrice  returns latest price of coversion
    /// @return decimals  returns decimals of  priceCoversion

    function getFeedLatestPriceAndDecimals(
        bytes32 _fromCurrency,
        bytes32 _toCurrency
    ) external view returns (uint64 lastestPrice, uint8 decimals) {
        address feedAddress = dataFeedAddressMapper[
            keccak256(abi.encodePacked(_fromCurrency, _toCurrency))
        ];
        require(feedAddress != address(0), "ECDE");
        AggregatorV3Interface prcieFeed = AggregatorV3Interface(feedAddress);
        (, int256 price, , , ) = prcieFeed.latestRoundData();
        return (uint64(uint256(price)), prcieFeed.decimals());
    }
}
