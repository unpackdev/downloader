// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Ownable.sol";

import "./IMeVesting.sol";


/// @title ME 3-year vesting contract
/// @author @CBobRobison, @carlfarterson, @bunsdev
/// @notice vests ME for 3 years to key meTokens stakeholders, claimable upon governance "transferability" vote
contract MeVesting is IMeVesting, ReentrancyGuard, Ownable {

    /// @notice check to enable stream withdrawals
    bool public withdrawable;

    /// @notice Counter for new stream ids.
    uint256 public streamId;

    struct Stream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        address tokenAddress;
        bool isEntity;
    }

    // @notice The stream objects identifiable by their unsigned integer ids.
    mapping(uint256 => Stream) private streams;

    /// @dev Throws if the caller is not the sender of the recipient of the stream.
    modifier onlySenderOrRecipient(uint256 _streamId) {
        require(
            msg.sender == streams[_streamId].sender || msg.sender == streams[_streamId].recipient,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }

    /// @dev Throws if the provided id does not point to a valid stream.
    modifier streamExists(uint256 _streamId) {
        require(streams[_streamId].isEntity, "stream does not exist");
        _;
    }

    /// @inheritdoc IMeVesting
    function getStream(uint256 _streamId)
        external
        view
        override
        streamExists(_streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        )
    {
        sender = streams[_streamId].sender;
        recipient = streams[_streamId].recipient;
        deposit = streams[_streamId].deposit;
        tokenAddress = streams[_streamId].tokenAddress;
        startTime = streams[_streamId].startTime;
        stopTime = streams[_streamId].stopTime;
        remainingBalance = streams[_streamId].remainingBalance;
        ratePerSecond = streams[_streamId].ratePerSecond;
    }


    /// @inheritdoc IMeVesting
    function deltaOf(uint256 _streamId)
        public
        view
        streamExists(_streamId)
        override
        returns (uint256 delta)
    {
        Stream memory stream = streams[_streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }


    /// @inheritdoc IMeVesting
    function balanceOf(uint256 _streamId, address who)
        public
        view
        override
        streamExists(_streamId)
        returns (uint256) 
    {
        Stream memory stream = streams[_streamId];

        uint256 recipientBalance = deltaOf(_streamId) * stream.ratePerSecond;

        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        if (stream.deposit > stream.remainingBalance) {
            uint256 withdrawalAmount = stream.deposit - stream.remainingBalance;
            recipientBalance -= withdrawalAmount;
        }

        if (who == stream.recipient) {return recipientBalance;}
        if (who == stream.sender) {
            uint256 senderBalance = stream.remainingBalance - recipientBalance;
            return senderBalance;
        }
        return 0;
    }


    /// @inheritdoc IMeVesting
    function createStream(address recipient,uint256 deposit,address tokenAddress)
        public
        override
        returns (uint256)
    {
        require(recipient != address(0), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(deposit > 0, "deposit is zero");

        uint256 startTime = block.timestamp - 5392000;
        uint256 stopTime = block.timestamp + 1095 days;

        require(stopTime > startTime, "stop time before the start time");

        uint256 duration = stopTime - startTime;

        /* Without this, the rate per second would be zero. */
        require(deposit >= duration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        require(deposit % duration == 0, "deposit not multiple of time delta");

        uint256 ratePerSecond = deposit / duration;

        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), deposit), "token transfer failure");

        //  TODO: should streams be mapped to their index, or start at 1?
        streams[++streamId] = Stream({
            remainingBalance: deposit,
            deposit: deposit,
            isEntity: true,
            ratePerSecond: ratePerSecond,
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            stopTime: stopTime,
            tokenAddress: tokenAddress
        });

        emit CreateStream(streamId, msg.sender, recipient, deposit, tokenAddress, startTime, stopTime);

        return streamId;
    }


    /// @inheritdoc IMeVesting
    function withdrawFromStream(uint256 _streamId, uint256 amount)
        external
        nonReentrant
        streamExists(_streamId)
        onlySenderOrRecipient(_streamId)
        override
        returns (bool)
    {
        require(withdrawable, "not withdrawable");
        require(amount > 0, "amount is zero");
        
        Stream storage stream = streams[_streamId];

        uint256 balance = balanceOf(_streamId, stream.recipient);
        require(balance >= amount, "amount exceeds the available balance");

        stream.remainingBalance -= amount;
        if (stream.remainingBalance == 0) {delete streams[_streamId];}

        require(IERC20(stream.tokenAddress).transfer(stream.recipient, amount), "token transfer failure");

        emit WithdrawFromStream(_streamId, stream.recipient, amount);
    }


    /// @inheritdoc IMeVesting
    function cancelStream(uint256 _streamId)
        external
        override
        nonReentrant
        streamExists(_streamId)
        onlySenderOrRecipient(_streamId)
        returns (bool)
    {
        require(withdrawable, "not withdrawable");

        Stream memory stream = streams[_streamId];
        uint256 senderBalance = balanceOf(_streamId, stream.sender);
        uint256 recipientBalance = balanceOf(_streamId, stream.recipient);

        delete streams[_streamId];

        IERC20 token = IERC20(stream.tokenAddress);
        if (recipientBalance > 0) {
            require(token.transfer(stream.recipient, recipientBalance), "recipient token transfer failure");
        }
        if (senderBalance > 0) {
            require(token.transfer(stream.sender, senderBalance), "sender token transfer failure");
        }

        emit CancelStream(_streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);
    }

    function turnOnWithdrawals() onlyOwner public {
        require(!withdrawable, "withdrawals already enabled");
        withdrawable = true;
        emit TurnOnWithdrawals();
    }
}
