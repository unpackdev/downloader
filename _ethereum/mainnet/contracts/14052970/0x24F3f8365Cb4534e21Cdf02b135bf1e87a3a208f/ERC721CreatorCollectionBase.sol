// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorCore.sol";
import "./CreatorExtension.sol";
import "./Strings.sol";

import "./IERC721Collection.sol";
import "./CollectionBase.sol";

/**
 * ERC721 Creator Collection Drop Contract (Base)
 */
abstract contract ERC721CreatorCollectionBase is CollectionBase, CreatorExtension, IERC721Collection {
    
    using Strings for uint256;

    // Immutable variables that should only be set by the constructor or initializer
    address internal _creator;
    uint16 public tokenMax;
    uint256 public tokenPrice;
    uint16 public transactionLimit;
    uint16 public purchaseLimit;
    uint256 public presaleTokenPrice;
    uint16 public presalePurchaseLimit;

    // Minted token information
    uint16 public tokenCount;
    mapping(address => uint16) internal _addressMintCount;


    function _initialize(address creator, uint16 tokenMax_, uint256 tokenPrice_, uint16 transactionLimit_, uint16 purchaseLimit_, uint256 presaleTokenPrice_, uint16 presalePurchaseLimit_, address signingAddress) internal {
        require(_creator == address(0) && _signingAddress == address(0), "Already initialized");
        _creator = creator;
        tokenMax = tokenMax_;
        tokenPrice = tokenPrice_;
        transactionLimit = transactionLimit_;
        purchaseLimit = purchaseLimit_;
        presaleTokenPrice = presaleTokenPrice_;
        presalePurchaseLimit = presalePurchaseLimit_;
        _signingAddress = signingAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtension, IERC165) returns (bool) {
      return interfaceId == type(IERC721Collection).interfaceId || CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * Premint tokens to the owner.  Sale must not be active.
     */
    function _premint(uint16 amount, address owner) internal virtual {
        require(!active, "Already active");
        _mint(owner, amount);
    }

    /**
     * Premint tokens to the list of addresses.  Sale must not be active.
     */
    function _premint(address[] calldata addresses) internal virtual {
        require(!active, "Already active");
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i], 1);
        }
    }

    /**
     * @dev override if you want to perform different mint functionality
     */
    function _mint(address to, uint16 amount) internal virtual {
        if (amount == 1) {
            tokenCount++;
        
            // Mint token
            uint256 tokenId = IERC721CreatorCore(_creator).mintExtension(to);
            
            emit Unveil(tokenCount, _creator, tokenId);
        } else {
            uint256 tokenStart = tokenCount+1;
            tokenCount += amount;
        
            // Mint token
            uint256[] memory tokenIds = IERC721CreatorCore(_creator).mintExtensionBatch(to, amount);

            for (uint i = 0; i < tokenIds.length; i++) {
                emit Unveil(tokenStart+i, _creator, tokenIds[i]);
            }
        }
    }

    /**
     *  Set the tokenURI prefix
     */
    function _setTokenURIPrefix(string calldata prefix) internal virtual {
        IERC721CreatorCore(_creator).setBaseTokenURIExtension(prefix);
    }
    
    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePrice(uint16 amount) internal virtual {
      require(msg.value == amount*tokenPrice, "Invalid purchase amount sent");
    }

    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePresalePrice(uint16 amount) internal virtual {
      require(msg.value == amount*presaleTokenPrice, "Invalid purchase amount sent");
    }


    /**
     * @dev See {IERC721Collection-purchase}.
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, string calldata nonce) external payable virtual override {
        _validatePurchaseRestrictions();

        // Check purchase amounts
        require(amount <= tokenRemaining() && (transactionLimit == 0 || amount <= transactionLimit), "Too many requested");
        if (block.timestamp - startTime < presaleInterval) {
            require(amount <= (presalePurchaseLimit-_addressMintCount[msg.sender]), "Too many requested");
            _validatePresalePrice(amount);
            _addressMintCount[msg.sender] += amount;
        } else {
            require(purchaseLimit == 0 || amount <= (purchaseLimit-_addressMintCount[msg.sender]), "Too many requested");
            _validatePrice(amount);
            if (purchaseLimit != 0) {
                _addressMintCount[msg.sender] += amount;
            }
        }
        _validatePurchaseRequest(message, signature, nonce);
        
        _mint(msg.sender, amount);
    }

    /**
     * @dev See {IERC721Collection-state}
     */
    function state() external override view returns(CollectionState memory) {
        return CollectionState(tokenMax, tokenMax-tokenCount, tokenPrice, transactionLimit, purchaseLimit, presaleTokenPrice, presalePurchaseLimit, _addressMintCount[msg.sender], active, startTime, endTime, presaleInterval);
    }

    /**
     * @dev See {IERC721Collection-tokenRemaining}.
     */
    function tokenRemaining() public view virtual override returns(uint16) {
        return tokenMax-tokenCount;
    }

}
