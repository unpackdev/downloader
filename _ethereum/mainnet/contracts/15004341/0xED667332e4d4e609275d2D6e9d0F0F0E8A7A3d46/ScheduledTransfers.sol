// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Owned.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./KeeperCompatible.sol";

contract ScheduledTransfers is Owned, KeeperCompatible {
    using SafeTransferLib for ERC20;

    ERC20 public token;

    uint256 public amount;

    address public receiver;

    uint32 public nextTransferTimestamp;

    uint24 public transfersInterval = 604800; // 1 week in seconds

    constructor(
        address _tokenAddress,
        address _receiver,
        uint256 _amount,
        uint32 _nextTransferTimestamp
    )
        Owned(msg.sender)
    {
        token = ERC20(_tokenAddress);
        receiver = _receiver;
        amount = _amount;
        nextTransferTimestamp = _nextTransferTimestamp;
    }

    function setToken(address tokenAddress) external onlyOwner {
        token = ERC20(tokenAddress);
    }

    function setReceiver(address newReceiver) external onlyOwner {
        receiver = newReceiver;
    }

    function setAmount(uint256 newAmount) external onlyOwner {
        amount = newAmount;
    }

    function setNextTransferTimestamp(uint32 newNextTransferTimestamp)
        external
        onlyOwner
    {
        nextTransferTimestamp = newNextTransferTimestamp;
    }

    function setTransfersInterval(uint24 newTransfersInterval)
        external
        onlyOwner
    {
        transfersInterval = newTransfersInterval;
    }

    function transferNow() external onlyOwner {
        token.safeTransfer(receiver, amount);
    }

    function checkUpkeep(bytes calldata)
        external
        view
        returns (bool, bytes memory)
    {
        return (block.timestamp >= nextTransferTimestamp, "");
    }

    function performUpkeep(bytes calldata) external {
        if (block.timestamp >= nextTransferTimestamp) {
            token.safeTransfer(receiver, amount);
            nextTransferTimestamp = uint32(block.timestamp + transfersInterval);
        }
    }

    function withdrawToken(address tokenAddress, uint256 amountToWithdraw)
        external
    {
        ERC20(tokenAddress).safeTransfer(owner, amountToWithdraw);
    }
}