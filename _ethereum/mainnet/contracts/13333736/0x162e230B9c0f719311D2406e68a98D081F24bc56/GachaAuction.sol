// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IERC721.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";

import "./IERC2981.sol";

contract GachaAuction is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    struct Drop {
        address tokenAddress;
        uint256 price;
        uint64 notBefore;
        uint64 deadline;
        uint256[] tokenIds;
    }

    event DropCreated(address indexed seller, uint256 dropId);
    event RoyaltyWithheld(address royaltyRecipient, uint256 royaltyAmount);
    event Sale(uint256 indexed dropId, uint256 tokenId, address buyer);

    Counters.Counter private _dropIdCounter;
    mapping(uint256 => Drop) private drops;
    mapping(uint256 => address) public dropSellers;

    uint256 private _auctionFeeBps;

    constructor(uint256 auctionFeeBps_) Ownable() Pausable() ReentrancyGuard() {
        _auctionFeeBps = auctionFeeBps_;
    }

    /// @notice Given a drop struct, kicks off a new drop
    function setup(Drop calldata drop_) external whenNotPaused returns (uint256) {
        uint256 dropId = _dropIdCounter.current();
        drops[dropId] = drop_;
        dropSellers[dropId] = msg.sender;
        emit DropCreated(msg.sender, dropId);

        _dropIdCounter.increment();
        return dropId;
    }

    /// @notice Returns the next drop ID
    function nextDropId() public view returns (uint256) {
        return _dropIdCounter.current();
    }

    function peek(uint256 dropId) public view returns (Drop memory) {
        return drops[dropId];
    }

    /// @notice Buyer's interface, delivers to the caller
    function buy(uint256 dropId_) external payable whenNotPaused nonReentrant {
        _buy(dropId_, msg.sender);
    }

    /// @notice Buyer's interface, delivers to a specified address
    function buy(uint256 dropId_, address deliverTo_) external payable whenNotPaused nonReentrant {
        _buy(dropId_, deliverTo_);
    }

    function _buy(uint256 dropId_, address deliverTo_) private {
        // CHECKS
        Drop storage drop = drops[dropId_];

        require(drop.tokenAddress != address(0), "gacha: not found");
        require(drop.tokenIds.length > 0, "gacha: sold out");
        require(drop.notBefore <= block.timestamp, "gacha: auction not yet started");
        require(drop.deadline == 0 || drop.deadline >= block.timestamp, "gacha: auction already ended");

        require(msg.value == drop.price, "gacha: incorrect amount sent");

        // EFFECTS
        // Select token at (semi-)random
        uint256 tokenIdx = uint256(keccak256(abi.encodePacked(block.timestamp))) % drop.tokenIds.length;
        uint256 tokenId = drop.tokenIds[tokenIdx];

        // Remove the token from the drop tokens list
        drop.tokenIds[tokenIdx] = drop.tokenIds[drop.tokenIds.length - 1];
        drop.tokenIds.pop();

        (, address royaltyReceiver, uint256 royaltyAmount, uint256 sellerShare) = _getProceedsDistribution(
            dropSellers[dropId_],
            drop.tokenAddress,
            tokenId,
            drop.price
        );

        emit Sale(dropId_, tokenId, msg.sender);
        if (royaltyReceiver != address(0) && royaltyAmount > 0) {
            emit RoyaltyWithheld(royaltyReceiver, royaltyAmount);
        }

        // INTERACTIONS
        // Transfer the token and ensure delivery of the token
        IERC721(drop.tokenAddress).safeTransferFrom(dropSellers[dropId_], deliverTo_, tokenId);
        require(IERC721(drop.tokenAddress).ownerOf(tokenId) == deliverTo_, "gacha: token transfer failed"); // ensure delivery

        // Ensure delivery of the payment
        // solhint-disable-next-line avoid-low-level-calls
        (bool paymentSent, ) = dropSellers[dropId_].call{value: sellerShare}("");
        require(paymentSent, "gacha: seller payment failed");

        // Clean up the drop after all items have been sold
        if (drop.tokenIds.length == 0) {
            delete drops[dropId_];
        }
    }

    function _getProceedsDistribution(
        address seller_,
        address tokenAddress_,
        uint256 tokenId_,
        uint256 price_
    )
        private
        view
        returns (
            uint256 auctionFeeAmount,
            address royaltyReceiver,
            uint256 royaltyAmount,
            uint256 sellerShare
        )
    {
        // Auction fee
        auctionFeeAmount = (price_ * _auctionFeeBps) / 10000;

        // EIP-2981 royalty split
        (royaltyReceiver, royaltyAmount) = _getRoyaltyInfo(tokenAddress_, tokenId_, price_ - auctionFeeAmount);
        // No royalty address, or royalty goes to the seller
        if (royaltyReceiver == address(0) || royaltyReceiver == seller_) {
            royaltyAmount = 0;
        }

        // Seller's share
        sellerShare = price_ - (auctionFeeAmount + royaltyAmount);

        // Internal consistency check
        assert(sellerShare + auctionFeeAmount + royaltyAmount <= price_);
    }

    function _getRoyaltyInfo(
        address tokenAddress_,
        uint256 tokenId_,
        uint256 price_
    ) private view returns (address, uint256) {
        try IERC2981(tokenAddress_).royaltyInfo(tokenId_, price_) returns (
            address royaltyReceiver,
            uint256 royaltyAmount
        ) {
            return (royaltyReceiver, royaltyAmount);
        } catch (bytes memory reason) {
            // EIP 2981's `royaltyInfo()` function is not implemented
            // treatment the same as here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.1/contracts/token/ERC721/ERC721.sol#L379
            if (reason.length == 0) {
                return (address(0), 0);
            } else {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /// @dev Auction fee setters and getters
    function auctionFeeBps() public view returns (uint256) {
        return _auctionFeeBps;
    }

    function setAuctionFeeBps(uint256 newAuctionFeeBps_) public onlyOwner {
        _auctionFeeBps = newAuctionFeeBps_;
    }

    /// @dev Auction fee & withheld royalty withdrawal
    function withdraw(address payable account_, uint256 amount_) public nonReentrant onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool paymentSent, ) = account_.call{value: amount_}("");
        require(paymentSent, "FixedPriceAuction: withdrawal failed");
    }

    /// @dev The following functions relate to pausing of the contract
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
