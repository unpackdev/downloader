// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ReentrancyGuard.sol";

import "./IERC721CreatorCore.sol";
import "./CreatorExtension.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./Strings.sol";

import "./IERC721Collection.sol";
import "./CollectionBase.sol";

/**
 * ERC721 Collection Drop Contract (Base)
 */
abstract contract ERC721CollectionBase is ReentrancyGuard, CollectionBase, CreatorExtension, IERC721Collection, ICreatorExtensionTokenURI {
    
    using Strings for uint256;

    // Immutable variables that should only be set by the constructor or initializer
    uint16 public tokenMax;
    uint16 public purchaseLimit;
    uint16 public presalePurchaseLimit;
    uint256 public tokenPrice;

    // Minted token information
    uint16 public tokenCount;
    mapping(uint256 => uint256) internal _mintNumbers;
    mapping(address => uint16) internal _addressMintCount;

    // Token URI Prefix
    string private _tokenURIPrefix;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtension, IERC165) returns (bool) {
      return interfaceId == type(IERC721Collection).interfaceId || interfaceId == type(ICreatorExtensionTokenURI).interfaceId 
          || CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * Premint tokens to the owner.  Sale must not be active.
     */
    function _premint(uint16 amount, address owner) internal virtual {
        require(!active, "Already active");
        for (uint i = 0; i < amount; i++) {
            _mint(owner);
        }
    }

    /**
     * Premint tokens to the list of addresses.  Sale must not be active.
     */
    function _premint(address[] calldata addresses) internal virtual {
        require(!active, "Already active");
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i]);
        }
    }

    /**
     * @dev override if you want to perform different mint functionality
     */
    function _mint(address to) internal virtual {
        tokenCount++;
        _addressMintCount[to]++;
        
        // Mint token
        uint256 tokenId = IERC721CreatorCore(_creator).mintExtension(to);
        _mintNumbers[tokenId] = tokenCount;

        emit Unveil(tokenCount, _creator, tokenId);
    }

    /**
     *  Set the tokenURI prefix
     */
    function _setTokenURIPrefix(string calldata prefix) internal virtual {
        _tokenURIPrefix = prefix;
    }
    
    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePrice(uint16 amount) internal virtual {
      require(msg.value == amount*tokenPrice, "Invalid purchase amount sent");
    }


    /**
     * @dev See {IERC721Collection-purchase}.
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, string calldata nonce) external payable virtual override nonReentrant {
        _validatePurchaseRestrictions();

        // Check purchase amounts
        require(amount <= tokenRemaining(), "Too many requested");
        if (block.timestamp - startTime < presaleInterval) {
            require(_addressMintCount[msg.sender] == 0 && amount <= presalePurchaseLimit, "Too many requested");
        } else {
            require(amount <= (purchaseLimit-_addressMintCount[msg.sender]), "Too many requested");
        }
        _validatePrice(amount);
        _validatePurchaseRequest(message, signature, nonce);
        
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender);
        }
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _mintNumbers[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked(_tokenURIPrefix, _mintNumbers[tokenId].toString()));
    }

    /**
     * @dev See {IERC721Collection-state}
     */
    function state() external override view returns(CollectionState memory) {
        return CollectionState(tokenMax, tokenPrice, tokenMax-tokenCount, purchaseLimit, presalePurchaseLimit, _addressMintCount[msg.sender], active, startTime, endTime, presaleInterval);
    }

    /**
     * @dev See {IERC721Collection-tokenRemaining}.
     */
    function tokenRemaining() public view virtual override returns(uint16) {
        return tokenMax-tokenCount;
    }

    /**
     * @dev See {IERC721Collection-mintNumber}.
     */
    function mintNumber(uint256 tokenId) external view virtual override returns(uint256) {
        return _mintNumbers[tokenId];
    }

}
