// SPDX-License-Identifier: UNLICESNED
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./PullPaymentUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IFeeDistributor.sol";

contract FeeDistributor is
    IFeeDistributor,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PullPaymentUpgradeable
{
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant VERSION = "1.1.0";
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    uint256 public constant DEFAULT_FEE_COUNT_LIMIT = 20;

    bytes32 public nativeToken;
    mapping(address contractAddress => uint256 feeCountLimit) public feeCountLimits;
    mapping(bytes32 tokenSymbol => address tokenAddress) public tokenAddresses;

    event EtherReceived(address sender, uint256 value);
    event FeeCountLimitSet(uint256 feeCountLimit);
    event NativeTokenSet(bytes32 indexed nativeToken);
    event TokenAddressSet(bytes32 tokenSymbol, address tokenAddress);
    event FeeDistributed(address indexed payee, bytes32 indexed token, uint256 amount);
    event FeesDistributed(uint256 feeCount);

    error FeeCountLimitExceeded(uint256 feeCount);
    error UnsupportedToken(bytes32 feeToken);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(bytes32 nativeToken_) external initializer {
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();
        PullPaymentUpgradeable.__PullPayment_init();

        nativeToken = nativeToken_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {
        _asyncTransfer(msg.sender, msg.value);
        emit EtherReceived(msg.sender, msg.value);
    }

    function setNativeToken(bytes32 nativeToken_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nativeToken = nativeToken_;
        emit NativeTokenSet(nativeToken_);
    }

    function setFeeCountLimit(address contractAddress, uint256 feeCountLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeCountLimits[contractAddress] = feeCountLimit;
        emit FeeCountLimitSet(feeCountLimit);
    }

    function setTokenAddress(bytes32 tokenSymbol, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenAddresses[tokenSymbol] = tokenAddress;
        emit TokenAddressSet(tokenSymbol, tokenAddress);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /* solhint-disable avoid-tx-origin */
    function distributeFee(Fee calldata fee) external payable nonReentrant whenNotPaused onlyRole(DISTRIBUTOR_ROLE) {
        fee.token == nativeToken ? fee.payee.sendValue(fee.amount) : _sendERC20Token(fee);

        if (msg.value > fee.amount) {
            uint256 residualAmount = msg.value - fee.amount;
            _asyncTransfer(tx.origin, residualAmount);
            emit EtherReceived(tx.origin, residualAmount);
        }

        emit FeeDistributed(fee.payee, fee.token, fee.amount);
    }

    function distributeFees(
        Fee[] calldata fees
    ) external payable nonReentrant whenNotPaused onlyRole(DISTRIBUTOR_ROLE) {
        uint256 feeCount = fees.length;
        uint256 contractFeeCountLimit = feeCountLimits[msg.sender];
        uint256 feeCountLimit = contractFeeCountLimit > 0 ? contractFeeCountLimit : DEFAULT_FEE_COUNT_LIMIT;
        if (feeCount > feeCountLimit) {
            revert FeeCountLimitExceeded(feeCount);
        }

        bytes32 nativeToken_ = nativeToken;
        uint256 totalNativeTokenFee = 0;

        for (uint256 i = 0; i < feeCount; ) {
            Fee calldata fee = fees[i];
            if (fee.token == nativeToken_) {
                fee.payee.sendValue(fee.amount);
                totalNativeTokenFee += fee.amount;
            } else {
                _sendERC20Token(fee);
            }
            unchecked {
                i++;
            }
        }

        if (msg.value > totalNativeTokenFee) {
            uint256 residualAmount = msg.value - totalNativeTokenFee;
            _asyncTransfer(tx.origin, residualAmount);
            emit EtherReceived(tx.origin, residualAmount);
        }

        emit FeesDistributed(feeCount);
    }

    function _sendERC20Token(Fee calldata fee) private {
        address tokenAddress = tokenAddresses[fee.token];
        if (tokenAddress == address(0)) {
            revert UnsupportedToken(fee.token);
        }
        // slither-disable-next-line arbitrary-send-erc20
        IERC20Upgradeable(tokenAddress).safeTransferFrom(tx.origin, fee.payee, fee.amount);
    }
    /* solhint-enable avoid-tx-origin */
}
