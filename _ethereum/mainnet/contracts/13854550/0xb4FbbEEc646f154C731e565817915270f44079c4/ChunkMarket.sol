// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.0 <0.9.0;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/**
 * @dev Contract module which provides access control
 *
 * the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * mapped to
 * `onlyOwner`
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract CryptoChunksMarket is ReentrancyGuard, Pausable, Ownable {
    IERC721 chunksContract; // instance of the CryptoChunks contract

    struct Offer {
        bool isForSale;
        uint256 chunkIndex;
        address seller;
        uint256 minValue; // in ether
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 chunkIndex;
        address bidder;
        uint256 value;
    }

    // A record of chunks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public chunksOfferedForSale;

    // A record of the highest chunk bid
    mapping(uint256 => Bid) public chunkBids;

    // A record of pending ETH withdrawls by address
    mapping(address => uint256) public pendingWithdrawals;

    event ChunkOffered(
        uint256 indexed chunkIndex,
        uint256 minValue,
        address indexed toAddress
    );
    event ChunkBidEntered(
        uint256 indexed chunkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event ChunkBidWithdrawn(
        uint256 indexed chunkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event ChunkBought(
        uint256 indexed chunkIndex,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event ChunkNoLongerForSale(uint256 indexed chunkIndex);

    /* Initializes contract with an instance of CryptoChunks contract, and sets deployer as owner */
    constructor(address initialChunksAddress) {
        IERC721(initialChunksAddress).balanceOf(address(this));
        chunksContract = IERC721(initialChunksAddress);
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    /* Returns the CryptoChunks contract address currently being used */
    function chunksAddress() public view returns (address) {
        return address(chunksContract);
    }

    /* Allows the owner of the contract to set a new CryptoChunks contract address */
    function setChunksContract(address newChunksAddress) public onlyOwner {
        chunksContract = IERC721(newChunksAddress);
    }

    /* Allows the owner of a CryptoChunks to stop offering it for sale */
    function chunkNoLongerForSale(uint256 chunkIndex) public nonReentrant {
        if (chunkIndex >= 10000) revert("token index not valid");
        if (chunksContract.ownerOf(chunkIndex) != msg.sender)
            revert("you are not the owner of this token");
        chunksOfferedForSale[chunkIndex] = Offer(
            false,
            chunkIndex,
            msg.sender,
            0,
            address(0x0)
        );
        emit ChunkNoLongerForSale(chunkIndex);
    }

    /* Allows a CryptoChunk owner to offer it for sale */
    function offerChunkForSale(uint256 chunkIndex, uint256 minSalePriceInWei)
        public
        whenNotPaused
        nonReentrant
    {
        if (chunkIndex >= 10000) revert("token index not valid");
        if (chunksContract.ownerOf(chunkIndex) != msg.sender)
            revert("you are not the owner of this token");
        chunksOfferedForSale[chunkIndex] = Offer(
            true,
            chunkIndex,
            msg.sender,
            minSalePriceInWei,
            address(0x0)
        );
        emit ChunkOffered(chunkIndex, minSalePriceInWei, address(0x0));
    }

    /* Allows a CryptoChunk owner to offer it for sale to a specific address */
    function offerChunkForSaleToAddress(
        uint256 chunkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) public whenNotPaused nonReentrant {
        if (chunkIndex >= 10000) revert();
        if (chunksContract.ownerOf(chunkIndex) != msg.sender)
            revert("you are not the owner of this token");
        chunksOfferedForSale[chunkIndex] = Offer(
            true,
            chunkIndex,
            msg.sender,
            minSalePriceInWei,
            toAddress
        );
        emit ChunkOffered(chunkIndex, minSalePriceInWei, toAddress);
    }

    /* Allows users to buy a CryptoChunk offered for sale */
    function buyChunk(uint256 chunkIndex)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        if (chunkIndex >= 10000) revert("token index not valid");
        Offer memory offer = chunksOfferedForSale[chunkIndex];
        if (!offer.isForSale) revert("chunk is not for sale"); // chunk not actually for sale
        if (offer.onlySellTo != address(0x0) && offer.onlySellTo != msg.sender)
            revert();
        if (msg.value != offer.minValue) revert("not enough ether"); // Didn't send enough ETH
        address seller = offer.seller;
        if (seller == msg.sender) revert("seller == msg.sender");
        if (seller != chunksContract.ownerOf(chunkIndex))
            revert("seller no longer owner of chunk"); // Seller no longer owner of chunk

        chunksOfferedForSale[chunkIndex] = Offer(
            false,
            chunkIndex,
            msg.sender,
            0,
            address(0x0)
        );
        chunksContract.safeTransferFrom(seller, msg.sender, chunkIndex);
        pendingWithdrawals[seller] += msg.value;
        emit ChunkBought(chunkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = chunkBids[chunkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            chunkBids[chunkIndex] = Bid(false, chunkIndex, address(0x0), 0);
        }
    }

    /* Allows users to retrieve ETH from sales */
    function withdraw() public nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /* Allows users to enter bids for any CryptoChunk */
    function enterBidForChunk(uint256 chunkIndex)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        if (chunkIndex >= 10000) revert("token index not valid");
        if (chunksContract.ownerOf(chunkIndex) == msg.sender)
            revert("you already own this chunk");
        if (msg.value == 0) revert("cannot enter bid of zero");
        Bid memory existing = chunkBids[chunkIndex];
        if (msg.value <= existing.value) revert("your bid is too low");
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        chunkBids[chunkIndex] = Bid(true, chunkIndex, msg.sender, msg.value);
        emit ChunkBidEntered(chunkIndex, msg.value, msg.sender);
    }

    /* Allows CryptoChunk owners to accept bids for their Chunks */
    function acceptBidForChunk(uint256 chunkIndex, uint256 minPrice)
        public
        whenNotPaused
        nonReentrant
    {
        if (chunkIndex >= 10000) revert("token index not valid");
        if (chunksContract.ownerOf(chunkIndex) != msg.sender)
            revert("you do not own this token");
        address seller = msg.sender;
        Bid memory bid = chunkBids[chunkIndex];
        if (bid.value == 0) revert("cannot enter bid of zero");
        if (bid.value < minPrice) revert("your bid is too low");

        address bidder = bid.bidder;
        if (seller == bidder) revert("you already own this token");
        chunksOfferedForSale[chunkIndex] = Offer(
            false,
            chunkIndex,
            bidder,
            0,
            address(0x0)
        );
        uint256 amount = bid.value;
        chunkBids[chunkIndex] = Bid(false, chunkIndex, address(0x0), 0);
        chunksContract.safeTransferFrom(msg.sender, bidder, chunkIndex);
        pendingWithdrawals[seller] += amount;
        emit ChunkBought(chunkIndex, bid.value, seller, bidder);
    }

    /* Allows bidders to withdraw their bids */
    function withdrawBidForChunk(uint256 chunkIndex) public nonReentrant {
        if (chunkIndex >= 10000) revert("token index not valid");
        Bid memory bid = chunkBids[chunkIndex];
        if (bid.bidder != msg.sender)
            revert("the bidder is not message sender");
        emit ChunkBidWithdrawn(chunkIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        chunkBids[chunkIndex] = Bid(false, chunkIndex, address(0x0), 0);
        // Refund the bid money
        payable(msg.sender).transfer(amount);
    }
}
