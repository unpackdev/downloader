// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

///////////////////////////////////////////////////
//                                               //
//                                 _             //
//       __ _  ___ _ __   ___  ___(_)___         //
//      / _` |/ _ \ '_ \ / _ \/ __| / __|        //
//     | (_| |  __/ | | |  __/\__ \ \__ \        //
//      \__, |\___|_| |_|\___||___/_|___/        //
//      |___/                                    //
//                                               //
///////////////////////////////////////////////////


/// @creator: @tzmartin
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

import "./console.sol";

/**
*/
contract GenesisNFT is
    ERC721Delegated, IEditionSingleMintable
{
    using Counters for Counters.Counter;

    // Events
    event PriceChanged(uint256 amount);
    event EditionMinted(uint256 price, address owner);

    struct TokenData {
        uint256 id;
        uint256 mintPrice;
        bool paused;
    }

    uint256 public maxNumberCanMint = 1;

    // Token Name
    string public name;

    // Token symbol
    string public symbol;

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

        // Seed initial Genesis Collection
        _tokenData[1] = TokenData({id: 1, mintPrice: 1900000000000000000, paused: false});
        _tokenData[2] = TokenData({id: 2, mintPrice: 6700000000000000000, paused: false});
        _tokenData[3] = TokenData({id: 3, mintPrice: 6300000000000000000, paused: false});
        _tokenData[4] = TokenData({id: 4, mintPrice: 6700000000000000000, paused: false});
        _tokenData[5] = TokenData({id: 5, mintPrice: 7500000000000000000, paused: false});
        _tokenData[6] = TokenData({id: 6, mintPrice: 2700000000000000000, paused: false});
        _tokenData[7] = TokenData({id: 7, mintPrice: 19500000000000000000, paused: false});
        _tokenData[8] = TokenData({id: 8, mintPrice: 4600000000000000000, paused: false});
        _tokenData[9] = TokenData({id: 9, mintPrice: 50000000000000000000, paused: false});
        _tokenData[10] = TokenData({id: 10, mintPrice: 1900000000000000000, paused: false});
        _tokenData[11] = TokenData({id: 11, mintPrice: 6500000000000000000, paused: false});
        _tokenData[12] = TokenData({id: 12, mintPrice: 2700000000000000000, paused: false});
        _tokenData[13] = TokenData({id: 13, mintPrice: 1400000000000000000, paused: false});
        _tokenData[14] = TokenData({id: 14, mintPrice: 2300000000000000000, paused: false});
        _tokenData[15] = TokenData({id: 15, mintPrice: 50000000000000000000, paused: false});
        _tokenData[16] = TokenData({id: 16, mintPrice: 20900000000000000000, paused: false});
        _tokenData[17] = TokenData({id: 17, mintPrice: 1800000000000000000, paused: false});
        _tokenData[18] = TokenData({id: 18, mintPrice: 4600000000000000000, paused: false});
        _tokenData[19] = TokenData({id: 19, mintPrice: 2700000000000000000, paused: false});
        _tokenData[20] = TokenData({id: 20, mintPrice: 5500000000000000000, paused: false});
        _tokenData[21] = TokenData({id: 21, mintPrice: 6700000000000000000, paused: false});
        _tokenData[22] = TokenData({id: 22, mintPrice: 6200000000000000000, paused: false});
        _tokenData[23] = TokenData({id: 23, mintPrice: 11500000000000000000, paused: false});
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

    /**
      @dev Set contract paused state
    */
    function setPaused(bool _paused)
        public
        onlyOwner
    {
        paused = _paused;
    }

    /**
      @dev Add token to collection
      @param _tokenId Token ID
      @param _mintPrice Mint price
      @param _paused Paused state for token
     */
    function addToken(uint256 _tokenId, uint256 _mintPrice, bool _paused)
        public
        onlyOwner
    {
        _tokenData[_tokenId].id = _tokenId;
        _tokenData[_tokenId].mintPrice = _mintPrice;
        _tokenData[_tokenId].paused = _paused;
    }

    /**
      @param tokenId the token Id
      @param _mintPrice the amount of ETH needed to start the sale for a given token.
      @dev This sets a simple ETH sales price for a given token
           Setting a sales price allows users to mint the edition until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setMintPrice(uint256 tokenId, uint256 _mintPrice)
        external
        onlyOwner
    {
        _tokenData[tokenId].mintPrice = _mintPrice;
        emit PriceChanged(_mintPrice);
    }

    /**
      @dev Sets pause state for token.
     */
    function setTokenPaused(uint256 tokenId, bool _paused)
        public
        onlyOwner
    {
        _tokenData[tokenId].paused = _paused;
    }

    /**
      @dev Returns the total amount of tokens minted in the contract.
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
        require(_isAllowedToMint(), "Needs to be an allowed minter");
        require(!(_tokenData[tokenId].id == 0), "Unregistered Token");
        require(msg.value == _tokenData[tokenId].mintPrice, "Wrong price");
        require(!_tokenData[tokenId].paused, "Token paused");
        require(editionSize == 0 || (tokenCounter.current() - 1) <= editionSize, "Sold out");

        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;

        _mint(toMint[0], tokenId);

        // Update token counter
        tokenCounter.increment();

        // Emit event
        emit EditionMinted(_tokenData[tokenId].mintPrice, msg.sender);

        return tokenCounter.current();
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
      simple override for owner interface.
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

    /**
      @dev Returns the number of editions allowed to mint (max_uint256 when open edition)
    */
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
      @dev User burn function for token id 
      @param tokenId Token ID to burn
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        _burn(tokenId);
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
      @dev Returns the number of minted tokens (burning factored in).
     */
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return ERC721Delegated._totalSupply();
    }

    /**
      @dev Returns the number of tokens minted by owner.
     */
    function numberMintedByOwner(address _owner)
        public
        view
        returns (uint256)
    {
        return ERC721Delegated._numberMinted(_owner);
    }

    /**
      @dev Returns the mint price for a token.
      @param tokenId token id
     */
    function mintPrice(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _tokenData[tokenId].mintPrice;
    }

    /**
      @dev Transfer token
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
