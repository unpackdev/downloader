// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

contract SendReceive is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Transaction {
        uint256 transactionCount;
        uint256 transactionType;
        address from;
        address to;
        uint256 amount;
        address token;
        address refer;
    }

    uint256 public constant FEE_DIVIDER = 100000;

    // transaction types
    uint256 public constant SEND_ETH = 0;
    uint256 public constant SEND_TOKEN = 1;
    uint256 public constant PAY_ETH = 2;
    uint256 public constant PAY_TOKEN = 3;

    bool public contractEnabled;

    uint256 public transactionCount;
    mapping(uint256 transactionCount => Transaction) public transactions;

    mapping(address user => uint256 sendTier) public sendTiers;
    mapping(uint256 sendTier => uint256 sendFee) public sendFees;

    mapping(address user => uint256 payTier) public payTiers;
    mapping(uint256 payTier => uint256 payFee) public payFees;
    mapping(uint256 payTier => uint256 payTaxFactor) public payTaxFactors;

    mapping(address refer => uint256 referralTier) public referralTiers;
    mapping(uint256 referralTier => uint256 referralFeeFactor) public referralFeeFactors;

    event EventReferralPayout(address refer, address sender, uint256 referFee, uint256 referTax);
    event EventSendTransaction(
        uint256 transactionCount,
        uint256 transactionType,
        address from,
        address to,
        uint256 amount,
        address token,
        address refer
    );

    event EventSetContractEnabled(bool _contractEnabled);
    event EventSetSendTier(address user, uint256 sendTier);
    event EventSetSendFee(uint256 sendTier, uint256 sendFee);
    event EventSetPayTier(address user, uint256 payTier);
    event EventSetPayFee(uint256 payTier, uint256 payFee);
    event EventSetPayTaxFactor(uint256 payTier, uint256 payTaxFactor);
    event EventSetReferralTier(address refer, uint256 referralTier);
    event EventSetReferralFeeFactor(uint256 referralTier, uint256 referralFeeFactor);
    event EventClaimedEthFees(address claimAddress, uint256 claimAmount);
    event EventClaimedTokenFees(address claimAddress, address token, uint256 claimAmount);

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        contractEnabled = true;

        sendFees[0] = 250000000000000;

        payFees[0] = 500000000000000;
        payTaxFactors[0] = 1000;

        referralFeeFactors[0] = 2500;
        referralFeeFactors[1] = 5000;
        referralFeeFactors[2] = 7500;
        referralFeeFactors[3] = 10000;
    }

    /* ========== USER FUNCTIONS ========== */
    function sendEth(uint256 amount, address to, address refer) external payable nonReentrant {
        require(contractEnabled, "Contract Disabled");

        uint256 sendFee = sendFees[sendTiers[msg.sender]];
        require(msg.value == amount + sendFee, "Invalid value");

        _sendValue(to, amount);

        if (refer != address(0)) {
            uint256 referralFeeFactor = referralFeeFactors[referralTiers[refer]];
            uint256 referFee = (sendFee * referralFeeFactor) / FEE_DIVIDER;

            _sendValue(refer, referFee);

            emit EventReferralPayout(refer, msg.sender, referFee, 0);
        }

        _finalizeTransaction(SEND_ETH, msg.sender, to, amount, address(0), refer);
    }

    function sendToken(address token, uint256 amount, address to, address refer) external payable nonReentrant {
        require(contractEnabled, "Contract Disabled");

        uint256 sendFee = sendFees[sendTiers[msg.sender]];
        require(msg.value == sendFee, "Invalid value");

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, to, amount);

        if (refer != address(0)) {
            uint256 referralFeeFactor = referralFeeFactors[referralTiers[refer]];
            uint256 referFee = (sendFee * referralFeeFactor) / FEE_DIVIDER;

            _sendValue(refer, referFee);

            emit EventReferralPayout(refer, msg.sender, referFee, 0);
        }

        _finalizeTransaction(SEND_TOKEN, msg.sender, to, amount, token, refer);
    }

    function payEth(uint256 amount, address to, address refer) external payable nonReentrant {
        require(contractEnabled, "Contract Disabled");

        uint256 payTier = payTiers[msg.sender];
        uint256 payFee = payFees[payTier];
        require(msg.value == amount + payFee, "Invalid value");

        uint256 payTaxFactor = payTaxFactors[payTier];
        uint256 payTax = (amount * payTaxFactor) / FEE_DIVIDER;

        _sendValue(to, amount - payTax);

        if (refer != address(0)) {
            uint256 referralFeeFactor = referralFeeFactors[referralTiers[refer]];
            uint256 referFee = (payFee * referralFeeFactor) / FEE_DIVIDER;
            uint256 referTax = (payTax * referralFeeFactor) / FEE_DIVIDER;

            _sendValue(refer, referFee + referTax);

            emit EventReferralPayout(refer, msg.sender, referFee, referTax);
        }

        _finalizeTransaction(PAY_ETH, msg.sender, to, amount, address(0), refer);
    }

    function payToken(address token, uint256 amount, address to, address refer) external payable nonReentrant {
        require(contractEnabled, "Contract Disabled");

        uint256 payTier = payTiers[msg.sender];
        uint256 payFee = payFees[payTier];
        require(msg.value == payFee, "Invalid value");

        uint256 payTaxFactor = payTaxFactors[payTier];
        uint256 payTax = (amount * payTaxFactor) / FEE_DIVIDER;

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(token).safeTransfer(to, amount - payTax);

        if (refer != address(0)) {
            uint256 referralFeeFactor = referralFeeFactors[referralTiers[refer]];
            uint256 referFee = (payFee * referralFeeFactor) / FEE_DIVIDER;
            uint256 referTax = (payTax * referralFeeFactor) / FEE_DIVIDER;

            _sendValue(refer, referFee);
            IERC20Upgradeable(token).safeTransfer(refer, referTax);

            emit EventReferralPayout(refer, msg.sender, referFee, referTax);
        }

        _finalizeTransaction(PAY_TOKEN, msg.sender, to, amount, token, refer);
    }

    /* ========== HELPER FUNCTIONS ========== */
    function _sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Failed to send");
    }

    function _finalizeTransaction(
        uint256 transactionType,
        address from,
        address to,
        uint256 amount,
        address token,
        address refer
    ) internal {
        uint256 _transactionCount = transactionCount + 1;
        transactionCount = _transactionCount;

        transactions[_transactionCount] = Transaction({
            transactionCount: _transactionCount,
            transactionType: transactionType,
            from: from,
            to: to,
            amount: amount,
            token: token,
            refer: refer
        });

        emit EventSendTransaction(_transactionCount, transactionType, from, to, amount, token, refer);
    }

    /* ========== ADMIN FUNCTIONS ========== */
    function setContractEnabled(bool _contractEnabled) external onlyOwner {
        contractEnabled = _contractEnabled;
        emit EventSetContractEnabled(_contractEnabled);
    }

    function setSendTier(address user, uint256 sendTier) external onlyOwner {
        sendTiers[user] = sendTier;
        emit EventSetSendTier(user, sendTier);
    }

    function setSendFee(uint256 sendTier, uint256 sendFee) external onlyOwner {
        sendFees[sendTier] = sendFee;
        emit EventSetSendFee(sendTier, sendFee);
    }

    function setPayTier(address user, uint256 payTier) external onlyOwner {
        payTiers[user] = payTier;
        emit EventSetPayTier(user, payTier);
    }

    function setPayFee(uint256 payTier, uint256 payFee) external onlyOwner {
        payFees[payTier] = payFee;
        emit EventSetPayFee(payTier, payFee);
    }

    function setPayTaxFactor(uint256 payTier, uint256 payTaxFactor) external onlyOwner {
        payTaxFactors[payTier] = payTaxFactor;
        emit EventSetPayTaxFactor(payTier, payTaxFactor);
    }

    function setReferralTier(address refer, uint256 referralTier) external onlyOwner {
        referralTiers[refer] = referralTier;
        emit EventSetReferralTier(refer, referralTier);
    }

    function setReferralFeeFactor(uint256 referralTier, uint256 referralFeeFactor) external onlyOwner {
        referralFeeFactors[referralTier] = referralFeeFactor;
        emit EventSetReferralFeeFactor(referralTier, referralFeeFactor);
    }

    function claimEthFees(address claimAddress) external onlyOwner {
        require(claimAddress != address(0), "Cannot be address zero");

        uint256 claimAmount = address(this).balance;
        _sendValue(claimAddress, claimAmount);

        emit EventClaimedEthFees(claimAddress, claimAmount);
    }

    function claimTokenFees(address claimAddress, address token) external onlyOwner {
        require(claimAddress != address(0), "Cannot be address zero");

        uint256 claimAmount = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransfer(claimAddress, claimAmount);

        emit EventClaimedTokenFees(claimAddress, token, claimAmount);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("cannot renounce ownership");
    }
}
