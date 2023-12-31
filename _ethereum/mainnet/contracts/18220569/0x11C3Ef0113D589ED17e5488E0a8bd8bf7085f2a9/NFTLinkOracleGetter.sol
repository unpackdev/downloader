// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./INFTOracleGetter.sol";
import "./IDIAOracle.sol";
import "./AddressChecksumUtils.sol";
import "./Initializable.sol";
import "./ILendPoolAddressesProvider.sol";
import "./AggregatorV3Interface.sol";
import "./Errors.sol";

contract NFTLinkOracleGetter is INFTOracleGetter, Initializable{

    ILendPoolAddressesProvider internal _addressesProvider;

    // NFT Address => Chainlink Oracle Address
    mapping(address => address) internal _oracleAddresses;
    AggregatorV3Interface internal nftFloorPriceFeed;

    modifier onlyPoolAdmin() {
        require(_addressesProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
        _;
    }

    function initialize(ILendPoolAddressesProvider provider) public initializer {
        _addressesProvider = provider;
    }

    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    /***********

    /**
     * @dev Get NFT floor price from Chainlink Oralce
     * @param asset of the NFT Oralce
     */
    function getAssetPrice( address asset) override external view returns ( uint256 ){
        address oracleAddress = _oracleAddresses[asset];
        require( oracleAddress != address(0), "NFTOracleGetter: Oracle address is not set");
        (
            /*uint80 roundID*/,
            int nftFloorPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface( oracleAddress ).latestRoundData();

        require(nftFloorPrice > 0, "NFTOracleGetter: NFT price is 0 or less than 0");
        return uint256(nftFloorPrice);
    }

    function addOracle(address asset, address oracleAddress) external onlyPoolAdmin {
        _oracleAddresses[asset] = oracleAddress;
    }
}