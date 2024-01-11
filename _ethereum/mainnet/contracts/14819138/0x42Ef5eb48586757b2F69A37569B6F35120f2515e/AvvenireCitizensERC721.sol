// SPDX-License-Identifier: MIT

/**
 * @title Avvenire Citizens Contract
 */
pragma solidity ^0.8.4;

import "AvvenireCitizensInterface.sol";
import "Ownable.sol";
import "ERC721A.sol";
// _setOwnersExplicit( ) moved from the ERC721A contract to an extension
import "ERC721AOwnersExplicit.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";

error TraitTypeDoesNotExist();
error TransferFailed();
error ChangeAlreadyRequested();
error NotSender();
// error InsufficcientFunds();

// token mutator changes the way that an ERC721A contract interacts with tokens
contract AvvenireCitizens is
    Ownable,
    ERC721A,
    ERC721AOwnersExplicit,
    ReentrancyGuard,
    AvvenireCitizensInterface
{
    // events
    event ChangeRequested(uint256 tokenId, address contractAddress, address sender);
    event TraitBound(uint256 citizenId, uint256 traitId, TraitType traitType);

    string baseURI; // a uri for minting, but this allows the contract owner to change it later
    string public loadURI; // a URI that the NFT will be set to while waiting for changes

    address payable receivingAddress; // the address that collects the cost of the mutation

    bool public isStopped; 

    // Data contract
    AvvenireCitizensMappingsInterface public avvenireCitizensData;

    // Traits contract
    AvvenireTraitsInterface public avvenireTraits; 

    // mapping for allowing other contracts to interact with this one
    mapping(address => bool) private allowedContracts;

    // Designated # of citizens; **** Needs to be set to immutable following testings ****
    constructor(
        string memory ERC721Name_,
        string memory ERC721AId_,
        string memory baseURI_,
        string memory loadURI_,
        address dataContractAddress_, 
        address traitContractAddress_
    ) ERC721A(ERC721Name_, ERC721AId_) Ownable() {
        // set the mint URI
        baseURI = baseURI_;

        // set the load uri
        loadURI = loadURI_;

        // set the receiving address to the publisher of this contract
        receivingAddress = payable(msg.sender);

        allowedContracts[msg.sender] = true;

        // Set data contract
        avvenireCitizensData = AvvenireCitizensMappingsInterface(dataContractAddress_);

        avvenireTraits = AvvenireTraitsInterface(traitContractAddress_);
    }

    /**
      Modifier to check if the contract is allowed to call this contract
    */
    modifier callerIsAllowed() {
        if (!allowedContracts[msg.sender]) revert NotSender();
        _;
    }

    modifier stoppedInEmergency {
        require(!isStopped, "Emergency stop active");
        _;
    }

    /**
     * @notice returns the tokenURI of a token id (overrides ERC721 function)
     * @param tokenId allows the user to request the tokenURI for a particular token id
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // check to make sure that the tokenId exists
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken(); // error from ERC721A

        // if a change has been requested, only show the loading URI
        if (avvenireCitizensData.getCitizenChangeRequest(tokenId)) {
            return loadURI;
        }

        // if there is a citizen associated with this token, return the chacter's uri

        if (bytes(avvenireCitizensData.getCitizen(tokenId).uri).length > 0) {
            return avvenireCitizensData.getCitizen(tokenId).uri;
        }

        // if there is no load uri, citizen uri, or trait uri, just return the base
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    /**
     * @notice Requests a change for a token
     * @param tokenId allows the user to request a change using their token id
     */
    function requestChange(uint256 tokenId) external payable callerIsAllowed {
        // check if you can even request changes at the moment
        require(avvenireCitizensData.getMutabilityMode(), "Tokens immutable");

        // check if the token exists
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        // check that this is the rightful token owner
        require(ownerOf(tokenId) == tx.origin, "Not owner");

        // check if the token has already been requested to change
        if (avvenireCitizensData.getCitizenChangeRequest(tokenId)) revert ChangeAlreadyRequested();

        _requestChange(tokenId); // call the internal function
    }

    function _requestChange(uint256 tokenId) internal {
        avvenireCitizensData.setCitizenChangeRequest(tokenId, true);
        emit ChangeRequested(tokenId, msg.sender, tx.origin);
    }

    /**
     * @notice Set the citizen data (id, uri, any traits)
     * note: can't just set the uri, because we need to set the sex also (after the first combination)
     * @param citizen allows a contract to set the citizen's uri to a new one
     * @param changeUpdate sets the change data to the correct boolean (allows the option to set the changes to false after something has been updated OR keep it at true if the update isn't done)
     */
    function setCitizenData(Citizen memory citizen, bool changeUpdate)
        external
        callerIsAllowed
        stoppedInEmergency
    {
        // set the citizen data
        avvenireCitizensData.setCitizen(citizen);

        // set the token change data
        avvenireCitizensData.setCitizenChangeRequest(citizen.tokenId, changeUpdate);
    }

    /**
     * @notice internal function for getting the default trait (mostly for creating new citizens, waste of compute for creating new traits)
     * @param originCitizenId for backwards ipfs mapping
     * @param sex for compatibility
     * @param traitType for compatibility
     * @param exists for tracking if the trait actually exists
     */
    function baseTrait(
        uint256 originCitizenId,
        Sex sex,
        TraitType traitType,
        bool exists
    ) internal returns (Trait memory) {
        return
            Trait({
                tokenId: 0, // there will be no traits with tokenId 0, as that must be the first citizen (cannot have traits without minting the first citizen)
                uri: "",
                free: false,
                exists: exists, // allow setting the existence
                sex: sex,
                traitType: traitType,
                originCitizenId: originCitizenId
            });
    }

    /**
     * @notice internal function to create a new citizen
     * @param tokenId (for binding the token id)
     */
    function createNewCitizen(uint256 tokenId) internal {
        // create a new citizen and put it in the mapping --> just set the token id and that it exists, don't set any of the traits or the URI (as these can be handled in the initial mint)
        Citizen memory _citizen = Citizen({
            tokenId: tokenId,
            uri: "", // keep this blank to keep the user from paying excess gas before decomposition (the tokenURI function will handle for blank URIs)
            exists: true,
            sex: Sex.NULL, // must be unisex for mint
            traits: Traits({
                background: baseTrait(0, Sex.NULL, TraitType.BACKGROUND, false), // minting with a default background
                body: baseTrait(tokenId, Sex.NULL, TraitType.BODY, true),
                tattoo: baseTrait(0, Sex.NULL, TraitType.TATTOO, false), // minting with no tattoos
                eyes: baseTrait(tokenId, Sex.NULL, TraitType.EYES, true),
                mouth: baseTrait(tokenId, Sex.NULL, TraitType.MOUTH, true),
                mask: baseTrait(0, Sex.NULL, TraitType.MASK, false), // mint with no masks
                necklace: baseTrait(0, Sex.NULL, TraitType.NECKLACE, false), // mint with no necklaces
                clothing: baseTrait(tokenId, Sex.NULL, TraitType.CLOTHING, true),
                earrings: baseTrait(0, Sex.NULL, TraitType.EARRINGS, false), // mint with no earrings
                hair: baseTrait(tokenId, Sex.NULL, TraitType.HAIR, true),
                effect: baseTrait(0, Sex.NULL, TraitType.EFFECT, false) // mint with no effects
            })
        });

        avvenireCitizensData.setCitizen(_citizen);
    }


    /**
     * @notice internal function to make traits transferrable (used when binding traits)
     * checks that a trait exists (makes user unable to set a default to a default)
     * @param traitId for locating the trait
     * @param exists for if the trait exists
     */
    function _makeTraitTransferable(uint256 traitId, bool exists) internal {
        avvenireTraits.makeTraitTransferable(traitId, exists);
    }

    /**
     * @notice internal function to make traits non-transferrable
     * checks that a trait exists (makes user unable to set a default to a default)
     * @param traitId to indicate which trait to change
     */
    function _makeTraitNonTransferrable(uint256 traitId) internal {
        avvenireTraits.makeTraitNonTransferrable(traitId);
    }

    /**
     * @notice a function to bind a tokenId to a citizen (used in combining)
     * Note: the tokenId must exist, this does not create new tokens (use spawn traits for that)
     * going to assume that the transaction origin owns the citizen (this function will be called multiple times)
     * Also, this does not set the character up for changing. It is assumed that many traits will be bound for a character to be changed, so the character should be requested to change once.
     * @param citizenId gets the citizen
     * @param traitId for the trait
     * @param traitType for the trait's type
     */
    function bind(
        uint256 citizenId,
        uint256 traitId,
        Sex sex,
        TraitType traitType
    ) external callerIsAllowed stoppedInEmergency {
        // if binding non-empty trait, must require the correct sex and ensure that the tokenId exists
        if (traitId != 0) {
            // check if the trait exists
            require(avvenireCitizensData.getTrait(traitId).exists, "Trait doesn't exist"); 

            // ensure that the trait and citizen have the same sex
            require(avvenireCitizensData.getCitizen(citizenId).sex == avvenireCitizensData.getTrait(traitId).sex,
            "Sex mismatch");
        }

        // check each of the types and bind them accordingly
        // this logic costs gas, as these are already checked in the market contract

        Trait memory _trait;

        // Set _trait according to its respective id 
        if (traitId == 0) {
            // this trait does not exist, just set it to the default struct
            _trait = Trait({
                tokenId: traitId,
                originCitizenId: 0, // no need for an origin citizen, it's a default
                uri: "",
                free: false,
                exists: false,
                sex: sex,
                traitType: traitType
            });
        } else {
            // check the owner of the trait
            require(avvenireTraits.isOwnerOf(traitId) == tx.origin, "The transaction origin does not own the trait");
            // the trait exists and can be found

            // disallow trading of the bound trait
            _makeTraitNonTransferrable(traitId);
            _trait = avvenireCitizensData.getTrait(traitId);

            // require that the trait's type is the same type as the trait Id (if the user tries to put traits on the wrong parts of NFTs)
            require(_trait.traitType == traitType, "Trait type does not match trait id");
        }

        Citizen memory _citizen = avvenireCitizensData.getCitizen(citizenId);

        // ***
        // Set all respective traits to free, set temporary _citizen's traits to the respective change
        // *** 
        if (traitType == TraitType.BACKGROUND) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.background.tokenId, _citizen.traits.background.exists);
            _citizen.traits.background = _trait;

        } else if (traitType == TraitType.BODY) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.body.tokenId, _citizen.traits.body.exists);
            _citizen.traits.body = _trait;

        } else if (traitType == TraitType.TATTOO) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.tattoo.tokenId, _citizen.traits.tattoo.exists);
            _citizen.traits.tattoo = _trait;

        } else if (traitType == TraitType.EYES) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.eyes.tokenId, _citizen.traits.eyes.exists);
            _citizen.traits.eyes = _trait;

        } else if (traitType == TraitType.MOUTH) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.mouth.tokenId, _citizen.traits.mouth.exists);
            _citizen.traits.mouth = _trait;

        } else if (traitType == TraitType.MASK) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.mask.tokenId, _citizen.traits.mask.exists);
            _citizen.traits.mask = _trait;

        } else if (traitType == TraitType.NECKLACE) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.necklace.tokenId, _citizen.traits.necklace.exists);
            _citizen.traits.necklace = _trait;

        } else if (traitType == TraitType.CLOTHING) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.clothing.tokenId, _citizen.traits.clothing.exists);
            _citizen.traits.clothing = _trait;

        } else if (traitType == TraitType.EARRINGS) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.earrings.tokenId, _citizen.traits.earrings.exists);
            _citizen.traits.earrings = _trait;

        } else if (traitType == TraitType.HAIR) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.hair.tokenId, _citizen.traits.hair.exists);
            _citizen.traits.hair = _trait;

        } else if (traitType == TraitType.EFFECT) {
            // make the old trait transferrable
            _makeTraitTransferable(_citizen.traits.effect.tokenId, _citizen.traits.effect.exists);
            _citizen.traits.effect = _trait;
        } else {
            // return an error that the trait type does not exist
            revert TraitTypeDoesNotExist();
        }

        // Finally set avvenireCitizensData.tokenIdToCitizen to _citizen
        avvenireCitizensData.setCitizen(_citizen);

        // emit that the trait was set
        emit TraitBound(_citizen.tokenId, _trait.tokenId, traitType);
    }

    /**
     * @notice external safemint function for allowed contracts
     * @param address_ for where to mint to
     * @param quantity_ for the amount
     */
    function safeMint(address address_, uint256 quantity_)
        external
        callerIsAllowed
        stoppedInEmergency
    {
        require(tx.origin != msg.sender, "The caller is a user.");

        // token id end counter
        uint256 startTokenId = _currentIndex;
        uint256 endTokenId = startTokenId + quantity_;

        _safeMint(address_, quantity_);

        // iterate over all the tokens
        for (
            uint256 tokenId = startTokenId;
            tokenId < endTokenId;
            tokenId += 1
        ) {
            // create a new citizen if the mint is active
            createNewCitizen(tokenId);

        } // end of for loop
    }

    /**
     * @notice returns the number minted from specified address
     * @param owner an address of an owner in the NFT collection
     */
    function numberMinted(address owner) public view returns (uint256) {
        // check how many have been minted to this owner --> where is this data stored, in the standard?
        // _addressData mapping in the ERC721A standard; line 51 - Daniel
        return _numberMinted(owner);
    }

    /**
     * @notice Returns a struct, which contains a token owner's address and the time they acquired the token
     * @param tokenId the tokenID
     */
    function getOwnershipData(
        uint256 tokenId // storing all the old ownership
    ) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId); // get historic ownership
    }

    /**
     * @notice This overrides the token transfers to check some conditions
     * @param from indicates the previous address
     * @param to indicates the new address
     * @param startTokenId indicates the first token id
     * @param quantity shows how many tokens have been minted
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        // token id end counter
        uint256 endTokenId = startTokenId + quantity;

        // iterate over all the tokens
        for (
            uint256 tokenId = startTokenId;
            tokenId < endTokenId;
            tokenId += 1
        ) {
            // the tokens SHOULD NOT be awaiting a change (you don't want the user to get surprised)
            if (!(avvenireCitizensData.getTradeBeforeChange())) {
                require(!avvenireCitizensData.getCitizenChangeRequest(tokenId), "Change  requested");
            }
        } // end of loop
    }

    /**
     * @notice setter  for emergency stop
     */
    function setEmergencyStop(bool _isStopped) external onlyOwner {
        isStopped = _isStopped; 
    }

    /**
     * @notice gets rid of the loops used in the ownerOf function in the ERC721A standard
     * @param quantity the number of tokens that you want to eliminate the loops for
     */
    function setOwnersExplicit(uint256 quantity)
        external
        callerIsAllowed
    {
        _setOwnersExplicit(quantity);
    }

    /**
     * @notice function that gets the total supply from the ERC721A contract
     */
    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    /**
     * @notice Sets the mint uri
     * @param baseURI_ represents the new base uri
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        // set thte global baseURI to this new baseURI_
        baseURI = baseURI_;
    }

    /**
     * @notice Sets the load uri
     * @param loadURI_ represents the new load uri
     */
    function setLoadURI(string calldata loadURI_) external onlyOwner {
        // set thte global loadURI to this new loadURI_
        loadURI = loadURI_;
    }

    /**
     * @notice Sets the receivingAddress
     * @param receivingAddress_ is the new receiving address
     */
    function setReceivingAddress(address receivingAddress_) external onlyOwner {
        receivingAddress = payable(receivingAddress_);
    }

    /**
     * @notice sets an address's allowed list permission (for future interaction)
     * @param address_ is the address to set the data for
     * @param setting is the boolean for the data
     */
    function setAllowedPermission(address address_, bool setting)
        external
        onlyOwner
    {
        allowedContracts[address_] = setting;
    }

    /**
     * @notice function to withdraw the money from the contract. Only callable by the owner
     */
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = receivingAddress.call{
            value: address(this).balance }("");
            
        require(success, "Failed transaction");
    }

    /**
     * @notice getter function for citizen data
     * @param tokenId the citizen's id
     */
    function getCitizen(uint256 tokenId) external view returns (Citizen memory) {
        return avvenireCitizensData.getCitizen(tokenId);
    }

    /**
     * @notice a burn function to burn an nft.  The tx.origin must be the owner
     * @param tokenId the desired token to be burned
     */
    function burn(uint256 tokenId) external callerIsAllowed {
        require (tx.origin == ownerOf(tokenId), "Not owner");
        _burn(tokenId);
    }

    /**
     * @notice getter function for number of tokens that a user has burned
     * @param _owner the user's address
     */
    function numberBurned(address _owner) external view returns (uint256) {
        return _numberBurned(_owner); 
    }

} // End of contract
