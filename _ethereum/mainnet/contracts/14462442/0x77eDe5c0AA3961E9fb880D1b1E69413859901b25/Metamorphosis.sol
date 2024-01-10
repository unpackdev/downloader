// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./ERC721.sol";
import "./Strings.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//   _____  _____  _____  _____  _____  _____  _____                                             //
//  |     ||  |  ||  _  ||  _  ||_   _||   __|| __  |                                            //
//  |   --||     ||     ||   __|  | |  |   __||    -|                                            //
//  |_____||__|__||__|__||__|     |_|  |_____||__|__|                                            //
//   _____  _ _ _  _____                                                                         //
//  |_   _|| | | ||     |                                                                        //
//    | |  | | | ||  |  |                                                                        //
//    |_|  |_____||_____|                                                                        //
//   _____  _____  _____  _____  _____  _____  _____  _____  _____  _____  _____  _____  _____   //
//  |     ||   __||_   _||  _  ||     ||     || __  ||  _  ||  |  ||     ||   __||     ||   __|  //
//  | | | ||   __|  | |  |     || | | ||  |  ||    -||   __||     ||  |  ||__   ||-   -||__   |  //
//  |_|_|_||_____|  |_|  |__|__||_|_|_||_____||__|__||__|   |__|__||_____||_____||_____||_____|  //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////

