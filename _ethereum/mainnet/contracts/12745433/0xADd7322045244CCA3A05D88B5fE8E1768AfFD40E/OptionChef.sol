//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;


import "./Ownable.sol";
import "./IOptions.sol";
import "./IHegexoption.sol";
import "./IChefData.sol";

/**
 * @author ivan@district0x
 * @title Option factory aka Mighty Option Chef
 * @notice Option Chef has the monopoly to mint and destroy NFT Hegexoptions
 */
contract OptionChef is Ownable {

    //storage

    IHegicOptions public hegicOptionETH;
    IHegicOptions public hegicOptionBTC;
    IHegexoption public hegexoption;
    IOptionChefData public chefData;

    //ideally this should've been a mapping/arr of id->Struct {owner, id}
    //there are a few EVM gotchas for this (afaik one can't peek into
    //mapped structs from another contracts, happy to restructure if I'm wrong though)
    // mapping (uint => uint) uIds;
    // mapping (uint => uint) ids;

    //events

    event Wrapped(address account, uint optionId);
    event Unwrapped(address account, uint tokenId);
    event Exercised(uint _tokenId, uint profit);
    event CreatedHegic(uint optionId, uint hegexId);


    //utility functions

    function updateHegicOption(IHegicOptions _hegicOptionETH,
                               IHegicOptions _hegicOptionBTC)
        external
        onlyOwner {
        hegicOptionETH = _hegicOptionETH;
        hegicOptionBTC = _hegicOptionBTC;
    }

    function updateHegexoption(IHegexoption _hegexoption)
        external
        onlyOwner {
        hegexoption = _hegexoption;
    }

    constructor(IHegicOptions _hegicOptionETH,
                IHegicOptions _hegicOptionBTC,
                IOptionChefData  _chefData) public {
        hegicOptionETH = _hegicOptionETH;
        hegicOptionBTC = _hegicOptionBTC;
        chefData = _chefData;
    }

    // direct user to a right contract
    // NOTE: optimize to bool if gas savings are substantial
    function getHegic(uint8 _optionType) public view returns (IHegicOptions) {
        if (_optionType == 0) {
            return hegicOptionETH;
        } else  {
            return hegicOptionBTC;
        }
    }

    //core (un)wrap functionality


    /**
     * @notice Hegexoption wrapper adapter for Hegic
     */
    function wrapHegic(uint _uId, uint8 _optionType) public returns (uint newTokenId) {
        require(chefData.ids(_uId) == 0 , "UOPT:exists");
        IHegicOptions hegicOption = getHegic(_optionType);
        (, address holder, , , , , , ) = hegicOption.options(_uId);
        //auth is a bit unintuitive for wrapping, see NFT.sol:isApprovedOrOwner()
        require(holder == msg.sender || holder == address(this), "UOPT:ownership");
        newTokenId = hegexoption.mintHegexoption(msg.sender);
        chefData.setuid(newTokenId, _uId);
        chefData.setid(_uId, newTokenId);
        chefData.setoptiontype(_uId, _optionType);
        emit Wrapped(msg.sender, _uId);
    }

    /**
     * @notice Hegexoption unwrapper adapter for Hegic
     * @notice check burning logic, do we really want to burn it (vs meta)
     * @notice TODO recheck escrow mechanism on 0x relay to prevent unwrapping when locked
     */
    function unwrapHegic(uint8 _optionType, uint _tokenId) external onlyTokenOwner(_tokenId) {
        // checks if hegicOption will allow to transfer option ownership
        IHegicOptions hegicOption = getHegic(_optionType);
        (IHegicOptions.State state, , , , , , uint expiration ,) = getUnderlyingOptionParams(_optionType, _tokenId);
        if (state == IHegicOptions.State.Active || expiration >= block.timestamp) {
            hegicOption.transfer(chefData.uIds(_tokenId), msg.sender);
        }
        //burns anyway if token is expired
        hegexoption.burnHegexoption(_tokenId);
        uint utokenid = chefData.uIds(_tokenId);
        chefData.setid(utokenid, 0);
        chefData.setuid(_tokenId, 0);
        emit Unwrapped(msg.sender, _tokenId);
    }

    function exerciseHegic(uint8 _optionType, uint _tokenId) external onlyTokenOwner(_tokenId) {
        IHegicOptions hegicOption = getHegic(_optionType);
        hegicOption.exercise(getUnderlyingOptionId(_tokenId));
        uint profit = address(this).balance;
        payable(msg.sender).transfer(profit);
        emit Exercised(_tokenId, profit);
    }

    uint256 public migrationLock = 0;
    address payable public newChef;

    /**
     * @notice  Migrate chef (effective after 72 hours)
     * @param _newChef chef address
     */
    function migrateChefWithTimelock(address payable _newChef) public onlyOwner {
        if (migrationLock != 0 && (block.timestamp > migrationLock + 72 hours)) {
            chefData.transferOwnership(newChef);
            hegexoption.migrateChef(newChef);
            migrationLock = 0;
        } else {
            migrationLock = block.timestamp;
            newChef = _newChef;
        }
    }

    function getUnderlyingOptionId(uint _tokenId) public view returns (uint) {
        return chefData.uIds(_tokenId);
    }

    function getUnderlyingOptionParams(uint8 _optionType, uint _tokenId)
        public
        view
        returns (
        IHegicOptions.State state,
        address payable holder,
        uint256 strike,
        uint256 amount,
        uint256 lockedAmount,
        uint256 premium,
        uint256 expiration,
        IHegicOptions.OptionType optionType)
    {
        (state,
         holder,
         strike,
         amount,
         lockedAmount,
         premium,
         expiration,
         optionType) = getHegic(_optionType).options(chefData.uIds(_tokenId));
    }

    /**
     * @notice gas-greedier getUnderlyingOptionParams when optionType is unknown
     */
    function tokenMetadata(uint _tokenId)
        public
        view
        returns (
        IHegicOptions.State state,
        address payable holder,
        uint256 strike,
        uint256 amount,
        uint256 premium,
        uint256 expiration,
        IHegicOptions.OptionType optionType,
        uint8 hegexOptionType)
    {
        uint8 hegexOptionType = chefData.optionType(chefData.uIds(_tokenId));
        (state, holder, strike, amount, , premium, expiration, optionType) =
            getUnderlyingOptionParams(hegexOptionType, _tokenId);
    }


    /**
     * @notice check whether Chef has underlying option locked
     */
    function isDelegated(uint _tokenId) public view returns (bool) {
        uint8 optionType = chefData.optionType(chefData.uIds(_tokenId));
        IHegicOptions hegicOption = getHegic(optionType);
        ( , address holder, , , , , , ) = hegicOption.options(chefData.uIds(_tokenId));
        return holder == address(this);
    }

    function createHegic(
        uint8 _hegicOptionType,
        uint _period,
        uint _amount,
        uint _strike,
        IHegicOptions.OptionType _optionType
    )
        payable
        external
        returns (uint)
    {
        IHegicOptions hegicOption = getHegic(_hegicOptionType);
        uint optionId = hegicOption.create{value: msg.value}(_period, _amount, _strike, _optionType);
        // return eth excess
        payable(msg.sender).transfer(address(this).balance);
        uint hegexId = wrapHegic(optionId, _hegicOptionType);
        emit CreatedHegic(optionId, hegexId);
        return hegexId;
    }

    function migrateBaseURI(string memory _base) public onlyOwner {
        hegexoption.migrateBaseURI(_base);
    }

    modifier onlyTokenOwner(uint _itemId) {
        require(msg.sender == hegexoption.ownerOf(_itemId), "UOPT:ownership/exchange");
        _;
    }

    receive() external payable {}
}
