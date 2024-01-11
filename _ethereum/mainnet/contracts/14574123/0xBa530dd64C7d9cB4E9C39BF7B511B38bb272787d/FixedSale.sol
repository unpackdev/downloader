// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC165.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";

contract FixedSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    /// @notice Events for the contract
    event BatchItemsListed(
        address indexed owner,
        address indexed nft,
        uint256[] tokenIds,
        uint256[] quantities,
        uint256[] prices,
        uint256 startingTime,
        bool isPrivate,
        address allowedAddress
    );
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

    /// @notice Structure for listed items
    struct Listing {
        uint256 quantity;
        uint256 pricePerItem;
        uint256 startingTime;
        address allowedAddress;
    }

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// @notice NftAddress -> Token ID -> Owner -> Listing item
    mapping(address => mapping(uint256 => mapping(address => Listing))) public listings;


    /// @notice Contract constructor
    constructor() public {
    }

    /// @notice Method for listing all items in a NFT
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenIds Token Start ID of NFT
    /// @param _quantities token amount to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
    /// @param _prices sale price for each iteam
    /// @param _startingTime scheduling for a future sale
    /// @param _allowedAddress optional param for private sale
    function batchListItems(
        address _nftAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _quantities,
        uint256[] calldata _prices,
        uint256 _startingTime,
        address _allowedAddress
    ) external {
        require(_tokenIds.length > 0, "No token IDs");
        require(_quantities.length == 1 || _quantities.length == _tokenIds.length, "Mismatching quantities");
        require(_prices.length == 1 || _prices.length == _prices.length, "Mismatching prices");

        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.isApprovedForAll(_msgSender(), address(this)), "Must be approved before list.");
        }
        else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(nft.isApprovedForAll(_msgSender(), address(this)), "Must be approved before list.");
        }
        else {
            revert("Invalid NFT address.");
        }

        for(uint256 i=0; i<_tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
                IERC721 nft = IERC721(_nftAddress);
                require(nft.ownerOf(_tokenId) == _msgSender(), "Must be owner of NFT.");
            }
            else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
                IERC1155 nft = IERC1155(_nftAddress);
                uint256 quantity = i < _quantities.length ? _quantities[i] : _quantities[0];
                require(nft.balanceOf(_msgSender(), _tokenId) >= quantity, "Must hold enough NFTs.");
            }
        }
        
        for(uint256 i=0; i<_tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            listings[_nftAddress][_tokenId][_msgSender()] = Listing(
                i < _quantities.length ? _quantities[i] : _quantities[0],
                i < _prices.length ? _prices[i] : _prices[0],
                _startingTime,
                _allowedAddress
            );
        }
        emit BatchItemsListed(
            _msgSender(),
            _nftAddress,
            _tokenIds,
            _quantities,
            _prices,
            _startingTime,
            _allowedAddress == address(0x0),
            _allowedAddress
        );
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
        uint256 _quantity,
        uint256 _pricePerItem,
        uint256 _startingTime,
        address _allowedAddress
    ) external {
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _msgSender(), "Must be owner of NFT.");
            require(nft.isApprovedForAll(_msgSender(), address(this)), "Must be approved before list.");
        }
        else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(nft.balanceOf(_msgSender(), _tokenId) >= _quantity, "Must hold enough NFTs.");
            require(nft.isApprovedForAll(_msgSender(), address(this)), "Must be approved before list.");
        }
        else {
            revert("Invalid NFT address.");
        }

        listings[_nftAddress][_tokenId][_msgSender()] = Listing(
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
    function cancelListing(
        address _nftAddress,
        uint256 _tokenId
    ) external nonReentrant {
        require(listings[_nftAddress][_tokenId][_msgSender()].quantity > 0, "Not listed item.");
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
        Listing storage listedItem = listings[_nftAddress][_tokenId][_msgSender()];
        require(listedItem.quantity > 0, "Not listed item.");
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _msgSender(), "Not owning the item.");
        }
        else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(nft.balanceOf(_msgSender(), _tokenId) >= listedItem.quantity, "Not owning the item.");
        }
        else {
            revert("Invalid NFT address.");
        }

        listedItem.pricePerItem = _newPrice;
        emit ItemUpdated(_msgSender(), _nftAddress, _tokenId, _newPrice);
    }

    /// @notice Method for buying listed NFT
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _owner Token Owner
    /// @param _quantity Quantity to buy
    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address payable _owner,
        uint256 _quantity
    ) external payable nonReentrant {
        _buyItem(_nftAddress, _tokenId, _owner, _quantity);
    }

    /// @notice Method for buying listed NFT
    /// @param _nftAddresses List of NFT contract address
    /// @param _tokenIds List of TokenId
    /// @param _owners List of Token Owners
    /// @param _quantities List of Quantities
    function batchBuyItems(
        address[] calldata _nftAddresses,
        uint256[] calldata _tokenIds,
        address payable[] calldata _owners,
        uint256[] calldata _quantities
    ) external payable nonReentrant {
        require(_nftAddresses.length > 0, "No Address");
        require(_tokenIds.length == _nftAddresses.length, "Mismatching token IDs");
        require(_owners.length == _nftAddresses.length, "Mismatching owners");
        require(_quantities.length == _nftAddresses.length, "Mismatching quantities");

        for(uint256 i=0; i<_nftAddresses.length; i++) {
            _buyItem(_nftAddresses[i], _tokenIds[i], _owners[i], _quantities[i]);
        }
    }

    /// @notice Internal method for buying listed NFT
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _owner Token Owner
    /// @param _quantity Quantity to buy
    function _buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address payable _owner,
        uint256 _quantity
    ) internal {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];
        require(listedItem.quantity > 0, "Not listed item.");
        require(listedItem.quantity >= _quantity, "Not enough on sale.");
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _owner, "Not owning the item.");
        }
        else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(nft.balanceOf(_owner, _tokenId) >= listedItem.quantity, "Not owning the item.");
        }
        else {
            revert("Invalid NFT address.");
        }
        require(_getNow() >= listedItem.startingTime, "Item is not buyable yet.");
        require(msg.value >= listedItem.pricePerItem.mul(_quantity), "Not enough amount to buy item.");
        if (listedItem.allowedAddress != address(0)) {
            require(listedItem.allowedAddress == _msgSender(), "You are not eligable to buy item.");
        }

        (bool ownerTransferSuccess,) = _owner.call{value : listedItem.pricePerItem.mul(_quantity)}("");
        require(ownerTransferSuccess, "FixedSale: Owner transfer failed");

        // Transfer NFT to buyer
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(_owner, _msgSender(), _tokenId);
        } else {
            IERC1155(_nftAddress).safeTransferFrom(_owner, _msgSender(), _tokenId, _quantity, bytes(""));
        }
        emit ItemSold(_owner, _msgSender(), _nftAddress, _tokenId, listedItem.quantity, msg.value.div(listedItem.quantity));
        if (listedItem.quantity > _quantity) {
            listings[_nftAddress][_tokenId][_owner].quantity = listedItem.quantity - _quantity;
        } else {
            delete(listings[_nftAddress][_tokenId][_owner]);
        }
    }
    
    ////////////////////////////
    /// Internal and Private ///
    ////////////////////////////

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /// @dev Reset approval and approve exact amount
    function _approveHelper(
        IERC20 token,
        address recipient,
        uint256 amount
    ) internal {
        token.safeApprove(recipient, 0);
        token.safeApprove(recipient, amount);
    }

    function _cancelListing(address _nftAddress, uint256 _tokenId, address _owner) private {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _owner, "Not owning the item.");
        }
        else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(nft.balanceOf(_msgSender(), _tokenId) >= listedItem.quantity, "Not owning the item.");
        }
        else {
            revert("Invalid NFT address.");
        }

        delete(listings[_nftAddress][_tokenId][_owner]);
        emit ItemCanceled(_owner, _nftAddress, _tokenId);
    }
}