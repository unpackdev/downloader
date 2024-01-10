// SPDX-License-Identifier: MIT

/**
 * @title bahia nft purchase contract
*/

pragma solidity ^0.8.12;

import "Bahia.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";
import "IERC721.sol";
import "ERC721Holder.sol";


error InsufficientFunds();
error ExceesReimbursementFailed();
error Expired();
error NFTNotApproved();
error NotOwner();
error NotBuyer();
error NotSeller();
error Completed();

contract BahiaNFTPurchase2 is
    Bahia,
    ERC721Holder,
    ReentrancyGuard
{
    // events
    event NFTPurchaseCreated(uint256 expirationTime, address collectionAddress, uint256 nftId, uint256 cost, address buyerAddress, uint256 purchaseId);
    event SetCost(uint256 transactionId, uint256 cost);
    event SetBuyer(uint256 transactionId, address buyerAddress);
    event CompleteTransaction(uint256 transactionId);

    // struct for purchases
    struct Transaction {
        // keep the id of the purchase, acts as a backlink, making it easy on the frontend
        uint256 purchaseId;

        // have an expiration time
        uint256 expirationTime;

        // keep track of the NFT is
        uint256 nftId;

        // keep track of the cost (in gwei)
        uint256 cost;

        // keep track of buyer, seller addresses
        address buyerAddress;
        address sellerAddress;

        // keep track of whether or not this have been completed
        bool completed;

        // keep track of the nft data
        IERC721 nftManager;
    }

    // track all purchases
    Transaction[] public transactions;

    // track each buyer
    mapping(address => uint256[]) public purchases;

    // track each seller
    mapping(address => uint256[]) public sales;

    // backtrack the constructor
    constructor(uint256 devRoyalty_) Bahia(devRoyalty_) {}

    /**
     * @notice a modifier that checks that the calling address is the buyer
     * @param transactionId for indicating which transaction it is
    */
    modifier onlyBuyer(uint256 transactionId)
    {
        if ((msg.sender != transactions[transactionId].buyerAddress) && (transactions[transactionId].buyerAddress != address(0))) revert NotBuyer();
        _;
    }

    /**
     * @notice a modifier that checks that the calling address is the seller
     * @param transactionId for indicating which transaction it is
    */
    modifier onlySeller(uint256 transactionId)
    {
        if (msg.sender != transactions[transactionId].sellerAddress) revert NotSeller();
        _;
    }

    /**
     * @notice a modifier to check transferrability
    */
    modifier transferrable(uint256 transactionId)
    {
        // only allow if it contains NFT, is not expired, and is not completed
        if (isExpired(transactionId)) revert Expired();

        if (transactions[transactionId].nftManager.getApproved(transactions[transactionId].nftId) != address(this)) revert NFTNotApproved();

        if (transactions[transactionId].nftManager.ownerOf(transactions[transactionId].nftId) != transactions[transactionId].sellerAddress) revert NotOwner();

        if (transactions[transactionId].completed) revert Completed();

        _;
    }

    /**
     * @notice a function to create a new transaction
     * @param expirationTime to set when the contract expires
     * @param collectionAddress to determine the nft collection
     * @param nftId to determine which nft is going to be traded
     * @param cost to determine how much to pay for the nft
     * @param buyerAddress to determine the buyer
    */
    function createTransaction(uint256 expirationTime, address collectionAddress, uint256 nftId, uint256 cost, address buyerAddress) external
    {
        // add the new nft purchase to the mapping (use the transactions array length)
        sales[msg.sender].push(transactions.length);

        if ((buyerAddress) != address(0))
        {
            sales[buyerAddress].push(transactions.length);
        }

        // check if the creator is the rightful owner
        IERC721 nftManager = IERC721(collectionAddress);
        if (nftManager.ownerOf(nftId) != msg.sender) revert NotOwner();

        // make a new transaction
        Transaction memory newTransaction = Transaction({
            purchaseId: transactions.length,
            expirationTime: expirationTime,
            nftId: nftId,
            cost: cost,
            buyerAddress: buyerAddress,
            sellerAddress: msg.sender,  // use the message sender as the seller
            completed: false,
            nftManager: nftManager
            });

        // create a new nft purchase
        transactions.push(newTransaction);

        // emit that a contract was created
        emit NFTPurchaseCreated(expirationTime, collectionAddress, nftId, cost, buyerAddress, transactions.length - 1);

    }

    /**
     * @notice count the purchases for frontend iteration
     * @param address_ to locate the address for which we are tracking purchases
    */
    function purchaseCount(address address_) external view returns (uint256)
    {
        return purchases[address_].length;
    }

    /**
     * @notice count the sales for frontend iteration
     * @param address_ to locate the address for which we are tracking sales
    */
    function saleCount(address address_) external view returns (uint256)
    {
        return sales[address_].length;
    }

    /**
     * @notice a function to return the amount of total transactions
    */
    function totalTransactions() external view returns (uint256)
    {
        return transactions.length;
    }

    /**
     * @notice a function to add a sale to the mapping
     * @param buyerAddress for who bought it
     * @param purchaseId for the purchase to be linked
    */
    function addPurchase(address buyerAddress, uint256 purchaseId) internal
    {
        // add the purchase to the buyer's list (in the mapping)
        purchases[buyerAddress].push(purchaseId);
    }

    /**
     * @notice a function to see if the contract is expired
    */
    function isExpired(uint256 transactionId) public view returns (bool)
    {
        return (block.timestamp > transactions[transactionId].expirationTime);
    }

    /**
     * @notice a function for the buyer to receive the nft
    */
    function buy(uint256 transactionId) external payable onlyBuyer(transactionId) nonReentrant
    {
        // cannot be expired  (other iterms will be checked in safe transfer)
        if (isExpired(transactionId)) revert Expired();

        // cannot be completed
        if (transactions[transactionId].completed) revert Completed();

        // now that the nft is transferrable, transfer it out of this wallet (will check other require statements)
        transactions[transactionId].nftManager.safeTransferFrom(transactions[transactionId].sellerAddress, msg.sender, transactions[transactionId].nftId);

        // pay the seller
        _paySeller(transactionId);

        // make sure that the message value exceeds the cost
        _refundExcess(transactionId);

        // log the sender as the buyer address
        transactions[transactionId].buyerAddress = msg.sender;

        // add the purchase to the parent contract
        addPurchase(transactions[transactionId].buyerAddress, transactionId);

        // set completed to true
        transactions[transactionId].completed = true;

        emit CompleteTransaction(transactionId);

    }

    /**
     * @notice a setter function for the cost
     * @param cost_ for the new cost
    */
    function setCost(uint256 transactionId, uint256 cost_) external onlySeller(transactionId) transferrable(transactionId)
    {
        transactions[transactionId].cost = cost_;

        emit SetCost(transactionId, transactions[transactionId].cost);
    }

    /**
     * @notice a setter function for the buyerAddress
     * @param buyerAddress_ for setting the buyer
    */
    function setBuyer(uint256 transactionId, address buyerAddress_) external onlySeller(transactionId) transferrable(transactionId)
    {
        transactions[transactionId].buyerAddress = buyerAddress_;

        emit SetBuyer(transactionId, transactions[transactionId].buyerAddress);
    }

    /**
     * @notice refund the rest of the funds if too many
    */
    function _refundExcess(uint256 transactionId) internal
    {
        // if the msg value is too much, refund it
        if (msg.value > transactions[transactionId].cost)
        {
            // refund the buyer the excess
            (bool sent, ) = transactions[transactionId].buyerAddress.call{value: msg.value - transactions[transactionId].cost}("");
            if (!sent) revert ExceesReimbursementFailed();
        }
    }

    /**
     * @notice a function to pay the seller
    */
    function _paySeller(uint256 transactionId) internal
    {
        uint256 devPayment = transactions[transactionId].cost * devRoyalty / 100000;

        (bool sent, ) = devAddress.call{value: devPayment}("");
        if (!sent) revert InsufficientFunds();

        (bool sent2, ) = transactions[transactionId].sellerAddress.call{value: transactions[transactionId].cost - devPayment}("");
        if (!sent2) revert InsufficientFunds();
    }

}
