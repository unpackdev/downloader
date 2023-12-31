// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract EscrowDMPlus is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    modifier validAddress(address addr) {
        require(addr != address(0), "Address cannot be zero");
        _;
    }

    struct Withdraw {
        bytes32 messageUidHash;
        bytes32 messageUid;
        bool cashback;
    }

    struct Deposit {
        uint256 amount;
        address payable sender;
        address payable recipient;
        uint256 timestamp;
    }

    enum TransferType {
        DEPOSIT,
        WITHDRAW,
        CASHBACK,
        REFUND
    }

    event MessagePaymentTransfer(
        bytes32 messageUidHash,
        Deposit deposit,
        TransferType transferType,
        uint256 feePercent
    );

    uint256 public constant MAX_FEE_PERCENT = 5;

    mapping(bytes32 => Deposit) public deposits;
    uint256 public allowRefundAfter = 0 days;
    uint256 public maxWithdrawAtOnce = 1;

    uint256 public depositFeePercent = 0;
    uint256 public withdrawFeePercent = 0;
    address payable public treasuryWallet;

    constructor() {
        treasuryWallet = payable(owner());
    }

    function setMaxWithdrawAtOnce(uint256 _value) external onlyOwner {
        require(_value > 0, "Min value is 1");

        maxWithdrawAtOnce = _value;
    }

    function setAllowRefundAfter(uint256 _newTime) external onlyOwner {
        allowRefundAfter = _newTime;
    }

    function setFees(uint256 _depositFeePercent, uint256 _withdrawFeePercent) external onlyOwner {
        require(_depositFeePercent <= MAX_FEE_PERCENT, "Deposit fee too high");
        require(_withdrawFeePercent <= MAX_FEE_PERCENT, "Withdraw fee too high");

        depositFeePercent = _depositFeePercent;
        withdrawFeePercent = _withdrawFeePercent;
    }

    function setTreasuryWallet(address payable _treasuryWallet) external onlyOwner validAddress(_treasuryWallet) {
        treasuryWallet = _treasuryWallet;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function deposit(bytes32 messageUidHash, address payable recipient) external payable nonReentrant validAddress(recipient) whenNotPaused {
        require(msg.value > 0, "Amount should be greater than 0");
        require(deposits[messageUidHash].amount == 0, "Already has a deposit for this message");

        uint256 fee = msg.value.mul(depositFeePercent).div(100);
        uint256 amountAfterFee = msg.value.sub(fee);

        deposits[messageUidHash] = Deposit({
            amount: amountAfterFee,
            sender: payable(msg.sender),
            recipient: recipient,
            timestamp: block.timestamp
        });

        (bool transferSuccess,) = treasuryWallet.call{value: fee}('');
        require(transferSuccess, 'Transfer failed');

        emit MessagePaymentTransfer(messageUidHash, deposits[messageUidHash], TransferType.DEPOSIT, depositFeePercent);
    }

    function withdraw(Withdraw[] calldata value) external nonReentrant whenNotPaused {
        require(maxWithdrawAtOnce >= value.length, "Withdraw limit exceeded at one time");

        for (uint i = 0; i < value.length; i++) {
            Deposit storage currentDeposit = deposits[value[i].messageUidHash];

            if (currentDeposit.amount == 0) {
                continue;
            }

            require(msg.sender == currentDeposit.recipient, "Only the recipient can withdraw funds");
            require(keccak256(abi.encodePacked(value[i].messageUid)) == value[i].messageUidHash, "Invalid message UID");

            uint256 fee = currentDeposit.amount.mul(withdrawFeePercent).div(100);
            uint256 amountAfterFee = currentDeposit.amount;

            currentDeposit.amount = 0;

            address payable recipient;
            TransferType transferType;
            uint256 feePercent = 0;

            if (value[i].cashback) {
                recipient = currentDeposit.sender;
                transferType = TransferType.CASHBACK;

            } else {
                feePercent = withdrawFeePercent;
                amountAfterFee = amountAfterFee.sub(fee);

                recipient = currentDeposit.recipient;
                transferType = TransferType.WITHDRAW;

                (bool transferTreasurySuccess,) = treasuryWallet.call{value: fee}('');
                require(transferTreasurySuccess, 'Transfer fee failed');
            }

            (bool transferRecipientSuccess,) = recipient.call{value: amountAfterFee}('');
            require(transferRecipientSuccess, 'Transfer recipient failed');

            emit MessagePaymentTransfer(value[i].messageUidHash, currentDeposit, transferType, feePercent);
        }
    }

    function refund(bytes32[] calldata messageUidHash) external nonReentrant whenNotPaused {
        for (uint i = 0; i < messageUidHash.length; i++) {
            Deposit storage currentDeposit = deposits[messageUidHash[i]];

            if (currentDeposit.amount == 0) {
                continue;
            }

            require(block.timestamp >= currentDeposit.timestamp + allowRefundAfter, "Refund is not yet allowed");
            require(msg.sender == currentDeposit.sender, "Only the sender can");

            uint256 amount = currentDeposit.amount;
            currentDeposit.amount = 0;

            (bool transferSuccess,) = payable(msg.sender).call{value: amount}('');
            require(transferSuccess, 'Transfer sender failed');

            emit MessagePaymentTransfer(messageUidHash[i], currentDeposit, TransferType.REFUND, 0);
        }
    }
}