contract Metamorphosis is AdminControl, ERC721 {

    using Strings for uint256;

    struct Creator {
        address address_;
        bool signed;
        uint32 editions;
        uint32 total;
        string name;
    }

    struct CreatorNFT {
        string name;
        string description;
        string imageURI;
        string animationURI;
    }

    struct CreatorNFTConfig {
      address creator;
      CreatorNFT nft;
    }

    // URI tags and data
    string constant private _NAME_TAG = '<NAME>';
    string constant private _DESCRIPTION_TAG = '<DESCRIPTION>';
    string constant private _CREATOR_TAG = '<CREATOR>';
    string constant private _EDITION_TAG = '<EDITION>';
    string constant private _TOTAL_TAG = '<TOTAL>';
    string constant private _IMAGE_TAG = '<IMAGE>';
    string constant private _ANIMATION_TAG = '<ANIMATION>';
    string constant private _FORM_TAG = '<FORM>';
    string[] private _uriParts;
    bool private _transferLock;

    // Marketplace configuration
    address private _marketplace;
    uint256 private _listingId;
    bytes4 private constant _INTERFACE_MARKETPLACE_LAZY_DELIVERY = 0xc83afbd0;
    string private _assetURI;

    // Token configuration
    uint256 public MAX_TOKENS;
    uint256 public constant CREATOR_TOKENS = 10;
    uint256 public constant CREATOR_MAX_TOKENS = 250;
    uint256 public MAX_PURCHASE;
    uint256 public MAX_FORM;
    uint256 private _mintCount;
    
    Creator[] private _creators;
    // tokenId -> form
    mapping(uint256 => uint256) private _tokenForm;
    // form -> creatorIndex -> CreatorNFT
    mapping(uint256 => mapping(uint256 => CreatorNFT)) private _creatorNFTs;

    bool private _activated;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor() ERC721("Metamorphosis", "MORPH") {
        _uriParts = [
            'data:application/json;utf8,{"name":"',_NAME_TAG,' #',_EDITION_TAG,'", "description":"',_DESCRIPTION_TAG,
            '", "created_by":"',_CREATOR_TAG,'", "image":"',_IMAGE_TAG,'", "animation_url":"',_ANIMATION_TAG,
            '", "attributes":[{"trait_type":"Collection","value":"Metamorphosis"},',
            '{"trait_type":"Creator","value":"',_CREATOR_TAG,'"},{"trait_type":"Form","value":"',_FORM_TAG,'"}]}'
        ];
        _transferLock = true;
    }

    /**
     * View list of all creators
     */
    function creators() external view returns(Creator[] memory) {
        return _creators;
    }

    /**
     * Set participating creators
     */
    function setCreators(Creator[] memory creators_) external adminRequired {
        require(!_activated, "Cannot set creators after activation");
        delete _creators;
        for (uint i; i < creators_.length; i++) {
            Creator memory creator = creators_[i];
            require(!creator.signed, "signed must be false");
            require(creator.editions == 0 && creator.total == 0, "edition and total must be 0");
            _creators.push(creator);
        }
    }

    /**
     * Update nft configuration
     */
    function configureNFTs(uint256 form, CreatorNFTConfig[] memory nftConfigs) external adminRequired {
        for (uint i; i < nftConfigs.length; i++) {
            CreatorNFTConfig memory nftConfig = nftConfigs[i];
            bool found = false;
            uint creatorIndex;
            for (uint j; j < _creators.length; j++) {
              if (_creators[j].address_ == nftConfig.creator) {
                found = true;
                creatorIndex = j;
                break;
              }
            }
            require(found, "Creator does not exist");
            _creatorNFTs[form][creatorIndex] = nftConfig.nft;
        }
    }

    /**
     * Sign the collection as an creator. Mints the first NFT to them
     */
    function sign() external {
        require(_activated, "Not activated");
        bool found = false;
        for (uint i; i < _creators.length; i++) {
            if (_creators[i].address_ == msg.sender) {
                require(!_creators[i].signed, "You have already signed");
                found = true;
                _creators[i].signed = true;
                for (uint j; j < CREATOR_TOKENS; j++) {
                    uint256 tokenId = i*CREATOR_MAX_TOKENS+j+1;
                    _mint(msg.sender, tokenId);
                }
                break;
            }
        }
        require(found, "You are not an creator");
    }

    /**
     * Activate the sale
     */
    function activate(uint256 maxPurchase, uint256 maxForm) external adminRequired {
        require(!_activated, "Already activated");
        for (uint i; i < _creators.length; i++) {
            Creator storage creator = _creators[i];
            creator.editions = uint32(CREATOR_TOKENS);
            creator.total = uint32(CREATOR_TOKENS);
        }
        MAX_TOKENS = CREATOR_MAX_TOKENS*_creators.length;
        _mintCount = CREATOR_TOKENS*_creators.length;
        MAX_PURCHASE = maxPurchase;
        MAX_FORM = maxForm;
        _activated = true;        
    }

    /**
     * Set the max form
     */
    function setMaxForm(uint256 maxForm) external adminRequired {
        MAX_FORM = maxForm;
    }

    /**
     * Mint an NFT
     */
    function _mintNFT(address recipient, uint256 creatorIndex) private returns (uint256) {
        Creator storage creator = _creators[creatorIndex];
        address creatorAddress = creator.address_;
        creator.editions++;
        creator.total++;
        uint256 tokenId = creatorIndex*CREATOR_MAX_TOKENS+creator.editions;
        _mintCount++;
        _mint(creatorAddress, tokenId);
        if (creatorAddress != recipient) {
            _transfer(creatorAddress, recipient, tokenId);
        }
        return tokenId;
    }

    /**
     * @dev Set the listing
     */
    function setListing(address marketplace, uint256 listingId) external adminRequired {
        require(_activated, "Not activated");
        _marketplace = marketplace;
        _listingId = listingId;
    }

    /**
     * @dev Set the asset uri for unsold item
     */
    function setAssetURI(string calldata uri) external adminRequired {
        _assetURI = uri;
    }

    /**
     * @dev Return asset data for a marketplace sale
     */
    function assetURI(uint256 assetId) external view returns(string memory) {
        require(assetId == 1, "Invalid asset");
        return _assetURI;
    }

    function updateTokenURIParts(string[] memory uriParts) external adminRequired {
        _uriParts = uriParts;
    }

    /**
     * @dev Deliver token from a marketplace sale
     */
    function deliver(address, uint256 listingId, uint256 assetId, address to, uint256, uint256 index) external returns(uint256) {
        require(msg.sender == _marketplace && listingId == _listingId && assetId == 1 && index == 0, "Invalid call data");
        require(_mintCount + 1 <= MAX_TOKENS && (to == owner() || balanceOf(to) + 1 <= MAX_PURCHASE), "Too many requested");
        uint256 creatorCount = _creators.length;
        uint256 startIndex = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _mintCount))) % creatorCount;
        uint256 creatorIndex = startIndex;
        bool minted = false;
        uint256 tokenId;
        do {
           if (_creators[creatorIndex].editions < CREATOR_MAX_TOKENS) {
              tokenId = _mintNFT(to, creatorIndex);
              minted = true;
              break;
           }
           creatorIndex = (creatorIndex + 1) % creatorCount;
        } while (creatorIndex != startIndex);

        require(minted, "Error minting token");
        return 0;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 creatorIndex = tokenId / CREATOR_MAX_TOKENS;
        CreatorNFT memory creatorNFT = _creatorNFTs[_tokenForm[tokenId]][creatorIndex];
        Creator memory creator = _creators[creatorIndex];
        bytes memory byteString;
        for (uint i; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _NAME_TAG)) {
                byteString = abi.encodePacked(byteString, creatorNFT.name);
            } else if (_checkTag(_uriParts[i], _DESCRIPTION_TAG)) {
                byteString = abi.encodePacked(byteString, creatorNFT.description);
            } else if (_checkTag(_uriParts[i], _CREATOR_TAG)) {
                byteString = abi.encodePacked(byteString, creator.name);
            } else if (_checkTag(_uriParts[i], _IMAGE_TAG)) {
                byteString = abi.encodePacked(byteString, creatorNFT.imageURI);
            } else if (_checkTag(_uriParts[i], _ANIMATION_TAG)) {
                byteString = abi.encodePacked(byteString, creatorNFT.animationURI);
            } else if (_checkTag(_uriParts[i], _FORM_TAG)) {
                byteString = abi.encodePacked(byteString, (_tokenForm[tokenId]+1).toString());
            } else if (_checkTag(_uriParts[i], _EDITION_TAG)) {
                byteString = abi.encodePacked(byteString, (tokenId-creatorIndex*CREATOR_MAX_TOKENS).toString());
             } else if (_checkTag(_uriParts[i], _TOTAL_TAG)) {
                byteString = abi.encodePacked(byteString, uint256(_creators[creatorIndex].total).toString());
            } else {
                byteString = abi.encodePacked(byteString, _uriParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setTransferLock(bool lock) public adminRequired {
        _transferLock = lock;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(!_transferLock, "ERC721: transfer not permitted");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(!_transferLock, "ERC721: transfer not permitted");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        if (to == address(0xdead)) {
            _burn(tokenId);
        } else {
            super._transfer(from, to, tokenId);
        }
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        require(!_transferLock, "ERC721: transfer not permitted");
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        _creators[tokenId / CREATOR_MAX_TOKENS].total--;
        delete _tokenForm[tokenId];
        super._burn(tokenId);
    }

    /**
     * Get token form
     */
    function tokenForm(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: query for nonexistent token");
        return _tokenForm[tokenId]+1;
    }

    /**
     * Get total count for a given token
    */
    function tokenTotalCount(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: query for nonexistent token");
        return _creators[tokenId / CREATOR_MAX_TOKENS].total;
    }

    /**
     * Morph a token
     */
    function morph(uint256 tokenId, uint256[] calldata burnedTokenIds) external {
        require(!_transferLock, "Morph not permitted");
        require(burnedTokenIds.length == 4, "Insufficient tokens");
        address tokenOwner = ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Must be token owner");
        uint256 currentForm = _tokenForm[tokenId];
        require(currentForm+1 < MAX_FORM, "Max form reached");
        for (uint i; i < burnedTokenIds.length; i++) {
            uint256 burnedTokenId = burnedTokenIds[i];
            require(tokenId != burnedTokenId && ownerOf(burnedTokenId) == msg.sender && _tokenForm[burnedTokenId] >= currentForm, "Invalid token to burn");
            for (uint j=i+1; j < burnedTokenIds.length; j++) {
                require(burnedTokenId != burnedTokenIds[j], "Cannot have duplicate tokens");
            }
            _burn(burnedTokenId);
        }
        _tokenForm[tokenId]++;
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId) 
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE || interfaceId == _INTERFACE_MARKETPLACE_LAZY_DELIVERY;
    }

    /**
     * ROYALTY FUNCTIONS
     */    
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

}