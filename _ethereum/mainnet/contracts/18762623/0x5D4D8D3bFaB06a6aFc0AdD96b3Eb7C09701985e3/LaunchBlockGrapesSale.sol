// SPDX-License-Identifier: UNLICENSED
// Developed by Liteflow.com
pragma solidity 0.8.20;

import "./Ownable.sol";
import "./MerkleProof.sol";

contract LaunchBlockGrapesSale is Ownable {
    /// @notice Start date of the sale in timestamp
    /// @dev Set in the constructor
    uint256 public immutable startDate;

    /// @notice End date of the sale in timestamp
    /// @dev Set in the constructor
    uint256 public immutable endDate;

    /// @notice Price of one ticket in wei
    /// @dev Set in the constructor
    uint256 public immutable ticketPrice;

    /// @notice Max number of tickets that can be bought per buyer
    /// @dev Set in the constructor
    uint256 public immutable maxTicketsPerBuyer;

    /// @notice Number of tickets bought by each buyer
    /// @dev Managed internally by contract
    mapping(address buyer => uint256) public balances;

    /// @notice Number of tickets refunded for each buyer
    /// @dev Managed internally by contract
    mapping(address buyer => uint256) public refunds;

    /// @notice Refund Merkle root
    bytes32 public refundMerkleRoot;

    /// @notice Emitted when a ticket is bought
    // event TicketBought(address indexed wallet, uint256[] ticketIds);
    event TicketsBought(address indexed wallet, uint256 count);

    /// @notice Emitted when a ticket is refunded
    event TicketsRefunded(address indexed wallet, uint256 count);

    /// @notice Returned when the sale is not started or ended
    error SaleClosed();

    /// @notice Returned when the amount of ETH sent is not equal to the ticket price multiplied by the number of tickets to buy
    error InvalidAmount();

    /// @notice Returned when the number of tickets to buy is greater than the max allowed
    error TicketLimitReached();

    /// @notice Returned when the refund function is not open
    error RefundClosed();

    /// @notice Returned when ticket is already refunded
    error AlreadyRefunded();

    /// @notice Returned when the merkle proof is invalid
    error InvalidMerkleProof();

    /// @notice Returned when the refund transfer fails
    error RefundFailed();

    /// @notice Returned when the sale is not ended
    error SaleNotClosed();

    /// @notice Returned when refund merkle root is already set
    error RefundMerkleRootAlreadySet();

    /// @notice Returned when the withdraw all transfer fails
    error WithdrawFailed();

    /// @notice Returned when it's too early to execute withdraw all
    error WithdrawAllNotEligible();

    /// @notice Returned when the withdraw all ETH fails
    error WithdrawAllFailed();

    /// @notice Initializes the contract
    /// @param initialOwner_ The address of the initial owner of the contract
    /// @param ticketPrice_ The price of one ticket in wei
    /// @param maxTicketsPerBuyer_ Max number of tickets that can be bought per buyer
    /// @param startDate_ Start date of the sale in timestamp
    /// @param endDate_ End date of the sale in timestamp
    constructor(
        address initialOwner_,
        uint256 ticketPrice_,
        uint256 maxTicketsPerBuyer_,
        uint256 startDate_,
        uint256 endDate_
    ) Ownable(initialOwner_) {
        ticketPrice = ticketPrice_;
        maxTicketsPerBuyer = maxTicketsPerBuyer_;
        startDate = startDate_;
        endDate = endDate_;
    }

    /// @notice Buy tickets
    /// @param numberOfTickets_ The number of tickets to buy
    function buyTickets(uint256 numberOfTickets_) external payable {
        // check if the sale is closed
        if (block.timestamp < startDate || block.timestamp > endDate) {
            revert SaleClosed();
        }

        // check amount provided is correct
        if (msg.value != ticketPrice * numberOfTickets_) revert InvalidAmount();

        // calculate the number of tickets bought by the sender
        uint256 balance = balances[msg.sender] + numberOfTickets_;

        // check that the number of tickets is not greater than the max allowed
        if (balance > maxTicketsPerBuyer) revert TicketLimitReached();

        // update ticket balance of buyer
        balances[msg.sender] = balance;

        // emit event
        emit TicketsBought(msg.sender, numberOfTickets_);
    }

    /// @notice Refund tickets
    /// @param ticketsToRefund_ The number of the tickets to refund
    /// @param merkleProof_ The merkle proof of the tickets to refund
    function refundTickets(
        uint256 ticketsToRefund_,
        bytes32[] calldata merkleProof_
    ) external {
        // check refund is activated
        if (refundMerkleRoot == bytes32(0)) revert RefundClosed();

        // check sender was not already refunded
        if (refunds[msg.sender] > 0) revert AlreadyRefunded();

        // check that the merkle proof is valid
        if (
            !MerkleProof.verifyCalldata(
                merkleProof_,
                refundMerkleRoot,
                keccak256(
                    bytes.concat(
                        keccak256(abi.encode(msg.sender, ticketsToRefund_))
                    )
                )
            )
        ) revert InvalidMerkleProof();

        // mark the sender as refunded
        refunds[msg.sender] = ticketsToRefund_;

        // emit event
        emit TicketsRefunded(msg.sender, ticketsToRefund_);

        // do the refund transfer
        (bool sent, ) = msg.sender.call{value: ticketsToRefund_ * ticketPrice}(
            ''
        );
        if (!sent) revert RefundFailed();
    }

    /// @notice Set the refund merkle root and withdraw ETH of the winning tickets. Only owner can execute this function
    /// @param refundMerkleRoot_ The refund merkle root
    /// @param numberOfWinningTickets_ The number of winning tickets
    /// @param to_ The address to send the ETH to
    function finalizeSale(
        bytes32 refundMerkleRoot_,
        uint256 numberOfWinningTickets_,
        address payable to_
    ) external onlyOwner {
        // check if the sale is closed
        if (block.timestamp <= endDate) {
            revert SaleNotClosed();
        }

        // prevent setting the Merkle root if already set
        if (refundMerkleRoot != bytes32(0)) revert RefundMerkleRootAlreadySet();

        // set the merkle root
        refundMerkleRoot = refundMerkleRoot_;

        // transfer amount corresponding to the winning tickets
        (bool sent, ) = to_.call{value: numberOfWinningTickets_ * ticketPrice}(
            ''
        );
        if (!sent) revert WithdrawFailed();
    }

    /// @notice Withdraw all ETH from the contract. Only owner can execute this function.
    /// @param to_ The address to send the ETH to.
    function withdrawAll(address payable to_) external onlyOwner {
        // check the sale is closed for at least 3 days
        if (block.timestamp <= endDate + 3 days) {
            revert WithdrawAllNotEligible();
        }

        (bool sent, ) = to_.call{value: address(this).balance}('');
        if (!sent) revert WithdrawAllFailed();
    }
}
