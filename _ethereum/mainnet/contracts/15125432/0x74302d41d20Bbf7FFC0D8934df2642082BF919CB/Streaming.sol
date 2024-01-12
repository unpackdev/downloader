// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Payments Stream - A contract that allows users to stream Ether to another account.
/// @author Gates Porter
/// @notice You can use this contract to 1) create a stream, 2) check a stream balance, 3) get data about a particular stream, 4) withdraw funds from a stream, 5) cancel a stream
contract Streaming {
    /**
     * @dev left owner public so that it could be used in Streaming.spec.js, otherwise would have made it private to save gas.
     * made it immutable to save gas, since it is set once in the constructor and then never needs to be altered.
     */
    address public immutable owner;

    /// @dev this didn't need to be public, save gas by making it private.
    uint256 private streamIdCounter;

    mapping(uint256 => Stream) private streams;

    /// @dev this check has been placed in a modifier since it is used 2+ times
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].deposit > 0, "stream does not exist");
        _;
    }

    /**
     * @dev the startTime has been split into two different fields originalStartTime and currentStartTime
     * originalStartTime is the startTime that is passed into createStream.
     * It is saved so that a user/contract can easily see the original start time of a stream. Good to have in case some future update needs it for calculation on chain.
     *
     * currentStartTime is originally set to the startTime passed into createStream.
     * Every time a withdrawal occurs, it is set to block.timestamp so that we can keep track of the funds that are due to the recipient.
     */
    struct Stream {
        address recipient;
        address sender;
        uint256 deposit;
        uint256 currentStartTime;
        uint256 stopTime;
        uint256 rate;
        uint256 balance;
        uint256 originalStartTime;
    }

    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        uint256 startTime,
        uint256 stopTime
    );

    event WithdrawFromStream(
        uint256 indexed streamId,
        address indexed recipient
    );

    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderFunds,
        uint256 recipientFunds
    );

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Creates a stream.
     * @dev Main changes:
     * 1) added a check to ensure that startTime is less than stopTime
     * 2) got rid of the deposit param, instead just looks at the msg.value - security fix. Before this a user could pass in a deposit param that didnt match the actual ether sent.
     * 3) made this function external to save gas, since it is never used inside this contract.
     */
    function createStream(
        address recipient,
        uint256 startTime,
        uint256 stopTime
    ) external payable returns (uint256) {
        require(recipient != address(0), "Stream to the zero address");
        require(recipient != address(this), "Stream to the contract itself");
        require(recipient != msg.sender, "Stream to the caller");
        require(msg.value > 0, "Deposit is equal to zero");
        require(
            startTime >= block.timestamp,
            "Start time before block timestamp"
        );
        require(
            startTime < stopTime,
            "Stop time is not greater than than start time"
        );

        uint256 duration = stopTime - startTime;

        require(msg.value >= duration, "Deposit smaller than duration");
        require(
            msg.value % duration == 0,
            "Deposit is not a multiple of time delta"
        );

        uint256 currentStreamId = ++streamIdCounter;

        // Rate Per second
        uint256 rate = msg.value / duration;

        streams[currentStreamId] = Stream({
            balance: msg.value,
            deposit: msg.value,
            rate: rate,
            recipient: recipient,
            sender: msg.sender,
            currentStartTime: startTime,
            stopTime: stopTime,
            originalStartTime: startTime
        });

        emit CreateStream(
            currentStreamId,
            msg.sender,
            recipient,
            msg.value,
            startTime,
            stopTime
        );

        return currentStreamId;
    }

    /**
     * @notice Returns the "balance" to the caller. Different from the balance field on the stream - returns the amount due if the recipeint calls, returns the balance field - amount due if the sender calls.
     * @dev Main changes:
     * 1) added a check to ensure that the stream exists (via modifier)
     * 2) added a check to ensure that msg.sender is the sender or recipient - as per requirements section in README.md
     * 3) got rid of "who" param and associated logic - we should be looking at the actual msg.sender, and erroring if the msg.sender isn't the recipient or the sender.
     * 4) made this function external to save gas, since it is never used inside this contract.
     */
    function balanceOf(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (uint256 balance)
    {
        Stream memory stream = streams[streamId];

        require(
            msg.sender == stream.sender || msg.sender == stream.recipient,
            "caller is not the sender or the recipient of the stream"
        );

        uint256 due = elapsedTimeFor(streamId) * stream.rate;

        if (msg.sender == stream.recipient) {
            return due;
        } else {
            return stream.balance - due;
        }
    }

    /**
     * @dev Main changes:
     * 1) use currentStartTime instead of startTime in the appropriate places
     */
    function elapsedTimeFor(uint256 streamId)
        private
        view
        returns (uint256 delta)
    {
        Stream memory stream = streams[streamId];

        // Before the start of the stream
        if (block.timestamp <= stream.originalStartTime) return 0;

        // During the stream
        if (block.timestamp < stream.stopTime)
            return block.timestamp - stream.currentStartTime;

        // After the end of the stream
        return stream.stopTime - stream.currentStartTime;
    }

    /**
     * @notice Allows a recipient to withdraw the funds due up until block.timestamp.
     * @dev Main changes:
     * 1) added a check to ensure that the stream exists (via modifier)
     * 2) got rid of the SenderOrRecipient modifer (its only used on two of the functions) and its use here - the requierements in README.md say only the recipient should be the msg.sender here. Added a check for that.
     * 3) got rid of call to balanceOf since we don't need the sender half of its logic - instead pulled the necessary logic from balanceOf into this function. Saves gas.
     * 4) got rid of unecessary streams[streamId] storage reads. Reads can be done from memory. For storage writes, use storage stream variable instead of querying the mapping over and over.
     * 5) Implemented the checks/effects/interaction pattern to prevent re-entrancy.
     * 6) There was a logic error in setting the balance to 0. Set stream balance to balance - due, and then set the currentStartTime to the block.timestamp to keep track of the next amount due.
     * 7) made this function external to save gas, since it is never used inside this contract.
     * 8) added a check that throws an error if ether transfer to the recipient fails. Would fail silently before.
     */
    function withdrawFromStream(uint256 streamId)
        external
        streamExists(streamId)
    {
        Stream memory streamCopy = streams[streamId];

        require(
            streamCopy.recipient == msg.sender,
            "only the recipient can call this method"
        );

        Stream storage stream = streams[streamId];

        uint256 due = elapsedTimeFor(streamId) * streamCopy.rate;

        require(due > 0, "Available balance is 0");
        stream.balance = streamCopy.balance - due;
        stream.currentStartTime = block.timestamp;

        emit WithdrawFromStream(streamId, streamCopy.recipient);

        (bool success, ) = payable(streamCopy.recipient).call{value: due}("");
        require(success, "Transfer to recipient failed!");
    }

    /**
     * @notice Allows the sender or recipient of a stream to cancel the stream, and return the vested amount until that time to recipient and the remaining to sender.
     * @dev This is external, since it is never called inside this contract. We check that the stream exists, and then check that msg.sender is the sender or the recipient - as per README.md.
     * Calculates recipientFunds, and senderFunds using elapsedTimeFor and the rate.
     * Sets the stream balance to 0, and the currentStartTime to end time to indicate stream is no longer active.
     * Emits a CancelStream event.
     * Implements the check/effects/interactions pattern to prevent re-entrancy.
     * I didn't do this - but you could add a cancelled boolean field to the stream struct if you wanted to 1) see which streams were cancelled vs completed via sufficient withdrawals without looking at events and 2) exit early from methods if the stream is cancelled.
     */
    function cancelStream(uint256 streamId) external streamExists(streamId) {
        Stream memory streamCopy = streams[streamId];

        require(
            msg.sender == streamCopy.sender ||
                msg.sender == streamCopy.recipient,
            "caller is not the sender or the recipient of the stream"
        );

        Stream storage stream = streams[streamId];

        uint256 recipientFunds = elapsedTimeFor(streamId) * streamCopy.rate;
        uint256 senderFunds = streamCopy.balance - recipientFunds;

        stream.balance = 0;
        stream.currentStartTime = streamCopy.stopTime;

        emit CancelStream(
            streamId,
            streamCopy.sender,
            streamCopy.recipient,
            senderFunds,
            recipientFunds
        );

        if (senderFunds > 0) {
            (bool senderSendSuccess, ) = payable(streamCopy.sender).call{
                value: senderFunds
            }("");
            require(senderSendSuccess, "Transfer to sender failed!");
        }

        if (recipientFunds > 0) {
            (bool recipientSendSuccess, ) = payable(streamCopy.recipient).call{
                value: recipientFunds
            }("");
            require(recipientSendSuccess, "Transfer to recipient failed!");
        }
    }

    /**
     * @notice Allows anyone to retrieve a particular streams fields given its ID.
     * @dev I went back and forth about whether or not to limit the msg.sender of this function to recipient/sender, and ended up deciding not to, since there may be another
     * user or contract that needs to get information about a stream in the future via a convenient method - and anyone can view the contents of the streams mapping on the blockchain since nothing is private.
     * Main changes:
     * 1) using a memory variable instead of doing a bunch of storage reads. Saves a ton of gas.
     * 2) changing startTime to originalStartTime and adding currentStartTime. I also added balance field (which is different from the value returned by getBalance, which is limited to the sender and recipient).
     */
    function getStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            uint256 originalStartTime,
            uint256 currentStartTime,
            uint256 stopTime,
            uint256 rate,
            uint256 balance
        )
    {
        Stream memory stream = streams[streamId];

        sender = stream.sender;
        recipient = stream.recipient;
        deposit = stream.deposit;
        originalStartTime = stream.originalStartTime;
        currentStartTime = stream.currentStartTime;
        stopTime = stream.stopTime;
        rate = stream.rate;
        balance = stream.balance;
    }
}
