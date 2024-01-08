pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

interface CapitalCityOwnership {
    function mintCapitalCityReceiver(
        string calldata _cityName,
        uint _tileIndex,
        bool _isGenesis,
        address _tokenOwner
    ) external returns(uint);
}

//------------------------------------------------------------------------------
/// @dev Contract module which provides a basic access control mechanism, where
///  there is an account (an owner) that can be granted exclusive access to
///  specific functions.
///
///  By default, the owner account will be the one that deploys the contract.
///  This can later be changed with {transferOwnership}.
/// 
///  This module is used through inheritance. It will make the modifier
///  onlyOwner available, which can be applied to functions to restrict
///  their use to the owner.
//------------------------------------------------------------------------------
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed _previousOwner,
        address indexed _newOwner
    );

    //--------------------------------------------------------------------------
    /// @dev Initializes the contract setting the deployer as the initial owner.
    //--------------------------------------------------------------------------
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    //--------------------------------------------------------------------------
    /// @dev Throws if called by any account other than the owner.
    //--------------------------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: sender must be contract owner");
        _;
    }

    //--------------------------------------------------------------------------
    /// @dev Leaves the contract without owner. It will not be possible to call
    ///  onlyOwner functions anymore. Can only be called by the current owner.
    ///
    ///  NOTE: Renouncing ownership will leave the contract without an owner,
    ///  thereby removing any functionality that is only available to the owner.
    //--------------------------------------------------------------------------
    function renounceOwnership() external onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));
    }

    //--------------------------------------------------------------------------
    /// @dev Transfers ownership of the contract to a new account (_newOwner).
    ///  Can only be called by the current owner.
    //--------------------------------------------------------------------------
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0),
            "Ownable: new owner cannot be the zero address");
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract CrusadesCapitalCityMinter is Ownable {
    event OnMintCapital(uint indexed cityID, int tileIndex);
    
    CapitalCityOwnership public cityOwnership;
    
    //Max tile amount on the planet
    uint constant TILE_COUNT = 40962;
    uint priceToMint = 1 ether / 10;

    //Bank public bank;
    /**
     * @dev Throws if parameter is zero.
     */
    modifier nonZero(uint _param) {
        require(_param != 0, "Parameter cannot be zero");
        _;
    }
    //-------------------------------------------------------------------------
    /// @notice Sets external contracts addresses, set external when finish deploy contracts. link all contracts together.
    /// @dev Throws if the sender is not the Owner address.
    //-------------------------------------------------------------------------
    function setExternalContracts(address _cityOwnership) external onlyOwner {
        if (_cityOwnership != address(0)) {
            cityOwnership = CapitalCityOwnership(_cityOwnership);
        }
    }

    //-------------------------------------------------------------------------
    /// @notice Sets the price to mint a new Capital City. Only able to be
    ///  called by the Owner address
    /// @dev Throws if the sender is not the Owner address. Throws if _newPrice
    ///  is zero
    /// @param _newPrice new cost of minting a Capital City in wei
    //-------------------------------------------------------------------------
    function changePriceToMint(uint _newPrice)
        external
        onlyOwner
        nonZero(_newPrice)
    {
        priceToMint = _newPrice;
    }

    //-------------------------------------------------------------------------
    /// @notice Creates a Genesis City at _tileIndex. Only able to be called by
    ///  the Owner address
    /// @dev Throws if the sender is not the Owner address. Throws if _tileIndex
    ///  is greater than number of planet tiles. WARNING: SENDER IS RESPONSIBLE
    ///  FOR MAKING SURE _tileIndex IS A VALID TILE.
    /// @param _tileIndex the tile index where the Genesis City will be created
    /// @param _cityName the name to assign the new city
    //-------------------------------------------------------------------------
    function mintGenesis(uint _tileIndex, string calldata _cityName) external onlyOwner {
        require(_tileIndex < TILE_COUNT, "Index provided is larger than planet size");
        
        cityOwnership.mintCapitalCityReceiver(_cityName, _tileIndex, true, msg.sender);
    }

    //-------------------------------------------------------------------------
    /// @notice Creates multiple Genesis Cities. Only able to be called by
    ///  the Owner address
    /// @dev Throws if the sender is not the Owner address. Throws if
    ///  _tileIndexes is not the same length as _cityNames. Throws if _tileIndex
    ///  is greater than number of planet tiles. WARNING: SENDER IS RESPONSIBLE
    ///  FOR MAKING SURE _tileIndex IS A VALID TILE.
    /// @param _tileIndexes the tile indexes where the Genesis Cities will be created
    //-------------------------------------------------------------------------
    function bulkMintGenesis(uint[] calldata _tileIndexes, string[] calldata _cityNames) external onlyOwner {
        require(_tileIndexes.length == _cityNames.length, "Arrays cannot be different lengths");
        for(uint i = 0; i < _tileIndexes.length; ++i) {
            require(_tileIndexes[i] < TILE_COUNT, "Index provided is larger than planet size");
            cityOwnership.mintCapitalCityReceiver(_cityNames[i], _tileIndexes[i], true, msg.sender);
        }
        
    }
    //-------------------------------------------------------------------------
    /// @notice init resource, units when mint Capital finished
    /// @dev this data come from Nathan's google sheet.
    /// @param cityID the id where the City index
    //-------------------------------------------------------------------------
    
    // function initResourcesAndUnits(uint cityID) private{
    //     uint[5] memory resources = [uint(30),20,20,5,10];
        
    //     resourceOwnership.grantResources(cityID,resources);
    //     uint[11] memory units = [uint(10),10,10,10,10,10,10,10,10,10,10];
    //     UnitOwnership(externalContracts.unitOwnership()).mintUnits(cityID,units);
    // }
    
}