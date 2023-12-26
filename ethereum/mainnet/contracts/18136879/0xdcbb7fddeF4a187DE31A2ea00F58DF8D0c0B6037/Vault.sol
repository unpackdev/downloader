pragma solidity ^0.8.11;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";
import "./IBurnableERC20.sol";

import "./console.sol";

error InvalidLockingDuration();
error ZeroAddress();
error ZeroAddressToken();
error InvalidAmount();
error NoDeposit();
error TokensLocked();
error CannotExtendLocking();
error InvalidUnlockingTimestamp();
error InvalidAccount();
error NeedsLockingRenewal();
error CannotRecoverLockableToken();
error NoTokensToRecover();

/**
 * @title Vault
 * @dev Vault contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract Vault is Ownable, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 constant private DECIMAL_FACTOR = 10**18; // 18 decimal places for fixed-point arithmetic

    struct Deposit {
        uint256 amount;
        uint256 unlockingTimestamp;
    }

    struct Beneficary {
        uint256 amount;
        uint256 lockingDuration;
        address beneficiary;
    }

    uint256 public lockingDuration;
    mapping(address => Deposit) public userDeposit;
    IBurnableERC20 public token;
    address public penaltyDepositAddress;

    event LockingDurationUpdated(uint256 duration);
    event UnlockingTimestampUpdated(address user, uint256 unlockingTimestamp);
    event Deposited(address user, uint256 amount, uint256 unlockingTimestamp);
    event Withdrawn(address indexed user, uint256 requestedAmount, uint256 receivedAmount, uint256 burnAmount, uint256 adminPenalty);
    event LockingRenewed(address user, uint256 unlockingTimestamp);
    event ERC20Recovered(address token, uint256 amount);
    event NewAdmin(address admin);
    event AdminRemoved(address admin);
    event PenaltyDespositAddressUpdated(address penaltyDepositAddress);

    constructor(address _token, uint256 _lockingDuration, address _penaltyDepositAddress) {
        if (_token == address(0)) revert ZeroAddressToken();
        if (_lockingDuration == 0) revert InvalidLockingDuration();
        if (_penaltyDepositAddress == address(0)) revert ZeroAddress();
        token = IBurnableERC20(_token);
        lockingDuration = _lockingDuration;
        penaltyDepositAddress = _penaltyDepositAddress;
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function addAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert ZeroAddress();
        _grantRole(ADMIN_ROLE, _admin);
        emit NewAdmin(_admin);
    }

    function relinquishAdminRole() external onlyRole(ADMIN_ROLE) {
        _revokeRole(ADMIN_ROLE, msg.sender);
        emit AdminRemoved(msg.sender);
    }

    function updatePenaltyDepositAddress(address _penaltyDepositAddress) external onlyOwner {
        if (_penaltyDepositAddress == address(0)) revert ZeroAddress();
        penaltyDepositAddress = _penaltyDepositAddress;
        emit PenaltyDespositAddressUpdated(penaltyDepositAddress);
    }

    function updateLockingDuration(uint256 _duration) external onlyOwner {
        if (_duration == 0) revert InvalidLockingDuration();
        lockingDuration = _duration;
        emit LockingDurationUpdated(_duration);
    }

    function reduceUnlockingTimestamp(
        address _account,
        uint256 _unlockingTimestamp
    ) external onlyOwner {
        if (_unlockingTimestamp < block.timestamp)
            revert InvalidUnlockingTimestamp();
        Deposit storage _deposit = userDeposit[_account];
        if (_deposit.amount == 0) revert InvalidAccount();
        if (_unlockingTimestamp > _deposit.unlockingTimestamp)
            revert CannotExtendLocking();
        _deposit.unlockingTimestamp = _unlockingTimestamp;
        emit UnlockingTimestampUpdated(_account, _unlockingTimestamp);
    }

    function recoverERC20(address _tokenToRecover) external onlyOwner {
        if (_tokenToRecover == address(token)) revert CannotRecoverLockableToken();
        uint256 _tokenBalance = IERC20(_tokenToRecover).balanceOf(
            address(this)
        );
        if (_tokenBalance == 0) revert NoTokensToRecover();
        IERC20(_tokenToRecover).safeTransfer(owner(), _tokenBalance);
        emit ERC20Recovered(_tokenToRecover, _tokenBalance);
    }

    function deposit(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        Deposit storage _deposit = userDeposit[msg.sender];
        _deposit.amount += _amount;
        if (_deposit.unlockingTimestamp == 0)
            _deposit.unlockingTimestamp = block.timestamp + lockingDuration;
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _amount, _deposit.unlockingTimestamp);
    }

    function depositForBeneficary(uint _amount, address _beneficiary, uint256 _lockingDuration) external onlyRole(ADMIN_ROLE) {
        if (_amount == 0) revert InvalidAmount();
        if (_beneficiary == address(0)) revert ZeroAddress();
        if (_lockingDuration == 0) revert InvalidLockingDuration();
        Deposit storage _deposit = userDeposit[_beneficiary];
        _deposit.amount += _amount;
        if (_deposit.unlockingTimestamp == 0)
            _deposit.unlockingTimestamp = block.timestamp + _lockingDuration;
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(_beneficiary, _amount, _deposit.unlockingTimestamp);
    }

    function depositForBeneficaries(Beneficary[] calldata _beneficiaries) external onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < _beneficiaries.length; i++) {
            if (_beneficiaries[i].amount == 0 || _beneficiaries[i].lockingDuration == 0 || _beneficiaries[i].beneficiary == address(0)) {
                continue;
            }
            Deposit storage _deposit = userDeposit[_beneficiaries[i].beneficiary];
            _deposit.amount += _beneficiaries[i].amount;
            if (_deposit.unlockingTimestamp == 0)
            _deposit.unlockingTimestamp = block.timestamp + _beneficiaries[i].lockingDuration;
            IERC20(token).safeTransferFrom(msg.sender, address(this), _beneficiaries[i].amount);
            emit Deposited(_beneficiaries[i].beneficiary, _beneficiaries[i].amount, _deposit.unlockingTimestamp);
        }
    }

    function withdraw(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        bool _isEarly = false;
        uint256 _totalAmount = _amount;
        uint256 _burnAmount = 0;
        uint256 _adminAmount = 0;
        Deposit storage _deposit = userDeposit[msg.sender];
        if (_deposit.amount < _amount) revert InvalidAmount();
        if (_deposit.unlockingTimestamp > block.timestamp) {
            if (_deposit.unlockingTimestamp - lockingDuration > block.timestamp) revert TokensLocked();
            uint256 elapsed = block.timestamp - (_deposit.unlockingTimestamp - lockingDuration);
            uint256 proportion = ( elapsed * DECIMAL_FACTOR ) / lockingDuration;
            uint256 penalty = (_totalAmount * (DECIMAL_FACTOR - proportion))/DECIMAL_FACTOR;
            _burnAmount = penalty / 2;
            _adminAmount = penalty - _burnAmount;
            _totalAmount -= penalty;
            _isEarly = true;
        }
        _deposit.amount -= _amount;
        if(_deposit.amount == 0) _deposit.unlockingTimestamp = 0;
        IERC20(token).safeTransfer(msg.sender, _totalAmount);
        if (_isEarly) {
            token.burn(_burnAmount);
            IERC20(token).safeTransfer(penaltyDepositAddress, _adminAmount);
        }
        emit Withdrawn(msg.sender, _amount, _totalAmount, _burnAmount, _adminAmount);
    }

    function viewWithdrawStatus(address _beneficiary) public view returns (uint256 amount, uint256 burnt, uint256 admin, uint256 tokensUnlockTimeRemaining) {
        if (_beneficiary == address(0)) revert ZeroAddress();
        uint256 _burnAmount = 0;
        uint256 _adminAmount = 0;
        uint256 _remainingDuration = 0;
        Deposit storage _deposit = userDeposit[_beneficiary];
        uint256 _amount = _deposit.amount;
        if (_deposit.unlockingTimestamp == 0) revert NoDeposit();
        if (_deposit.unlockingTimestamp > block.timestamp) {
            if (_deposit.unlockingTimestamp - lockingDuration > block.timestamp) revert TokensLocked();
            uint256 elapsed = block.timestamp - (_deposit.unlockingTimestamp - lockingDuration);
            uint256 proportion = ( elapsed * DECIMAL_FACTOR ) / lockingDuration;
            uint256 penalty = (_amount * (DECIMAL_FACTOR - proportion))/DECIMAL_FACTOR;
            _amount -= penalty;
            _burnAmount = penalty / 2;
            _adminAmount = penalty - _burnAmount;
            _remainingDuration = _deposit.unlockingTimestamp - block.timestamp;
        }
        return (_amount, _burnAmount, _adminAmount, _remainingDuration);
    }

    function renewLocking() external {
        Deposit storage _deposit = userDeposit[msg.sender];
        if (_deposit.unlockingTimestamp == 0) revert NoDeposit();
        uint256 _unlockingTimestamp = (
            _deposit.unlockingTimestamp > block.timestamp
                ? _deposit.unlockingTimestamp
                : block.timestamp
        ) + lockingDuration;
        _deposit.unlockingTimestamp = _unlockingTimestamp;
        emit LockingRenewed(msg.sender, _unlockingTimestamp);
    }

    function renewedUnlockingTimestamp(address _account)
        external
        view
        returns (uint256)
    {
        Deposit storage _deposit = userDeposit[_account];
        if (_deposit.unlockingTimestamp == 0) revert NoDeposit();
        return
            (
                _deposit.unlockingTimestamp > block.timestamp
                    ? _deposit.unlockingTimestamp
                    : block.timestamp
            ) + lockingDuration;
    }
}
