// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./Airdrop.sol";

interface IWASNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

contract WAS is ERC20, Airdrop, Ownable, IERC721Receiver {
    //Master switch
    bool private _isContractActive;

    //Max supply control
    uint256 private _maxSupply;
    uint256 private _totalSupply;
    uint256 private _claimedTokens;
    
    //Airdrop status & related settings
    bool private _airdropEnabled;
    bool private _airdropExpired;
    address private _communityLiquidityAddress;

    //Hell - Resurrection
    bool private _selfHellResurrectionStatus;
    bool private _hellResurrectionStatus;
    uint256 _publicResurrectionCost; //Cost of public resurrection in WAS utility tokens
    uint256 _selftResurrectionCost; //Cost of self-resurrection
    
    // Mapping of all Satoshis currently in hell / heaven - where the unit index is the satoshi #
    mapping(uint256 => bool) private _satoshisInHell;
    mapping(uint256 => bool) private _hellVersionSatoshis;
    mapping(uint256 => bool) private _heavenVersionSatoshis;
    mapping(uint256 => bool) private _restrictedSatoshis; //Unique and Flying satoshis can not be resurrected
    uint256[] private _resurrectedSatoshisHell; //Simple array holding all WAS NFT Ids ever resurrected in Hell State
    uint256[] private _resurrectedSatoshisHeaven; //Simple array holding all WAS NFT Ids ever resurrected in Heaven State


    //Fires when a genesis Satoshi is turned into Hell version Satoshi
    event SatoshiHellResurrection(uint256 satoshiId, address newOwner);

    //Fires when a genesis Satoshi is turned into Heaven version Satoshi
    event SatoshiHeavenResurrection(uint256 satoshiId, address newOwner);

    //Fires when a new genesis Satoshi is added to hell and is now available for public resurrection
    event SatoshiAddedToHell(uint256 satoshiId);

    //Fires on public resurrections
    event PublicResurrection(uint256 satoshiId, address resurrectorAddress);

    //Control events fired on reciving a new NFT
    event incomingNftOperator(address operatorAddress);
    event incomingNftFrom(address fromAddress);
    event incomingNftId(uint256 nftId);
    event incomingNftOwner(address nftOwnerAddress);

    //WAS NFT Smart contract and OS Satoshi Hell address
    address private _wasNFTSmartContract;
    address private _satoshiHellOSAddress;

    IWASNFT wasNFTContract = IWASNFT(_wasNFTSmartContract);

    constructor(uint256 maxTokenSupply, address wasNftScAddress, address satoshisHellOsAddress, address communityLiquidityAddress) ERC20("WAS Utility Token", "WAS") public {
        _isContractActive = true;
        _maxSupply = maxTokenSupply * 1000000000000000000;
        _claimedTokens = 0;
        _airdropEnabled = true;
        _airdropExpired = false;
        _communityLiquidityAddress = communityLiquidityAddress;
        _selfHellResurrectionStatus = true;
        _hellResurrectionStatus = true;
        _publicResurrectionCost = 25000000000000000000000;
        _selftResurrectionCost = 100000000000000000000000;
        _wasNFTSmartContract = wasNftScAddress;
        _satoshiHellOSAddress = satoshisHellOsAddress;
        
        // Set restricted satoshis
        _restrictedSatoshis[1] = true;
        _restrictedSatoshis[4] = true;
        _restrictedSatoshis[191] = true;
        _restrictedSatoshis[350] = true;
        _restrictedSatoshis[587] = true;
        _restrictedSatoshis[78] = true;
        _restrictedSatoshis[989] = true;
        _restrictedSatoshis[204] = true;
        _restrictedSatoshis[570] = true;
        _restrictedSatoshis[122] = true;
        _restrictedSatoshis[923] = true;
    }

    // Airdrop methods
    function claimAirdrop(address to)
    public
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");

        uint256 claimableAmount = getAirdropAmount(to);
        require(claimableAmount > 0,"This address is not eligible for WAS utility token airdrop.");
        require(_airdropEnabled, "Sorry, WAS utility token airdrop claiming is not enabled at the moment.");
        require(_airdropExpired == false, "Sorry, WAS utility airdrop claiming window has expired.");
        require(_maxSupply >= (_claimedTokens + claimableAmount),"Invalid claim operation would exceed max token supply limit.");
        invalidateAirdrop(to);
        _claimedTokens = _claimedTokens + claimableAmount;
        _mint(to, claimableAmount);
        if (_claimedTokens == _maxSupply) {
            _airdropExpired = true;
            _airdropEnabled = false;
        }
    }

    function getClaimableTokensAmount(address to)
    public
    view
    returns (uint256)
    {
        uint256 claimableAmount = 0;
        if (_airdropExpired == false && _airdropEnabled) {
            claimableAmount = getAirdropAmount(to);
        }
        return claimableAmount;
    }

    /**
    * Resurrection methods
    */

    //This method is called by users to buy and resurrect Satoshis that are currently in hell
    function resurrectHellPublic(uint256 satoshiId)
    public
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into hell Satoshi.");
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        require(_satoshisInHell[satoshiId],"This Satoshi is not in Hell and it can not be resurrected.");
        require(_hellVersionSatoshis[satoshiId] == false, "This Satoshi is already a hell version.");
        require(balanceOf(msg.sender) >= _publicResurrectionCost, "You do not have enough tokens to resurrect this Satoshi");

        _burn(msg.sender, _publicResurrectionCost);

        delete _satoshisInHell[satoshiId];
        _hellVersionSatoshis[satoshiId] = true;
        _resurrectedSatoshisHell.push(satoshiId); //Record this Satoshi as Hell Version resurrection occured
        IWASNFT(_wasNFTSmartContract).safeTransferFrom(address(this), msg.sender, satoshiId);
        emit SatoshiHellResurrection(satoshiId,msg.sender);
        emit PublicResurrection(satoshiId,msg.sender);
    }

    //This method is called by users to self-resurrect Satoshis they own
    //This method should check if the sender owns the Satoshi being resurrected
    function selfResurrectHell(uint256 satoshiId)
    public
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");

        //You can not turn heaven Satoshis into hell Satoshis
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into hell Satoshi.");
        //You can not turn unique and super rare satoshis into hell Satoshis
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        //You can not turn hell Satoshis into hell Satoshis
        require(_hellVersionSatoshis[satoshiId] == false, "This Satoshi is already a hell version");
        //You need to have enough WAS tokens to resurrect a Satoshi
        require(balanceOf(msg.sender) >= _selftResurrectionCost, "You do not have enough tokens to resurrect this Satoshi.");
        //You must own this Satoshi
        require(IWASNFT(_wasNFTSmartContract).ownerOf(satoshiId) == msg.sender, "You must own the Satoshi you wish to resurrect.");
        
        
        // Burn utility tokens for the resurrection
        _burn(msg.sender, _selftResurrectionCost);

        //Add this Satoshi to the map of hell version Satoshis
        _hellVersionSatoshis[satoshiId] = true;
        
        //Make a public record of this resurrection (needed for metadarta conversion)
        _resurrectedSatoshisHell.push(satoshiId);

        //Resurrection completed, emit the event
        emit SatoshiHellResurrection(satoshiId,msg.sender);
    }

    // Heaven resurrection methods
    function resurrectHeavenPublic(uint256 satoshiId)
    public
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");

        //You can not turn unique and super rare satoshis into heaven Satoshis
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");

        //You can only turn hell Satoshi into heaven Satoshis
        require(_hellVersionSatoshis[satoshiId] == true, "Satoshi must be a hell version before turning it to heaven version");
        
        //You can not turn heaven Satoshis into heaven Satoshis
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into heaven Satoshi.");
        
        //Is satoshi in hell / available for resurrection?
        require(_satoshisInHell[satoshiId] == true,"This Satoshi is not in Hell and it can not be resurrected.");
        
        //Does sender have enough funds to resurrect this Satoshi?
        require(balanceOf(msg.sender) >= _publicResurrectionCost, "You do not have enough tokens to resurrect this Satoshi");

        // Burn the resurrection payment
        _burn(msg.sender, _publicResurrectionCost);

        //Remove Satoshi from hell and list of hell version Satoshis
        delete _satoshisInHell[satoshiId];
        delete _hellVersionSatoshis[satoshiId];

        //Move satoshi to the list of heaven version satoshis
        _heavenVersionSatoshis[satoshiId] = true;
        _resurrectedSatoshisHeaven.push(satoshiId);

        //Transfer the resurrected Satoshi to the resurrector
        IWASNFT(_wasNFTSmartContract).safeTransferFrom(address(this), msg.sender, satoshiId);
        
        //Notify the world about this resurrection
        emit SatoshiHeavenResurrection(satoshiId,msg.sender);
        emit PublicResurrection(satoshiId,msg.sender);
    }

    function selfResurrectHeaven(uint256 satoshiId)
    public
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");

        //You can not turn unique and super rare satoshis into heaven Satoshis
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");

        //You can only turn hell Satoshis into heaven Satoshis
        require(_hellVersionSatoshis[satoshiId] == true, "Satoshi must be a hell version before turning it to heaven version");
        
        //You can not turn heaven Satoshis into heaven Satoshis
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into heaven Satoshi.");

        //Does sender have enough funds to resurrect this Satoshi?
        require(balanceOf(msg.sender) >= _selftResurrectionCost, "You do not have enough tokens to resurrect this Satoshi");

        //You must own this Satoshi
        require(IWASNFT(_wasNFTSmartContract).ownerOf(satoshiId) == msg.sender, "You must own the Satoshi you wish to resurrect.");
        

        // Burn the resurrection payment
        _burn(msg.sender, _selftResurrectionCost);

        //Remove Satoshi from the list of hell version satoshis
        delete _hellVersionSatoshis[satoshiId];

        //Move satoshi to the list of heaven version satoshis
        _heavenVersionSatoshis[satoshiId] = true;
        _resurrectedSatoshisHeaven.push(satoshiId);
        
        //Notify the world about this resurrection
        emit SatoshiHeavenResurrection(satoshiId,msg.sender);
    }

    function _addSatoshiToHell(uint256 satoshiId)
    internal 
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");
        require(satoshiId <= 1024,"Satoshi outside of the NFT collection size.");
        require(satoshiId > 0,"Satoshi outside of the NFT collection size.");
        require(_satoshisInHell[satoshiId] == false,"Satoshi already in hell.");
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not add heaven Satoshis to hell.");
         
        _satoshisInHell[satoshiId] = true;
        emit SatoshiAddedToHell(satoshiId);
    }

    //Only accept satoshis from WAS OS Satoshi Hell wallet
    function onERC721Received(address operator, address from, uint256 satoshiId, bytes memory)
    public
    virtual
    override
    returns (bytes4) {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");
        require(from == _satoshiHellOSAddress, "No thank you, I am not sure this is a WAS NFT.");
        require(IWASNFT(_wasNFTSmartContract).ownerOf(satoshiId) == address(this), "This Satoshi does not belong to this smart contract.");
       
        if (from == _satoshiHellOSAddress) {
            _addSatoshiToHell(satoshiId);
            emit incomingNftOperator(operator);
            emit incomingNftFrom(from);
            emit incomingNftId(satoshiId);
            return this.onERC721Received.selector;
        }
    }


    /**
    * Setters
    * The methods below are ownerOnly methods used to configure various properties of the smart contract.
    * These methods are also used to control various states of the contract.
    */
    function manualAddSatoshiToHell(uint256 satoshiId)
    public
    onlyOwner 
    {
        require(IWASNFT(_wasNFTSmartContract).ownerOf(satoshiId) == address(this), "This Satoshi does not belong to this smart contract.");
        _addSatoshiToHell(satoshiId);
    }

    function setSelfResurrectionPrice(uint256 newPrice)
    public
    onlyOwner
    {
        _selftResurrectionCost = newPrice * 1000000000000000000;
    }

    function setPublicResurrectionPrice(uint256 newPrice)
    public
    onlyOwner 
    {
        _publicResurrectionCost = newPrice * 1000000000000000000;
    }

    function toggleContract()
    public
    onlyOwner
    {
        _isContractActive = !_isContractActive;
    }

    function toggleAirdrop()
    public
    onlyOwner
    {
        _airdropEnabled = !_airdropEnabled;
    }

    // Mint all utility tokens that were not claimed during the airdrop and transer them to the community wallet.
    function expireAirdrop()
    public
    onlyOwner
    {
        require(_airdropEnabled == false, "Can not expire the airdrop while its enabled.");
        require(_airdropExpired == false, "Airdrop already expired. Can not expire the airdrop again.");
        _airdropExpired = true;

        uint256 remainingTokens = _maxSupply - _claimedTokens;
        if (remainingTokens > 0) {
            _mint(_communityLiquidityAddress, remainingTokens);
            _claimedTokens = _claimedTokens + remainingTokens;
        }
    }

    function setCommunityLiquidityAddress(address newCommunityAddress)
    public
    onlyOwner
    {
        _communityLiquidityAddress = newCommunityAddress;
    }
    //If needed, to change the interfacing address for WAS NFT smart contract
    function setWasSmartContractAddress(address newSCAddress)
    public
    onlyOwner
    {
        _wasNFTSmartContract = newSCAddress;
    }

    function setSatoshisHellOsAddress(address newSatoshisHellOsAddresss)
    public
    onlyOwner 
    {
        _satoshiHellOSAddress = newSatoshisHellOsAddresss;
    }






    // Public getters
    /**
    * The methods below are used to get/read various internal vars/information from the contract.
    */
    function isSatoshiInHell(uint256 satoshiId)
    public
    view
    returns (bool)
    {
        return _satoshisInHell[satoshiId];
    }

    function getResurrectedSatoshisHell()
    external
    view
    returns(uint256[] memory) {
        return _resurrectedSatoshisHell;
    }

    function getResurrectedSatoshisHeaven()
    external
    view
    returns(uint256[] memory) {
        return _resurrectedSatoshisHeaven;
    }

    function isSatoshiHellVersion(uint256 satoshiId)
    public
    view
    returns (bool)
    {
        return _hellVersionSatoshis[satoshiId];
    }

    function isSatoshiHeavenVersion(uint256 satoshiId)
    public
    view
    returns (bool)
    {
        return _heavenVersionSatoshis[satoshiId];
    }

    function getMaxSupply()
    public
    view
    returns (uint256) {
        return _maxSupply;
    }

    function getTotalTokensClaimed()
    public
    view
    returns(uint256)
    {
        return _claimedTokens;
    }

    //How many tokens left?
    function getRemainingTokens()
    public
    view
    returns (uint256)
    {
        uint256 remainingTokens = _maxSupply - _claimedTokens;
        return remainingTokens;
    }

    function getAirdropStatus()
    public
    view
    returns (bool)
    {
        return _airdropEnabled;
    }

    function getPublicResurrectionCost()
    public
    view
    returns(uint256) {
        return _publicResurrectionCost;
    }

    function getSelfResurrectionCost()
    public
    view
    returns(uint256) {
        return _selftResurrectionCost;
    }

    function getWASNftContract()
    public
    view
    returns(address) {
        return _wasNFTSmartContract;
    }

    function getWasCommunityWallet()
    public
    view
    returns(address)
    {
        return _communityLiquidityAddress;
    }

    function getWasOsHellAddress()
    public
    view
    returns(address)
    {
        return _satoshiHellOSAddress;
    }

    function getContractState()
    public
    view
    returns(bool)
    {
        return _isContractActive;
    }
}