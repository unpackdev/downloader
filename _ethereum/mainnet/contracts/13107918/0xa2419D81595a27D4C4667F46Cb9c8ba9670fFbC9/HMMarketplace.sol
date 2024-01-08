// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IHMNFT1155 {
    function creators(uint256) external returns (address);
}

contract HMMarketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    /// @notice Events for the contract
    event ItemListed(
        address indexed owner,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        uint256 pricePerItem,
        uint256 startingTime,
        bool isPrivate,
        address allowedAddress
    );
    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address payToken,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    );
    event ItemUpdated(
        address indexed owner,
        address indexed nft,
        uint256 tokenId,
        uint256 newPrice
    );
    event ItemCanceled(
        address indexed owner,
        address indexed nft,
        uint256 tokenId
    );
    event OfferCreated(
        address indexed creator,
        address indexed nft,
        uint256 tokenId,
        address payToken,
        uint256 quantity,
        uint256 pricePerItem,
        uint256 deadline
    );
    event OfferCanceled(
        address indexed creator,
        address indexed nft,
        uint256 tokenId
    );
    event UpdatePlatformFee(uint256 platformFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);
    event UpdatePayToken(address indexed payToken, bool value);

    /// @notice Structure for listed items
    struct Listing {
        IERC20 payToken;
        uint256 quantity;
        uint256 pricePerItem;
        uint256 startingTime;
        address allowedAddress;
    }

    /// @notice Structure for offer
    struct Offer {
        IERC20 payToken;
        uint256 quantity;
        uint256 pricePerItem;
        uint256 deadline;
    }

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// @notice NftAddress -> Token ID -> Minter
    mapping(address => mapping(uint256 => address)) public minters;

    /// @notice NftAddress -> Token ID -> Royalty
    mapping(address => mapping(uint256 => uint8)) public royalties;

    /// @notice NftAddress -> Token ID -> Owner -> Listing item
    mapping(address => mapping(uint256 => mapping(address => Listing)))
        public listings;

    /// @notice NftAddress -> Token ID -> Offerer -> Offer
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public offers;

    /// @notice address -> amount
    mapping(address => bool) payTokens;

    /// @notice Platform fee
    uint256 public platformFee;

    /// @notice Listing fee
    uint256 public listingFee;

    /// @notice Platform fee receipient
    address payable public feeReceipient;

    /// @notice HM721 contract
    address public hm721;

    uint8 public constant MAX_ROYALTY_FEE = 10;

    /// @notice Contract constructor
    constructor(
        address payable _feeRecipient,
        uint256 _platformFee,
        uint256 _listingFee
    ) public {
        platformFee = _platformFee;
        feeReceipient = _feeRecipient;
        listingFee = _listingFee;
    }

    /// @notice Method for listing NFT
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _quantity token amount to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
    /// @param _pricePerItem sale price for each iteam
    /// @param _startingTime scheduling for a future sale
    /// @param _allowedAddress optional param for private sale
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        IERC20 _payToken,
        uint256 _quantity,
        uint256 _pricePerItem,
        uint256 _startingTime,
        address _allowedAddress
    ) external payable {
        require(payTokens[address(_payToken)], "PayToken is not registered");

        if (_supportERC721(_nftAddress)) {
            IERC721 nft = IERC721(_nftAddress);
            require(
                nft.ownerOf(_tokenId) == _msgSender(),
                "Must be owner of NFT."
            );
            require(
                nft.isApprovedForAll(_msgSender(), address(this)),
                "Must be approved before list."
            );
            require(_quantity == 1, "Quantity value must be one for 721.");
        } else if (_supportERC1155(_nftAddress)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(
                nft.balanceOf(_msgSender(), _tokenId) >= _quantity,
                "Must hold enough NFTs."
            );
            require(
                nft.isApprovedForAll(_msgSender(), address(this)),
                "Must be approved before list."
            );
        } else {
            revert("Invalid NFT address.");
        }

        // Send ListingFee to receipient address
        require(
            msg.value >= listingFee,
            "HMMarketplace: Not enough listing fee sent"
        );
        (bool listingFeeTransferSuccess, ) = feeReceipient.call{
            value: msg.value
        }("");
        require(
            listingFeeTransferSuccess,
            "HMMarketplace: ListingFee Transfer failed"
        );

        listings[_nftAddress][_tokenId][_msgSender()] = Listing(
            _payToken,
            _quantity,
            _pricePerItem,
            _startingTime,
            _allowedAddress
        );
        emit ItemListed(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _quantity,
            _pricePerItem,
            _startingTime,
            _allowedAddress == address(0x0),
            _allowedAddress
        );
    }

    /// @notice Method for canceling listed NFT
    function cancelListing(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        require(
            listings[_nftAddress][_tokenId][_msgSender()].quantity > 0,
            "Not listed item."
        );
        _cancelListing(_nftAddress, _tokenId, _msgSender());
    }

    /// @notice Method for updating listed NFT
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _newPrice New sale price for each iteam
    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    ) external nonReentrant {
        Listing storage listedItem = listings[_nftAddress][_tokenId][
            _msgSender()
        ];
        require(listedItem.quantity > 0, "Not listed item.");
        if (_supportERC721(_nftAddress)) {
            IERC721 nft = IERC721(_nftAddress);
            require(
                nft.ownerOf(_tokenId) == _msgSender(),
                "Not owning the item."
            );
        } else if (_supportERC1155(_nftAddress)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(
                nft.balanceOf(_msgSender(), _tokenId) >= listedItem.quantity,
                "Not owning the item."
            );
        } else {
            revert("Invalid NFT address.");
        }

        listedItem.pricePerItem = _newPrice;
        emit ItemUpdated(_msgSender(), _nftAddress, _tokenId, _newPrice);
    }

    /// @notice Method for buying listed NFT
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        address payable _owner
    ) external payable nonReentrant {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];
        require(listedItem.quantity > 0, "Not listed item.");
        if (_supportERC721(_nftAddress)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _owner, "Not owning the item.");
        } else if (_supportERC1155(_nftAddress)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(
                nft.balanceOf(_owner, _tokenId) >= listedItem.quantity,
                "Not owning the item."
            );
        } else {
            revert("Invalid NFT address.");
        }
        require(
            _getNow() >= listedItem.startingTime,
            "Item is not buyable yet."
        );
        require(
            _tokenAmount >= listedItem.pricePerItem.mul(listedItem.quantity),
            "Not enough amount to buy item."
        );
        if (listedItem.allowedAddress != address(0)) {
            require(
                listedItem.allowedAddress == _msgSender(),
                "You are not eligable to buy item."
            );
        }

        uint256 feeAmount = _tokenAmount.mul(platformFee).div(1e3);
        listedItem.payToken.safeTransferFrom(
            _msgSender(),
            feeReceipient,
            feeAmount
        );
        // (bool feeTransferSuccess, ) = feeReceipient.call{value: feeAmount}("");
        // require(feeTransferSuccess, "HMMarketplace: Fee transfer failed");
        if (
            minters[_nftAddress][_tokenId] != address(0) &&
            royalties[_nftAddress][_tokenId] != uint8(0)
        ) {
            uint256 royaltyFee = _tokenAmount
                .sub(feeAmount)
                .mul(royalties[_nftAddress][_tokenId])
                .div(100);

            listedItem.payToken.safeTransferFrom(
                _msgSender(),
                minters[_nftAddress][_tokenId],
                royaltyFee
            );
            feeAmount = feeAmount.add(royaltyFee);

            // (bool royaltyTransferSuccess, ) = payable(
            //     minters[_nftAddress][_tokenId]
            // ).call{value: royaltyFee}("");
            // require(
            //     royaltyTransferSuccess,
            //     "HMMarketplace: Royalty fee transfer failed"
            // );
        }
        listedItem.payToken.safeTransferFrom(
            _msgSender(),
            _owner,
            _tokenAmount.sub(feeAmount)
        );
        // (bool ownerTransferSuccess, ) = _owner.call{
        //     value: msg.value.sub(feeAmount)
        // }("");
        // require(ownerTransferSuccess, "HMMarketplace: Owner transfer failed");

        // Transfer NFT to buyer
        if (_supportERC721(_nftAddress)) {
            IERC721(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId,
                listedItem.quantity,
                bytes("")
            );
        }
        emit ItemSold(
            _owner,
            _msgSender(),
            address(listedItem.payToken),
            _nftAddress,
            _tokenId,
            listedItem.quantity,
            _tokenAmount.div(listedItem.quantity)
        );
        delete (listings[_nftAddress][_tokenId][_owner]);
    }

    /// @notice Method for offering item
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _payToken Paying token
    /// @param _quantity Quantity of items
    /// @param _pricePerItem Price per item
    /// @param _deadline Offer expiration
    function createOffer(
        address _nftAddress,
        uint256 _tokenId,
        IERC20 _payToken,
        uint256 _quantity,
        uint256 _pricePerItem,
        uint256 _deadline
    ) external {
        require(payTokens[address(_payToken)], "PayToken is not registered");
        require(
            _supportERC721(_nftAddress) || _supportERC1155(_nftAddress),
            "Invalid NFT address."
        );
        require(_deadline > _getNow(), "Invalid expiration");

        offers[_nftAddress][_tokenId][_msgSender()] = Offer(
            _payToken,
            _quantity,
            _pricePerItem,
            _deadline
        );

        emit OfferCreated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            address(_payToken),
            _quantity,
            _pricePerItem,
            _deadline
        );
    }

    /// @notice Method for canceling the offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    function cancelOffer(address _nftAddress, uint256 _tokenId) external {
        delete (offers[_nftAddress][_tokenId][_msgSender()]);
        emit OfferCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    /// @notice Method for accepting the offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _creator Offer creator address
    function acceptOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) external nonReentrant {
        Offer memory offer = offers[_nftAddress][_tokenId][_creator];
        if (_supportERC721(_nftAddress)) {
            IERC721 nft = IERC721(_nftAddress);
            require(
                nft.ownerOf(_tokenId) == _msgSender(),
                "Not owning the item."
            );
        } else if (_supportERC1155(_nftAddress)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(
                nft.balanceOf(_msgSender(), _tokenId) >= offer.quantity,
                "Not owning the item."
            );
        } else {
            revert("Invalid NFT address.");
        }
        require(
            offer.pricePerItem > 0 && offer.quantity > 0,
            "Offer doesn't exist."
        );

        uint256 price = offer.pricePerItem.mul(offer.quantity);
        uint256 feeAmount = price.mul(platformFee).div(1e3);
        uint256 royaltyFee;

        if (
            _nftAddress == hm721 &&
            minters[_nftAddress][_tokenId] != address(0) &&
            royalties[_nftAddress][_tokenId] != uint8(0)
        ) {
            royaltyFee = price
                .sub(feeAmount)
                .mul(royalties[_nftAddress][_tokenId])
                .div(100);
            offer.payToken.safeTransferFrom(
                _creator,
                minters[_nftAddress][_tokenId],
                royaltyFee
            );
            feeAmount = feeAmount.add(royaltyFee);
        }

        offer.payToken.safeTransferFrom(_creator, feeReceipient, feeAmount);
        offer.payToken.safeTransferFrom(
            _creator,
            _msgSender(),
            price.sub(feeAmount)
        );

        // Transfer NFT to buyer
        if (_supportERC721(_nftAddress)) {
            IERC721(_nftAddress).safeTransferFrom(
                _msgSender(),
                _creator,
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                _msgSender(),
                _creator,
                _tokenId,
                offer.quantity,
                bytes("")
            );
        }
        delete (listings[_nftAddress][_tokenId][_msgSender()]);
        delete (offers[_nftAddress][_tokenId][_creator]);

        emit ItemSold(
            _msgSender(),
            _creator,
            address(offer.payToken),
            _nftAddress,
            _tokenId,
            offer.quantity,
            offer.pricePerItem
        );
        emit OfferCanceled(_creator, _nftAddress, _tokenId);
    }

    /// @notice Method for setting royalty
    /// @param _tokenId TokenId
    /// @param _royalty Royalty
    function registerRoyalty(
        address _nftAddress,
        uint256 _tokenId,
        uint8 _royalty
    ) external {
        require(_royalty <= MAX_ROYALTY_FEE, "invalid royalty fee");
        if (_supportERC721(_nftAddress)) {
            require(
                IERC721(hm721).ownerOf(_tokenId) == _msgSender(),
                "Not owning the item."
            );
        } else if (_supportERC1155(_nftAddress)) {
            require(
                IHMNFT1155(_nftAddress).creators(_tokenId) == _msgSender(),
                "Not owning the item."
            );
        } else {
            revert("Invalid NFT address.");
        }

        require(
            minters[_nftAddress][_tokenId] == address(0),
            "Royalty already set"
        );
        minters[_nftAddress][_tokenId] = _msgSender();
        royalties[_nftAddress][_tokenId] = _royalty;
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint256 the platform fee to set
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Update HM721 contract
     @dev Only admin
     */
    function updateHM721(address _hm721) external onlyOwner {
        require(
            IERC165(_hm721).supportsInterface(INTERFACE_ID_ERC721),
            "Not ERC721"
        );
        hm721 = _hm721;
    }

    /**
     @notice Update ListingFee
     @dev Only admin
     */
    function updateListingFee(uint256 _listingFee) external onlyOwner {
        listingFee = _listingFee;
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient)
        external
        onlyOwner
    {
        feeReceipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    /**
     @notice Method for updating platform pay tokens
     @dev Only admin
     @param _payToken address of paytoken update
     */
    function updatePayToken(address _payToken, bool value) external onlyOwner {
        payTokens[_payToken] = value;
        emit UpdatePayToken(_payToken, value);
    }

    ////////////////////////////
    /// Internal and Private ///
    ////////////////////////////

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _cancelListing(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) private {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];
        if (_supportERC721(_nftAddress)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _owner, "Not owning the item.");
        } else if (_supportERC1155(_nftAddress)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(
                nft.balanceOf(_msgSender(), _tokenId) >= listedItem.quantity,
                "Not owning the item."
            );
        } else {
            revert("Invalid NFT address.");
        }

        delete (listings[_nftAddress][_tokenId][_owner]);
        emit ItemCanceled(_owner, _nftAddress, _tokenId);
    }

    function _supportERC721(address _nftAddress) private view returns (bool) {
        return IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721);
    }

    function _supportERC1155(address _nftAddress) private view returns (bool) {
        return IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155);
    }
}
