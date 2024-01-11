// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";

contract Auction is Ownable, ReentrancyGuard, ERC721Holder, ERC1155Holder,AccessControl {
    using SafeERC20 for IERC20;

    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant EXTENDING_AUCTION = 600;

    uint256 public fee = 250;

    address public payee;

    struct Collectible {
        address seller;
        address collection;
        uint256 tokenId;
        uint256 amount;
        address currency;
        uint256 price;
        uint256 opening;
        uint256 finish;
    }

    mapping(bytes32 => Collectible) public collectibles;
    mapping(address => mapping(uint256 => bool)) public allowTokens;

    mapping(bytes32 => address[]) public bidders;
    mapping(bytes32 => mapping(address => uint256)) public bids;

    event WhitelistedTokensAdded(address indexed collection, uint256[] tokenIds);
    event WhitelistedTokenRemoved(address indexed collection,uint256 tokenId);

    event FeeUpdated(uint256 previousFee, uint256 newFee);
    event PayeeUpdated(address previousPayee, address newPayee);

    event CollectibleAdded(bytes32 collectibleHash, address indexed seller, address indexed collection, uint256 tokenId, uint256 amount, address currency, uint256 price, uint256 opening, uint256 finish);
    event CollectibleRemoved(bytes32 collectibleHash);

    event Bided(bytes32 collectibleHash, address bidder, uint256 price,uint256 finish);
    event Withdrawn(bytes32 collectibleHash, address bidder, uint256 price);

    event Purchased(bytes32 collectibleHash, address indexed purchaser, address indexed collection, uint256 tokenId, uint256 amount);

    modifier onlyWhitelisted(address collection,uint256 tokenId) {
        require(allowTokens[collection][tokenId], "Collection or tokenId is not whitelisted");
        _;
    }

    constructor(address payable payee_) {
        require(payee_ != address(0), "Payee cannot be zero address");
        payee = payee_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function setFee(uint256 newFee) external onlyOwner {
        require(newFee < FEE_DENOMINATOR, "Invalid value");
        uint256 previousFee = fee;
        fee = newFee;
        emit FeeUpdated(previousFee, newFee);
    }

    function setPayee(address payable newPayee) external onlyOwner {
        require(newPayee != address(0), "Payee cannot be zero address");
        address previousPayee = payee;
        payee = newPayee;
        emit PayeeUpdated(previousPayee, newPayee);
    }

    function addWhiteListedTokens(address collection, uint256[] calldata tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) || IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155),
            "Invalid collection contract address"
        );

        for(uint256 i = 0; i < tokenIds.length; i ++) {
            allowTokens[collection][tokenIds[i]] = true;
        }

        emit WhitelistedTokensAdded(collection,tokenIds);
    }

    function removeWhitelistedToken(address collection, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) onlyWhitelisted(collection,tokenId){
        delete allowTokens[collection][tokenId];
        emit WhitelistedTokenRemoved(collection,tokenId);
    }

    function addCollectible(address collection, uint256 tokenId, uint256 amount, address currency, uint256 price, uint256 opening, uint256 finish) external nonReentrant onlyWhitelisted(collection,tokenId){
        require(IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) || IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155), "Not ERC721/ERC1155");
        require(opening > block.timestamp, "Opening time must be greater than current time");
        require(opening < finish, "Opening time must be less than finish time");

        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            amount = 1;
        }

        bytes32 collectibleHash = keccak256(abi.encodePacked(_msgSender(), collection, tokenId, block.number));

        Collectible storage collectible = collectibles[collectibleHash];
        collectible.seller = _msgSender();
        collectible.collection = collection;
        collectible.tokenId = tokenId;
        collectible.amount = amount;
        collectible.currency = currency;
        collectible.price = price;
        collectible.opening = opening;
        collectible.finish = finish;

        _executeCollectibleTransferFrom(collection, _msgSender(), address(this), tokenId, amount);

        emit CollectibleAdded(collectibleHash, _msgSender(), collection, tokenId, amount, currency, price, opening, finish);
    }

    function removeCollectible(bytes32 collectibleHash) external nonReentrant {
        Collectible memory collectible = collectibles[collectibleHash];
        require(collectible.seller == _msgSender(), "Caller must be the seller of this collectible");
        require(bidders[collectibleHash].length == 0, "Can't remove collectible that already have bidders");

        delete collectibles[collectibleHash];

        _executeCollectibleTransferFrom(collectible.collection, address(this), _msgSender(), collectible.tokenId, collectible.amount);

        emit CollectibleRemoved(collectibleHash);
    }

    function bid(bytes32 collectibleHash, uint256 price) payable external nonReentrant {
        require(tx.origin == _msgSender(), "Invalid caller");

        Collectible storage collectible = collectibles[collectibleHash];
        require(collectible.seller != address(0), "Invalid collectible");

        require(block.timestamp > collectible.opening, "Auction has not started");
        require(block.timestamp < collectible.finish, "Auction has ended");

        if (collectible.finish - block.timestamp < EXTENDING_AUCTION) {
            collectible.finish += EXTENDING_AUCTION;
        }

        address lastBidder = _msgSender();
        if(bidders[collectibleHash].length > 0) {
            lastBidder = bidders[collectibleHash][bidders[collectibleHash].length - 1];
        }

        uint256 highestBid = bids[collectibleHash][lastBidder];
        uint256 finishPrice = collectible.amount * collectible.price;
        if (highestBid < finishPrice) {
            highestBid = finishPrice;
        }
        require(price > highestBid, "Below highest bid");

        uint256 paymentAmount = bids[collectibleHash][lastBidder];
        price -= paymentAmount;

        if (collectible.currency == address(0)) {
            require(msg.value >= price, "Insufficient payment");
            _executeFundsTransfer(collectible.currency, lastBidder, paymentAmount);
        } else {
            IERC20(collectible.currency).safeTransferFrom(_msgSender(), address(this), price);
            IERC20(collectible.currency).safeTransferFrom(_msgSender(), lastBidder, paymentAmount);
        }

        if (paymentAmount > 0){
            emit Withdrawn(collectibleHash, lastBidder, paymentAmount);
        }

        bidders[collectibleHash].push(_msgSender());

        bids[collectibleHash][_msgSender()] = price + paymentAmount;

        emit Bided(collectibleHash, _msgSender(), price + paymentAmount,collectible.finish);
    }

    function withdraw(bytes32 collectibleHash) payable external nonReentrant {
        Collectible memory collectible = collectibles[collectibleHash];
        require(block.timestamp > collectible.finish, "Auction is not over yet");

        uint256 paymentAmount = bids[collectibleHash][_msgSender()];
        bids[collectibleHash][_msgSender()] = 0;

        address lastBidder = bidders[collectibleHash][bidders[collectibleHash].length - 1];
        require(lastBidder == _msgSender(),"You didn't bid successfully");

        delete collectibles[collectibleHash];

        uint256 feeAmount = paymentAmount * fee / FEE_DENOMINATOR;
        _executeFundsTransfer(collectible.currency, payee, feeAmount);
        _executeFundsTransfer(collectible.currency, collectible.seller, paymentAmount - feeAmount);

        _executeCollectibleTransferFrom(collectible.collection, address(this), _msgSender(), collectible.tokenId, collectible.amount);
        emit Purchased(collectibleHash, _msgSender(), collectible.collection, collectible.tokenId, collectible.amount);
    }

    function _executeCollectibleTransferFrom(address collection, address from, address to, uint256 tokenId, uint256 amount) private {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(collection).safeTransferFrom(from, to, tokenId, "");
        } else {
            IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, "");
        }
    }

    function _executeFundsTransfer(address currency, address to, uint256 amount) private {
        if (currency == address(0)) {
            Address.sendValue(payable(to), amount);
        } else {
            IERC20(currency).safeTransfer(to, amount);
        }
    }
}
