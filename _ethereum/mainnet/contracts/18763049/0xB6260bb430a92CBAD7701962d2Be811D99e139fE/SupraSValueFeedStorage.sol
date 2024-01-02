// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ISupraSValueFeedVerifier.sol";
import "./Ownable2StepUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/// @title Supra Oracle Value Feed Storage Contract
/// @author Supra developer
/// @notice This contract is used for to storing the exchange rate of trading pairs
/// @dev All function calls are currently implemented without side effects
contract SupraSValueFeedStorage is Ownable2StepUpgradeable,UUPSUpgradeable {


    /// @dev To extract the ROUND data of a pair ID on that particular location of the word (32 byte).
    uint256 constant private ROUND=0xffffffffffffffff000000000000000000000000000000000000000000000000;
    /// @dev To extract the DECIMAL data of a pair ID on that particular location of the word (32 byte).
    uint256 constant private DECIMAL=0x0000000000000000ff0000000000000000000000000000000000000000000000;
    /// @dev To extract the TIMESTAMP data of a pair ID on that particular location of the word (32 byte).
    uint256 constant private TIMESTAMP=0x000000000000000000ffffffffffffffff000000000000000000000000000000;
    /// @dev To extract the PRICE data of a pair ID on that particular location of the word (32 byte).
    uint256 constant private PRICE=0x0000000000000000000000000000000000ffffffffffffffffffffffff000000;
    /// @dev To extract the HCC data of a pair ID on that particular location of the word (32 byte).
    uint256 constant private HCC=0x0000000000000000000000000000000000000000000000000000000000ff0000;
    /// @dev Keeping the decimal for the derived prices as 18.
    uint256 constant private MAX_DECIMAL = 18;


    /// @notice Structure of the Unpacked data that does not need HCC validation check data
    struct priceFeed {
        uint256 round;
        uint256 decimals;
        uint256 time;
        uint256 price;

    }

    /// @notice Structure to Provide the derived prices data
    struct derivedData{
        int256 roundDifference;
        uint256 derivedPrice;
        uint256 decimals;
    }

    /// @notice Currently Deprecated Structure to store the Derived Pairs
    /// @dev We need to keep this just to avoid storage collision
    struct derivedPair {
        uint256 basePairId;
        uint256 quotePairId;
        uint256 operation;
    }


    /// @notice It is address of Verifier contract of SupraOracle
    /// @dev It stores contract address of Verifier contract
    address public supraSValueFeedVerifier;
    /// @dev Storing the packed data of a particular pairID
    mapping(uint256 => bytes32) supraStorage;
    /// @notice Currently Deprecated Storing the derived pair info data
    /// @dev We need to keep this just to avoid storage collision
    mapping(uint256 => derivedPair) public derivedPairs;
    // @notice It is address of Oracle PUll contract of SupraOracle
    /// @dev It stores contract address of DORA pull contract
    address public supraPull;


    error InvalidVerifier();
    error InvalidPull();
    error InvalidOperation();
    error UnauthorisedAccess();
    error PairIdIsAbsentForHCC();
    error PairIdsAreAbsentForHCC();
    error DerivedPairNotAvailable(uint256 pairId);
    error ArrayLengthMismatched();
    error InvalidDerivedPair();

    modifier onlySupraVerifierOrSupraPull() {
        if (msg.sender != supraSValueFeedVerifier && msg.sender != supraPull){
                  revert UnauthorisedAccess();
        }
        _;

    }

    event SupraSValueVerifierUpdated(address _updatedVerifierAddress);
    event SupraPullUpdated(address _updatedPullAddress);


    /// @notice This function will work similar to Constructor as we cannot use constructor while using proxy
    /// @dev Initialize the respective variables once and behaves similar to constructor
    function initialize() public initializer {
        Ownable2StepUpgradeable.__Ownable2Step_init();
    }



    /// @notice Helper function for upgradability
    /// @dev While upgrading using UUPS proxy interface, when we call upgradeTo(address) function
    /// @dev we need to check that only owner can upgrade
    /// @param newImplementation address of the new implementation contract
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}


    /// @notice This function will help to find the prices of the derived pairs
    /// @dev Derived pairs are the one whose price info is calculated using two compatible pairs using either multiplication or division.
    /// @param pair_id_1 the base pair id
    /// @param pair_id_2 the qoute pair id
    /// @return derivedData the structured derived price data
    function getDerivedSvalue(uint256 pair_id_1,uint256 pair_id_2,uint256 operation) external view returns (derivedData memory) {
        (uint256 _round1,uint256 _decimal1,,uint256 _price1)=_unPackData(uint256(supraStorage[pair_id_1]));
        (uint256 _round2,uint256 _decimal2,,uint256 _price2)=_unPackData(uint256(supraStorage[pair_id_2]));
        uint256 derivedPrice;
        //0->Multiplication 1->Division else->Invalid
        if(operation==0){
            if((_decimal1+_decimal2)>MAX_DECIMAL){
                derivedPrice = (_price1*_price2)/(10**((_decimal1+_decimal2)-MAX_DECIMAL));
            }
            else{
                derivedPrice = (_price1*_price2)*10**(MAX_DECIMAL-(_decimal1+_decimal2));
            }
        }
        else if(operation==1){
            derivedPrice = (_scalePrice(_price1,_decimal1)*10**MAX_DECIMAL)/_scalePrice(_price2,_decimal2);
        }
        else {
            revert InvalidOperation();
        }
        return derivedData(int256(int256(_round1)-int256(_round2)),derivedPrice,MAX_DECIMAL);
    }


    /// @notice Get the all the data for a single trading pair.
    /// @dev It takes the data of a pair ID from supraStorage variable
    /// @dev Unpacks them and returns in a structure format
    /// @param _pairIndex The index of the trading pair.
    /// @return The structured data without HCC
    function getSvalue(uint256 _pairIndex)
    external
    view
    returns (priceFeed memory)
    {
        (uint256 _round,uint256 _decimal,uint256 _timestamp,uint256 _price)=_unPackData(uint256(supraStorage[_pairIndex]));
        return priceFeed(_round,_decimal,_timestamp,_price);
    }



    /// @notice Get the all the data for Multiple trading pairs.
    /// @dev It takes the data of a multiple pair IDs from supraStorage variable
    /// @dev Unpacks them and returns in a array of structure format
    /// @param _pairIndexes The list of indexes of trading pairs.
    /// @return The array of structured data without HCC
    function getSvalues(uint256[] memory _pairIndexes)
    external
    view
    returns (priceFeed[] memory)
    {
        priceFeed[] memory storedata = new priceFeed[](_pairIndexes.length);
        for (uint256 loop = 0; loop < _pairIndexes.length; ++loop) {
            (uint256 _round,uint256 _decimal,uint256 _timestamp,uint256 _price)=_unPackData(uint256(supraStorage[_pairIndexes[loop]]));
            storedata[loop] = priceFeed(_round,_decimal,_timestamp,_price);
        }
        return (storedata);
    }




    /// @notice Get the exchange rate value and availability status for a single trading pair.
    /// @param _pairIndex The index of the trading pair.
    /// @return The exchange rate value and a flag indicating if the value is available or not.
    function getSvalue(uint64 _pairIndex)
    external
    view
    returns (bytes32, bool)
    {
        bool flag;
        if (supraStorage[_pairIndex] == bytes32(0)) {
            flag = true;
        }
        return (supraStorage[_pairIndex], flag);
    }

    /// @notice Get the exchange rate values and availability statuses for multiple trading pairs.
    /// @param _pairIndexes An array of trading pair indexes.
    /// @return An array of exchange rate values and an array of flags indicating if the values are available or not.
    function getSvalues(uint64[] memory _pairIndexes)
    external
    view
    returns (bytes32[] memory, bool[] memory)
    {
        bytes32[] memory storedata = new bytes32[](_pairIndexes.length);
        bool[] memory flags = new bool[](_pairIndexes.length);
        for (uint256 loop = 0; loop < _pairIndexes.length; ++loop) {
            storedata[loop] = supraStorage[_pairIndexes[loop]];
            if (supraStorage[_pairIndexes[loop]] == bytes32(0)) {
                flags[loop] = true;
            }
        }
        return (storedata, flags);
    }


    /// @notice Update the address of the Supra Oracle Verifier contract.
    /// @param _supraSValueFeedVerifier The new address of the SupraOracle Verifier contract.
    /// @dev Only the owner of this contract can update the verifier address.
    function updateSupraSValueFeedVerifier(address _supraSValueFeedVerifier)
    public
    onlyOwner
    {
        if (_supraSValueFeedVerifier == address(0)) {
            revert InvalidVerifier();
        }
        supraSValueFeedVerifier = _supraSValueFeedVerifier;

        emit SupraSValueVerifierUpdated(_supraSValueFeedVerifier);
    }

    /// @notice Update the address of the Supra Oracle Pull contract.
    /// @param _supraPull The new address of the SupraOracle Pull contract.
    /// @dev Only the owner of this contract can update the Pull address.
    function updateSupraPull(address _supraPull)
    external
    onlyOwner
    {
        if (_supraPull == address(0)) {
            revert InvalidPull();
        }
        supraPull = _supraPull;

        emit SupraPullUpdated(_supraPull);
    }

    /// @notice Set the exchange rate value for a specific trading pair.
    /// @param _index The index of the trading pair.
    /// @param _bytes The exchange rate value to be set.
    /// @dev This function is restricted to the Supra Oracle Verifier contract.
    ///      It is used to set the exchange rate value for a trading pair.
    function restrictedSetSupraStorage(uint256 _index, bytes32 _bytes)
    external
    onlySupraVerifierOrSupraPull
    {
        supraStorage[_index] = _bytes;
    }

    /// @notice It helps to find the last timestamp on which the data of a pairId is updated.
    function getTimestamp(uint256 _tradingPair)
    external
    view
    returns (uint256)
    {
        return (uint256(supraStorage[_tradingPair]) & TIMESTAMP)>>120;
    }




    /// @notice It helps to Unpack one single word (32 bytes) into many data points 
    /// @dev This function will take one word data in uint256 format, 
    /// @dev Will do unary AND with the particular constants defined 
    /// @dev Will shift the value to the lower bit.
    /// @param data Packed data of a pairID
    /// @return Tuple of uint256 representing round,decimal,timestamp,price,hcc
    function _unPackData(
        uint256 data
    ) internal pure returns (uint256,uint256,uint256,uint256) {

        return (uint256(data & ROUND)>>192,uint256(data & DECIMAL)>>184,uint256(data & TIMESTAMP)>>120,uint256(data & PRICE)>>24);

    }


    /// @notice Helps to scale the price of a pair id to 18 decimal places
    /// @dev checks if the price is in MAX_DECIMAL decimal or not . If not then will convert them to MAX_DECIMAL
    /// @param price the price of the pair ID
    /// @param decimal number of decimals that the pair info supports
    /// @return the scaled prices of the pair

    function _scalePrice(uint256 price,uint256 decimal) internal pure returns(uint256) {
        if (decimal==MAX_DECIMAL) return price;
        else return price*10**(MAX_DECIMAL-decimal);
    }
}

