//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;


import "./Ownable.sol";
import "./IOptions.sol";
import "./IUniOption.sol";

/**
 * @author ivan@district0x
 * @title Option factory aka Mighty Option Chef
 * @notice Option Chef has the monopoly to mint and destroy NFT UniOptions
 */
contract OptionChef is Ownable {

    //storage

    IHegicOptions public hegicOption;
    IUniOption public uniOption;

    //ideally this should've been a mapping/arr of id->Struct {owner, id}
    //there are a few EVM gotchas for this (afaik one can't peek into
    //mapped structs from another contracts, happy to restructure if I'm wrong though)
    uint256[] uIds;
    uint256[] ids;

    //events

    event Wrapped(address account, uint optionId);
    event Unwrapped(address account, uint tokenId);


    //utility functions

    function updateHegicOption(IHegicOptions _hegicOption)
        external
        onlyOwner {
        hegicOption = _hegicOption ;
    }

    function updateUniOption(IUniOption _uniOption)
        external
        onlyOwner {
        uniOption = _uniOption;
    }

    constructor(IHegicOptions _hegicOption) public {
        hegicOption = _hegicOption ;
    }


    //core (un)wrap functionality


    /**
     * @notice UniOption wrapper adapter for Hegic
     */
    function wrapHegic(uint _uId) public returns (uint newTokenId) {
        require(ids[_uId] == 0 , "UOPT:exists");
        (, address holder, , , , , , ) = hegicOption.options(_uId);
        //auth is a bit unintuitive for wrapping, see NFT.sol:isApprovedOrOwner()
        require(holder == msg.sender, "UOPT:ownership");
        newTokenId = uniOption.mintUniOption(msg.sender);
        uIds[newTokenId] = _uId;
        ids[_uId] = newTokenId;
        emit Wrapped(msg.sender, _uId);
    }

    /**
     * @notice UniOption unwrapper adapter for Hegic
     * @notice check burning logic, do we really want to burn it (vs meta)
     * @notice TODO recheck escrow mechanism on 0x relay to prevent unwrapping when locked
     */
    function unwrapHegic(uint _tokenId) external onlyTokenOwner(_tokenId) {
        // checks if hegicOption will allow to transfer option ownership
        (IHegicOptions.State state, , , , , , uint expiration , ) = getUnderlyingOptionParams(_tokenId);
        if (state == IHegicOptions.State.Active || expiration >= block.timestamp) {
            hegicOption.transfer(uIds[_tokenId], msg.sender);
        }
        //burns anyway if token is expired
        uniOption.burnUniOption(_tokenId);
        ids[uIds[_tokenId]] = 0;
        uIds[_tokenId] = 0;
        emit Unwrapped(msg.sender, _tokenId);
    }

    function getUnderlyingOptionId(uint _tokenId) external view returns (uint) {
        return uIds[_tokenId];
    }

    function getUnderlyingOptionParams(uint _tokenId)
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
         optionType) = hegicOption.options(uIds[_tokenId]);
    }

    /**
     * @notice check whether Chef has underlying option locked
     */
    function isDelegated(uint _tokenId) public view returns (bool) {
        ( , address holder, , , , , , ) = hegicOption.options(uIds[_tokenId]);
        return holder == address(this);
    }

    function createHegic(
        uint _period,
        uint _amount,
        uint _strike,
        IHegicOptions.OptionType _optionType
    )
        payable
        external
        returns (uint)
    {
        uint optionId = hegicOption.create{value: msg.value}(_period, _amount, _strike, _optionType);
        // return eth excess
        payable(msg.sender).transfer(address(this).balance);
        return wrapHegic(optionId);
    }

    modifier onlyTokenOwner(uint _itemId) {
        require(msg.sender == uniOption.ownerOf(_itemId), "UOPT:ownership/exchange");
        _;
    }
}
