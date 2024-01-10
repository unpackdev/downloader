// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     _____           _       _   _                 //
//    |  ___|         | |     | | (_)                //
//    | |____   _____ | |_   _| |_ _  ___  _ __      //
//    |  __\ \ / / _ \| | | | | __| |/ _ \| '_ \     //
//    | |___\ V / (_) | | |_| | |_| | (_) | | | |    //
//    \____/ \_/ \___/|_|\__,_|\__|_|\___/|_| |_|    //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////

/// @creator: tzmartin
/// @author: mintroad.xyz
/// @version: 0.1

import "./Counters.sol";
import "./Address.sol";

import "./IERC721.sol";
import "./IERC2981.sol";

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";

import "./SharedNFTLogic.sol";
import "./IEditionSingleMintable.sol";

/**
*/
contract EvolutionNFT is
    ERC721Delegated, IEditionSingleMintable
{
    using Counters for Counters.Counter;

    // Events
    event PriceChanged(uint256 amount);
    event ClaimPriceChanged(uint256 amount);
    event EditionMinted(uint256 price, address owner);
    event EditionClaimed(address from, uint256 amount, uint256 evolution, string claimData);

    struct TokenData {
        uint64 claims;
        uint256 claimsBalance;
    }

    uint256 public maxNumberCanMint = 1;

    // Token Name
    string public name;

    // Token symbol
    string public symbol;

    // Price for sale
    uint256 public mintPrice;

    // Claim price
    uint256 public claimPrice;

    // Edition royalty (basis points)
    uint16 private royaltyBPS;

    // Total size of edition that can be minted
    uint256 public editionSize;

    // URI base for image renderer
    string private metaRendererBase;

    // URI extension for metadata renderer
    string private metaRendererExtension;

    // Paused state
    bool public paused;

    // Current dynamic state of the edition
    uint256 private evolution;

    // Minted counter for current Token and totalSupply()
    Counters.Counter private tokenCounter;

    // Addresses allowed to mint edition
    mapping(address => bool) allowedMinters;

    // Meta data for edition
    mapping(uint256 => string) metadataJson;

    // Mapping tokenID to token data
    mapping(uint256 => TokenData) private _tokenData;

    // NFT rendering logic contract
    SharedNFTLogic private immutable sharedNFTLogic;

    // Global constructor for factory
    constructor(
        string memory _name,
        string memory _symbol,
        uint16 _royaltyBPS,
        uint256 _editionSize,
        string memory _metaRendererBase,
        string memory _metaRendererExtension,
        address baseNFTContract,
        SharedNFTLogic _sharedNFTLogic
    ) ERC721Delegated(
        baseNFTContract,
        name,
        symbol,
        ConfigSettings({
            royaltyBps: _royaltyBPS,
            uriBase: _metaRendererBase,
            uriExtension: _metaRendererExtension,
            hasTransferHook: false
        })
    ) {
        // Increment first token ID
        tokenCounter.increment();

        // Set defaults
        name = _name;
        symbol = _symbol;
        royaltyBPS = _royaltyBPS;
        sharedNFTLogic = _sharedNFTLogic;
        editionSize = _editionSize;
        metaRendererBase = _metaRendererBase;
        metaRendererExtension = _metaRendererExtension;
        evolution = 0;
    }

    modifier onlyUnpaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal onlyUnpaused {
        // Stop transfers when paused
    }

    function setPaused(bool _paused)
        public
        onlyOwner
    {
        paused = _paused;
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted()
        external
        view
        returns (uint256)
    {
        // Counter underflow is impossible as tokenCounter does not decrement,
        // and it is initialized to 1
        unchecked {
            return tokenCounter.current() - 1;
        }
    }

    /**
      @param tokenId The ID of the token to get the owner of.
      @dev This allows a user to mint a single edition at the 
           for a given token ID at the current price in the contract. 
           If token ID is 0, it will mint a new edition at the next 
           available increment.
     */
    function mint(uint256 tokenId)
        external
        payable
        onlyUnpaused
        returns (uint256)
    {
        require(!_exists(tokenId), "Token exists");
        require(msg.value == mintPrice, "Wrong price");
        require(editionSize == 0 || (tokenCounter.current() - 1) <= editionSize, "Sold out");

        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;

        if (tokenId == 0) {
            return _mintEditions(toMint);
        } else {
            _mint(toMint[0], tokenId);
            emit EditionMinted(mintPrice, msg.sender);
            setMetadata(tokenId, string(abi.encodePacked('{"token":"', sharedNFTLogic.numberToString(tokenId), '","evolution":"', sharedNFTLogic.numberToString(evolution), '", "claims":[]}')));
            return tokenCounter.current();
        }
    }

    /**
      @dev This allows a user to claim an edition at the current claim price.

     */
    function claim(uint256 tokenId, string calldata claimCode)
        external
        payable
    {
        require(msg.value >= claimPrice, "Wrong price");
        uint refund = msg.value - claimPrice;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        _tokenData[tokenId].claims += uint64(1);
        _tokenData[tokenId].claimsBalance += claimPrice;
        emit EditionClaimed(msg.sender, claimPrice, evolution, claimCode);
    }

    /**
      @param _mintPrice the amount of ETH needed to start the sale.
      @dev This sets a simple ETH sales price
           Setting a sales price allows users to mint the edition until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setMintPrice(uint256 _mintPrice)
        external
        onlyOwner
    {
        mintPrice = _mintPrice;
        emit PriceChanged(mintPrice);
    }

    /**
      @param _claimPrice the amount of ETH needed to claim an Edition.
      @dev This sets a simple ETH claim price
           Setting a claim price allows users to pay additional Eth for physical redemptions.
           If a zero value is set, any funds sent to the contract will be refunded, yet emitted.
     */
    function setClaimPrice(uint256 _claimPrice)
        external
        onlyOwner
    {
        claimPrice = _claimPrice;
        emit ClaimPriceChanged(claimPrice);
    }

    /**
      @dev This withdraws ETH from the contract to the contract owner.
     */
    function withdraw()
        external
        onlyOwner
    {
        // No need for gas limit to trusted address.
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /**
      @dev This helper function checks if the msg.sender is allowed to mint the
            given edition id.
     */
    function _isAllowedToMint()
        internal
        view
        returns (bool)
    {
        // If the owner attempts to mint
        if (owner() == msg.sender) {
            return true;
        }
        // Anyone is allowed to mint
        if (allowedMinters[address(0x0)]) {
            return true;
        }
        // Otherwise use the allowed minter check
        return allowedMinters[msg.sender];
    }

    /**
      @param to address to send the newly minted edition to
      @dev This mints one edition to the given address by an allowed minter on the edition instance.
     */
    function mintEdition(address to)
        external
        override
        onlyUnpaused
        returns (uint256)
    {
        require(_isAllowedToMint(), "Needs to be an allowed minter");
        address[] memory toMint = new address[](1);
        toMint[0] = to;
        // console.log('Start at', tokenCounter.current());

        return _mintEditions(toMint);
    }

    /**
      @param recipients list of addresses to send the newly minted editions to
      @dev This mints multiple editions to the given list of addresses.
     */
    function mintEditions(address[] memory recipients)
        external
        override
        returns (uint256)
    {
        require(_isAllowedToMint(), "Needs to be an allowed minter");
        return _mintEditions(recipients);
    }

    /**
        Simple override for owner interface.
     */
    function owner()
        public
        view
        override(IEditionSingleMintable)
        returns (address)
    {
        return ERC721Delegated._owner();
    }

    /**
      @param minter address to set approved minting status for
      @param allowed boolean if that address is allowed to mint
      @dev Sets the approved minting status of the given address.
           This requires that msg.sender is the owner of the given edition id.
           If the ZeroAddress (address(0x0)) is set as a minter,
             anyone will be allowed to mint.
           This setup is similar to setApprovalForAll in the ERC721 spec.
     */
    function setApprovedMinter(address minter, bool allowed)
        public
        onlyOwner 
    {
        allowedMinters[minter] = allowed;
    }

    /**
      @dev Allows for updates of edition urls by the owner of the edition.
           Only URLs can be updated (data-uris are supported), hashes cannot be updated.
     */
    function setBaseURI(string memory _baseURI)
        public
        onlyOwner 
    {
        _setBaseURI(_baseURI, "");
    }

    // Returns the number of editions allowed to mint (max_uint256 when open edition)
    function numberCanMint()
        external
        view
        override
        returns (uint256)
    {
        // Return max int if open edition
        if (editionSize == 0) {
            return type(uint256).max;
        }
        return maxNumberCanMint;
    }

    /**
      @dev Allows for number of editions allowed to mint to be updated by the owner of the edition.
     */
    function setNumberCanMint(uint256 _numberCanMint)
        public
        onlyOwner
    {
        maxNumberCanMint = _numberCanMint;
    }

    /**
        @param tokenId Token ID to burn
        User burn function for token id 
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        _burn(tokenId);
    }

    /**
      @dev Private function to mint als without any access checks.
           Called by the public edition minting functions.
     */
    function _mintEditions(address[] memory recipients)
        internal
        returns (uint256)
    {
        uint256 startAt = tokenCounter.current();
        uint256 endAt = startAt + (recipients.length - 1);
        require(editionSize == 0 || endAt <= editionSize, "Sold out");

        while (tokenCounter.current() <= endAt) {
            // Get next available token id
            uint256 tokenId = tokenCounter.current();
            for(uint8 i=1; i<= editionSize + 1; i++) {
                if (!_exists(i)) {
                    tokenId = i;
                    break;
                }
            }
            // Mint the edition
            _mint(
                recipients[tokenCounter.current() - startAt],
                tokenId
            );
            tokenCounter.increment();
            setMetadata(tokenId, string(abi.encodePacked('{"token":"', sharedNFTLogic.numberToString(tokenId), '","evolution":"', sharedNFTLogic.numberToString(evolution), '", "claims":[]}')));
            emit EditionMinted(mintPrice, msg.sender);
        }
        return tokenCounter.current();
    }

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function tokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), "No token found");
        return _tokenURI(tokenId);
    }

    /**
      @dev Allows for updates of metadata by the owner of the edition.
     */
    function setMetadata(uint256 tokenId, string memory _metadata)
        public
        onlyOwner
    {
        require(_exists(tokenId), "No token found");
        // console.log('setMetadata', tokenId);
        // console.log('- metadataJson SIZE', bytes(_metadata).length);
        // string memory _m = sharedNFTLogic.base64Encode(bytes(_metadata));
        // console.log('- _m SIZE', bytes(_m).length);
        metadataJson[tokenId] = _metadata;
    }

    /**
        @dev Returns the auxillary data for `owner`.
     */
    function getAux(address _owner)
        public
        view
        returns (uint64)
    {
        return ERC721Delegated._getAux(_owner);
    }

    /**
      @dev Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function setAux(address _owner, uint64 aux)
        public
        onlyOwner
    {
        ERC721Delegated._setAux(_owner, aux);
    }

    /**
        @dev Get Metadata for given token id
        @param tokenId token id to get metadata for
        @return base64-encoded json metadata object
    */
    function getMetadata(uint256 tokenId)
        external
        view
        returns (string memory) 
    {
        require(_exists(tokenId), "No token found");
        return metadataJson[tokenId];
    }

    /**
     * Returns the number of minted tokens (burning factored in).
     */
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return ERC721Delegated._totalSupply();
    }

    /**
     * Returns the number of tokens minted by owner.
     */
    function numberMintedByOwner(address _owner)
        public
        view
        returns (uint256)
    {
        return ERC721Delegated._numberMinted(_owner);
    }

    /**
     * Returns the number of claims by token.
     */
    function numberClaims(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _tokenData[tokenId].claims;
    }

    /**
     * Returns the number of claims by token.
     */
    function claimsBalance(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _tokenData[tokenId].claimsBalance;
    }

    /**
     * Set current Evolution state for the collection
     */
    function setEvolution(uint256 _evolution)
        public
        onlyOwner
    {
        evolution = _evolution;
    }

    /**
     * Get current Evolution state
     */
    function getEvolution()
        public
        view
        returns (uint256)
    {
        return evolution;
    }

    /**
     * Transfer token
     */
    function transferOwnership(address newOwner)
        external
        onlyOwner
    {
        ERC721Delegated._transferOwnership(newOwner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        returns (bool)
    {
        return
            type(IERC2981).interfaceId == interfaceId ||
            type(IERC721).interfaceId == interfaceId ||
            type(IEditionSingleMintable).interfaceId == interfaceId;
    }
}
