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
    uint16 public transactionLimit;
    uint16 public purchaseMax;
    uint256 public purchasePrice;
    uint16 public purchaseLimit;
    uint256 public presalePurchasePrice;
    uint16 public presalePurchaseLimit;
    bool public useDynamicPresalePurchaseLimit;

    // Minted token information
    uint16 public purchaseCount;
    mapping(address => uint16) internal _addressMintCount;

    // Transfer lock
    bool public transferLocked;

    function _initialize(address creator, uint16 purchaseMax_, uint256 purchasePrice_, uint16 purchaseLimit_, uint16 transactionLimit_, uint256 presalePurchasePrice_, uint16 presalePurchaseLimit_, address signingAddress, bool useDynamicPresalePurchaseLimit_) internal {
        require(_creator == address(0) && _signingAddress == address(0), "Already initialized");
        _creator = creator;
        purchaseMax = purchaseMax_;
        purchasePrice = purchasePrice_;
        purchaseLimit = purchaseLimit_;
        transactionLimit = transactionLimit_;
        presalePurchasePrice = presalePurchasePrice_;
        presalePurchaseLimit = presalePurchaseLimit_;
        _signingAddress = signingAddress;
        useDynamicPresalePurchaseLimit = useDynamicPresalePurchaseLimit_;
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
            purchaseCount++;
        
            // Mint token
            uint256 tokenId = IERC721CreatorCore(_creator).mintExtension(to);
            
            emit Unveil(purchaseCount, _creator, tokenId);
        } else {
            uint256 tokenStart = purchaseCount+1;
            purchaseCount += amount;
        
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
      require(msg.value == amount*purchasePrice, "Invalid purchase amount sent");
    }

    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePresalePrice(uint16 amount) internal virtual {
      require(msg.value == amount*presalePurchasePrice, "Invalid purchase amount sent");
    }

    /**
     * Returns whether or not token transfers are enabled.
     */
    function _validateTokenTransferability(address from) internal view returns(bool) {
        return from == address(0) || !transferLocked;
    }

    /**
     * Set whether or not token transfers are locked
     */
    function _setTransferLocked(bool locked) internal {
        transferLocked = locked;
    }

    /**
     * @dev See {IERC721Collection-claim}.
     */
    function claim(uint16 amount, bytes32 message, bytes calldata signature, string calldata nonce) external virtual override {
        _validateClaimRestrictions();
        _validateClaimRequest(message, signature, nonce, amount);
        _mint(msg.sender, amount);

        _addressMintCount[msg.sender] += amount;
    }
    
    /**
     * @dev See {IERC721Collection-purchase}.
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, string calldata nonce) external payable virtual override {
        _validatePurchaseRestrictions();

        bool isPresale = _isPresale();

        // Check purchase amounts
        require(amount <= purchaseRemaining() && ((isPresale && useDynamicPresalePurchaseLimit) || transactionLimit == 0 || amount <= transactionLimit), "Too many requested");

        if (isPresale) {
            require(useDynamicPresalePurchaseLimit || ((presalePurchaseLimit == 0 || amount <= (presalePurchaseLimit-_addressMintCount[msg.sender])) && (purchaseLimit == 0 || amount <= (purchaseLimit-_addressMintCount[msg.sender]))), "Too many requested");
            _validatePresalePrice(amount);
            _addressMintCount[msg.sender] += amount;
        } else {
            require(purchaseLimit == 0 || amount <= (purchaseLimit-_addressMintCount[msg.sender]), "Too many requested");
            _validatePrice(amount);
            if (purchaseLimit != 0) {
                _addressMintCount[msg.sender] += amount;
            }
        }

        if (isPresale && useDynamicPresalePurchaseLimit) {
            _validatePurchaseRequestWithAmount(message, signature, nonce, amount);
        } else {
            _validatePurchaseRequest(message, signature, nonce);
        }

        _mint(msg.sender, amount);
    }

    /**
     * @dev See {IERC721Collection-state}
     */
    function state() external override view returns(CollectionState memory) {
        return CollectionState(transactionLimit, purchaseMax, purchaseRemaining(), purchasePrice, purchaseLimit, presalePurchasePrice, presalePurchaseLimit, _addressMintCount[msg.sender], active, startTime, endTime, presaleInterval, claimStartTime, claimEndTime, useDynamicPresalePurchaseLimit);
    }

    /**
     * @dev See {IERC721Collection-purchaseRemaining}.
     */
    function purchaseRemaining() public view virtual override returns(uint16) {
        return purchaseMax-purchaseCount;
    }

}
