// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IMoneyStreamer.sol";
import "./Types.sol";
import "./CarefulMath.sol";

/**
 * @title Money Streamer
 * @author Wage3 (@wage3xyz)
 * @notice Optimized money streaming smart contract.
 */
contract MoneyStreamer is
    IMoneyStreamer,
    ReentrancyGuard,
    CarefulMath,
    Ownable
{
    using SafeERC20 for IERC20;

    uint256 public nextStreamId;
    uint256 public serviceFee = 5; // 5 = 0.05%    1000 = 100%

    mapping(uint256 => Types.Stream) private streams;

    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender ||
                msg.sender == streams[streamId].recipient,
            "Caller is not the sender or the recipient of the stream."
        );
        _;
    }

    modifier streamExists(uint256 streamId) {
        require(
            streams[streamId].isActive ||
                streams[streamId].isFinished ||
                streams[streamId].isCanceled,
            "Stream does not exist"
        );
        _;
    }

    struct BalanceOfLocalVars {
        MathError mathErr;
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }

    struct CreateStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 ratePerSecond;
    }

    constructor() {
        nextStreamId = 1;
    }

    function updateServiceFee(uint256 newServiceFee) external onlyOwner {
        require(newServiceFee <= 1000, "Fee cannot be higher than 100%");
        require(newServiceFee >= 0, "Fee cannot be lower than 0");
        serviceFee = newServiceFee;
    }

    function calculateFee(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * serviceFee) / 1000;
        return feeAmount;
    }

    function getStreamById(uint256 streamId)
        external
        view
        override
        streamExists(streamId)
        returns (Types.Stream memory stream)
    {
        return streams[streamId];
    }

    function getActiveStreams(address userAddress)
        external
        view
        override
        returns (Types.Stream[] memory streamsByRecipient)
    {
        Types.Stream[] memory iteratingStreams = new Types.Stream[](
            nextStreamId
        );
        for (uint256 i = 1; i < nextStreamId; i++) {
            if (
                (streams[i].recipient == userAddress ||
                    streams[i].sender == userAddress) && streams[i].isActive
            ) {
                Types.Stream storage currentStream = streams[i];
                iteratingStreams[i] = currentStream;
            }
        }
        return iteratingStreams;
    }

    function getStreamsByRecipientAddress(address recipient)
        external
        view
        override
        returns (Types.Stream[] memory streamsByRecipient)
    {
        Types.Stream[] memory iteratingStreams = new Types.Stream[](
            nextStreamId
        );
        for (uint256 i = 1; i < nextStreamId; i++) {
            if (streams[i].recipient == recipient) {
                Types.Stream storage currentStream = streams[i];
                iteratingStreams[i] = currentStream;
            }
        }
        return iteratingStreams;
    }

    function getStreamsBySenderAddress(address sender)
        external
        view
        override
        returns (Types.Stream[] memory streamsBySender)
    {
        Types.Stream[] memory iteratingStreams = new Types.Stream[](
            nextStreamId
        );
        for (uint256 i = 1; i < nextStreamId; i++) {
            if (streams[i].sender == sender) {
                Types.Stream storage currentStream = streams[i];
                iteratingStreams[i] = currentStream;
            }
        }
        return iteratingStreams;
    }

    function deltaOf(uint256 streamId)
        public
        view
        streamExists(streamId)
        returns (uint256 delta)
    {
        Types.Stream memory stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0; // Stream not started yet
        if (block.timestamp < stream.stopTime)
            return block.timestamp - stream.startTime; // Stream is active
        return stream.stopTime - stream.startTime; // Stream is finished
    }

    function balanceOf(uint256 streamId, address account)
        public
        view
        override
        streamExists(streamId)
        returns (uint256 balance)
    {
        Types.Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        (vars.mathErr, vars.recipientBalance) = mulUInt(
            delta,
            stream.ratePerSecond
        );
        require(
            vars.mathErr == MathError.NO_ERROR,
            "recipient balance calculation error"
        );

        if (stream.deposit > stream.remainingBalance) {
            (vars.mathErr, vars.withdrawalAmount) = subUInt(
                stream.deposit,
                stream.remainingBalance
            );
            assert(vars.mathErr == MathError.NO_ERROR);
            (vars.mathErr, vars.recipientBalance) = subUInt(
                vars.recipientBalance,
                vars.withdrawalAmount
            );

            assert(vars.mathErr == MathError.NO_ERROR);
        }

        if (account == stream.recipient) return vars.recipientBalance;
        if (account == stream.sender) {
            (vars.mathErr, vars.senderBalance) = subUInt(
                stream.remainingBalance,
                vars.recipientBalance
            );

            assert(vars.mathErr == MathError.NO_ERROR);
            return vars.senderBalance;
        }
        return 0;
    }

    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) internal returns (uint256) {
        require(
            recipient != address(0x00),
            "Stream to the zero address not allowed."
        );
        require(
            recipient != address(this),
            "Stream to the contract itself not allowed."
        );
        require(recipient != msg.sender, "Stream to the caller not allowed.");
        require(deposit > 0, "Deposit is zero. Stream not created.");
        require(
            startTime >= block.timestamp,
            "Start time cannot be in the past."
        );
        require(
            stopTime > startTime,
            "Stop time cannot be before the start time."
        );

        CreateStreamLocalVars memory vars;
        (vars.mathErr, vars.duration) = subUInt(stopTime, startTime);

        assert(vars.mathErr == MathError.NO_ERROR);

        // Without this, the rate per second would be zero.
        require(
            deposit >= vars.duration,
            "Deposit smaller than time delta not allowed."
        );

        // This condition avoids dealing with remainders
        require(
            deposit % vars.duration == 0,
            "Deposit not multiple of time delta not allowed."
        );

        (vars.mathErr, vars.ratePerSecond) = divUInt(deposit, vars.duration);

        assert(vars.mathErr == MathError.NO_ERROR);

        uint256 streamId = nextStreamId;
        streams[streamId] = Types.Stream({
            id: streamId,
            remainingBalance: deposit,
            deposit: deposit,
            ratePerSecond: vars.ratePerSecond,
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            stopTime: stopTime,
            tokenAddress: tokenAddress,
            isActive: true,
            isFinished: false,
            isCanceled: false
        });

        // Increment the next stream id
        (vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
        require(
            vars.mathErr == MathError.NO_ERROR,
            "next stream id calculation error"
        );

        // deposit the deposit amount to the smart contract to unlock the stream
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            deposit
        );

        // pay service fee
        uint256 fee = calculateFee(deposit);
        IERC20(tokenAddress).safeTransferFrom(msg.sender, owner(), fee);

        emit CreateStream(
            streamId,
            msg.sender,
            recipient,
            deposit,
            tokenAddress,
            startTime,
            stopTime
        );
        return streamId;
    }

    function createStreams(
        address[] memory recipients,
        uint256[] memory deposits,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) public {
        require(
            recipients.length == deposits.length,
            "Size of Recipients and Deposits does not match."
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            createStream(
                recipients[i],
                deposits[i],
                tokenAddress,
                startTime,
                stopTime
            );
        }
    }

    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        override
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        require(amount > 0, "Amount is zero. Withdrawal not performed.");
        Types.Stream memory stream = streams[streamId];

        uint256 balance = balanceOf(streamId, stream.recipient);
        require(
            balance >= amount,
            "Amount exceeds the available balance. Withdrawal not performed."
        );

        MathError mathErr;
        (mathErr, streams[streamId].remainingBalance) = subUInt(
            stream.remainingBalance,
            amount
        );

        assert(mathErr == MathError.NO_ERROR);

        if (streams[streamId].remainingBalance == 0) {
            streams[streamId].isFinished = true;
            streams[streamId].isActive = false;
        }

        IERC20(stream.tokenAddress).safeTransfer(stream.recipient, amount);
        emit WithdrawFromStream(streamId, stream.recipient, amount);
        return true;
    }

    function cancelStream(uint256 streamId)
        external
        override
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        Types.Stream memory stream = streams[streamId];
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        streams[streamId];

        IERC20 token = IERC20(stream.tokenAddress);
        if (recipientBalance > 0)
            token.safeTransfer(stream.recipient, recipientBalance);
        if (senderBalance > 0) token.safeTransfer(stream.sender, senderBalance);

        streams[streamId].isFinished = false;
        streams[streamId].isActive = false;
        streams[streamId].isCanceled = true;

        emit CancelStream(
            streamId,
            stream.sender,
            stream.recipient,
            senderBalance,
            recipientBalance
        );
        return true;
    }
}
