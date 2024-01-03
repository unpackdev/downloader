// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.20;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";

contract NumeDeposit is Initializable, ReentrancyGuardUpgradeable {
    address public numeOwner;
    uint256 public totalTokens;
    uint256 public depositsLimit;
    mapping(address => uint) public userDepositCount;
    mapping(address => uint) public userDepositTimestamp;
    mapping(address => bool) public isAddressBlacklisted;
    mapping(address => uint256) public tokenDepositLimit;
    mapping(address => bool) public supportedTokens;
    mapping(uint256 => address) public depositSenderAddress;
    mapping(address => mapping(address => uint256)) public userInvalidBalance;

    modifier numeOwnerOnly() {
        require(
            msg.sender == numeOwner,
            "Nume: Only Nume owner can call this function"
        );
        _;
    }

    event DepositQueued(
        address user,
        address sender,
        address tokenAddress,
        uint256 amountDeposited
    );
    event DepositLimit(uint256 limit);
    event TokenWithdrawn(address user, address tokenAddress, uint256 amount);

    error ExceededMaximumDailyCalls(address user);
    error InvalidTokenAddress(address tokenAddress);
    error InvalidAmount();
    error AddressBlacklisted(address user);
    error TransactionFailed();

    function initialize(address admin) public initializer {
        numeOwner = admin;
    }

    function setNumeOwner(address _numeOwner) external numeOwnerOnly {
        numeOwner = _numeOwner;
    }

    function supportToken(address _tokenAddress) external numeOwnerOnly {
        if (supportedTokens[_tokenAddress]) {
            revert InvalidTokenAddress(_tokenAddress);
        }
        ++totalTokens;
        supportedTokens[_tokenAddress] = true;
    }

    function setBlacklistStatus(
        address _user,
        bool _value
    ) external numeOwnerOnly {
        isAddressBlacklisted[_user] = _value;
    }

    function setTokenDepositLimit(
        address _tokenAddress,
        uint256 _limit
    ) external numeOwnerOnly {
        if (!supportedTokens[_tokenAddress]) {
            revert InvalidTokenAddress(_tokenAddress);
        }
        tokenDepositLimit[_tokenAddress] = _limit;
    }

    /// @notice Function to set the maximum number of deposits allowed per day.
    /// @param _limit The maximum number of deposits allowed per day.
    function setDepositsLimit(
        uint256 _limit
    ) external numeOwnerOnly nonReentrant {
        depositsLimit = _limit;
        emit DepositLimit(_limit);
    }

    /// @notice Function to check the number of deposits made by a user in a day.
    /// @param _user The address of the user.
    function _checkDepositStatus(address _user) internal {
        if (isAddressBlacklisted[_user]) {
            revert AddressBlacklisted(_user);
        }
        uint256 currentTime = block.timestamp;
        if (currentTime - userDepositTimestamp[_user] >= 1 days) {
            delete userDepositCount[_user];
            userDepositTimestamp[_user] = currentTime;
        }
        if (userDepositCount[_user] >= depositsLimit) {
            revert ExceededMaximumDailyCalls(_user);
        }
    }

    /// @notice Function to deposit native token into the Nume contract.
    /// @dev Will be blocked in case of exodus mode.
    /// @param _user The address of the user who is depositing the token.
    function deposit(address _user) external payable nonReentrant {
        _checkDepositStatus(msg.sender);
        if (!(msg.value > 0)) {
            revert InvalidAmount();
        }
        if (
            msg.value >
            tokenDepositLimit[0x1111111111111111111111111111111111111111]
        ) {
            revert InvalidAmount();
        }
        userDepositCount[msg.sender]++;
        emit DepositQueued(
            _user,
            msg.sender,
            0x1111111111111111111111111111111111111111,
            msg.value
        );
    }

    /// @notice Function to deposit ERC20 token into the Nume contract.
    /// @dev Will be blocked in case of exodus mode.
    /// @param _user The address of the user who is depositing the token.
    /// @param _tokenAddress The address of the ERC20 token to deposit.
    /// @param _depositAmount The amount of the ERC20 token to deposit.
    function depositERC20(
        address _user,
        address _tokenAddress,
        uint256 _depositAmount
    ) external nonReentrant {
        if (!supportedTokens[_tokenAddress]) {
            revert InvalidTokenAddress(_tokenAddress);
        }
        _checkDepositStatus(msg.sender);
        userDepositCount[msg.sender]++;
        uint256 balanceBefore = IERC20(_tokenAddress).balanceOf(address(this));
        SafeERC20.safeTransferFrom(
            IERC20(_tokenAddress),
            msg.sender,
            address(this),
            _depositAmount
        );
        uint256 balanceAfter = IERC20(_tokenAddress).balanceOf(address(this));
        uint256 depositAmount = balanceAfter - balanceBefore;
        if (
            depositAmount > tokenDepositLimit[_tokenAddress] ||
            depositAmount != _depositAmount ||
            !(depositAmount > 0)
        ) {
            revert InvalidAmount();
        }
        emit DepositQueued(_user, msg.sender, _tokenAddress, depositAmount);
    }

    function invalidDeposit(
        address _user,
        address _tokenAddress,
        uint256 _amount
    ) external numeOwnerOnly {
        if (!supportedTokens[_tokenAddress]) {
            revert InvalidTokenAddress(_tokenAddress);
        }
        if (!(_amount > 0)) {
            revert InvalidAmount();
        }
        userInvalidBalance[_user][_tokenAddress] += _amount;
    }

    function withdrawInvalidDeposit(
        address _user,
        address _tokenAddress
    ) external {
        if (!supportedTokens[_tokenAddress]) {
            revert InvalidTokenAddress(_tokenAddress);
        }
        uint256 _amount = userInvalidBalance[_user][_tokenAddress];
         if (!(_amount > 0)) {
            revert InvalidAmount();
        }
        delete userInvalidBalance[_user][_tokenAddress];
        if (_tokenAddress == 0x1111111111111111111111111111111111111111) {
            (bool sent, ) = _user.call{value: _amount}("");
            if (!sent) {
                revert TransactionFailed();
            }
        } else {
            uint256 balanceBefore = IERC20(_tokenAddress).balanceOf(
                address(this)
            );
            SafeERC20.safeTransfer(IERC20(_tokenAddress), _user, _amount);
            uint256 balanceAfter = IERC20(_tokenAddress).balanceOf(
                address(this)
            );
            uint256 amountSent = balanceBefore - balanceAfter;
            if (amountSent != _amount) {
                revert TransactionFailed();
            }
        }
        emit TokenWithdrawn(_user, _tokenAddress, _amount);
    }
}
