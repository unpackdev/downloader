// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./WadRayMath.sol";

import "./PTokenStorage.sol";
import "./Constants.sol";
import "./IPToken.sol";

contract PToken is IPToken, PTokenStorage {
    using WadRayMath for uint256;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Throws if called by any account other than the bucket.
     */
    modifier onlyBucket() {
        _require(address(bucket) == msg.sender, Errors.CALLER_IS_NOT_BUCKET.selector);
        _;
    }

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(bucket.registry()).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @dev Modifier to check if the sender is not blacklisted.
     */
    modifier notBlackListed() {
        _require(
            !IWhiteBlackList(bucket.whiteBlackList()).isBlackListed(msg.sender),
            Errors.SENDER_IS_BLACKLISTED.selector
        );
        _;
    }

    /**
     * @dev Modifier to check if the recipient is not blacklisted.
     */
    modifier isRecipientNotBlackListed(address _recipient) {
        _require(
            !IWhiteBlackList(bucket.whiteBlackList()).isBlackListed(_recipient),
            Errors.RECIPIENT_IS_BLACKLISTED.selector
        );
        _;
    }

    /**
     * @inheritdoc IPToken
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _bucketsFactory
    ) public override initializer {
        __ERC20_init(_name, _symbol);
        __ERC165_init();
        __ReentrancyGuard_init();
        tokenDecimals = _decimals;
        bucketsFactory = _bucketsFactory;
    }

    /**
     * @inheritdoc IPToken
     */
    function setBucket(IBucket _bucket) external override {
        _require(msg.sender == bucketsFactory, Errors.FORBIDDEN.selector);
        _require(address(bucket) == address(0), Errors.BUCKET_IS_IMMUTABLE.selector);
        _require(
            IERC165Upgradeable(address(_bucket)).supportsInterface(type(IBucket).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        bucket = _bucket;
    }

    /**
     * @inheritdoc IPToken
     */
    function setInterestIncreaser(IFeeExecutor _interestIncreaser) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            address(_interestIncreaser) == address(0) ||
                IERC165Upgradeable(address(_interestIncreaser)).supportsInterface(type(IFeeExecutor).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        interestIncreaser = _interestIncreaser;
    }

    /**
     * @inheritdoc IPToken
     */
    function setLenderRewardDistributor(
        IActivityRewardDistributor _lenderRewardDistributor
    ) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            address(_lenderRewardDistributor) == address(0) ||
                IERC165Upgradeable(address(_lenderRewardDistributor)).supportsInterface(
                    type(IActivityRewardDistributor).interfaceId
                ),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        lenderRewardDistributor = _lenderRewardDistributor;
    }

    /**
     * @inheritdoc IPToken
     */
    function lockDeposit(
        address _user,
        uint256 _amount,
        uint256 _duration
    ) external override nonReentrant notBlackListed onlyBucket {
        _require(_duration != 0, Errors.DURATION_MUST_BE_MORE_THAN_0.selector);
        _require(bucket.isActive(), Errors.BUCKET_IS_NOT_ACTIVE.selector);
        (_amount, ) = _getAvailableBalance(_user, _amount, bucket.getNormalizedIncome());
        lockedBalances[_user].totalLockedBalance += _amount;
        lockedDepositsIndexes.push(lockedBalances[_user].deposits.length);
        uint256 deadline = block.timestamp + _duration;
        lockedBalances[_user].deposits.push(Deposit(_amount, deadline, lockedDepositsIndexes.length - 1));

        emit LockDeposit(_user, lockedDepositsIndexes.length - 1, deadline, _amount);
    }

    /**
     * @inheritdoc IPToken
     */
    function unlockDeposit(uint256 _depositId) external override nonReentrant notBlackListed {
        Deposit[] storage deposits = lockedBalances[msg.sender].deposits;
        _require(deposits.length > 0, Errors.THERE_ARE_NO_LOCK_DEPOSITS.selector);
        uint256 index = lockedDepositsIndexes[_depositId];
        _require(deposits[index].id == _depositId, Errors.INCORRECT_ID.selector);
        if (!bucket.isDelisted()) {
            _require(deposits[index].deadline < block.timestamp, Errors.LOCK_TIME_IS_NOT_EXPIRED.selector);
        }
        lockedBalances[msg.sender].totalLockedBalance -= deposits[index].lockedBalance;
        deposits[index] = deposits[deposits.length - 1];
        lockedDepositsIndexes[deposits[deposits.length - 1].id] = index;

        deposits.pop();
        delete lockedDepositsIndexes[_depositId];

        emit UnlockDeposit(msg.sender, _depositId);
    }

    /**
     * @inheritdoc IPToken
     */
    function mint(address _user, uint256 _amount, uint256 _index) external override onlyBucket returns (uint256) {
        _require(_user != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        _require(_amount != 0, Errors.AMOUNT_IS_0.selector);
        uint256 amountScaled = _amount.rdiv(_index);
        _require(amountScaled != 0, Errors.INVALID_MINT_AMOUNT.selector);
        if (address(interestIncreaser) != address(0)) {
            //in this case the _index will be equal to the getNormalizedIncome()
            try interestIncreaser.updateBonus(_user, scaledBalanceOf(_user), address(bucket), _index) {} catch {
                emit Errors.Log(Errors.INTEREST_INCREASER_CALL_FAILED.selector);
            }
        }

        _mint(_user, amountScaled);

        if (address(lenderRewardDistributor) != address(0)) {
            try
                lenderRewardDistributor.updateUserActivity(
                    bucket,
                    _user,
                    scaledBalanceOf(_user),
                    IActivityRewardDistributor.Role.LENDER
                )
            {} catch {
                emit Errors.Log(Errors.LENDER_REWARD_DISTRIBUTOR_CALL_FAILED.selector);
            }
        }

        emit Mint(_user, _amount);
        return amountScaled.rmul(_index);
    }

    /**
     * @inheritdoc IPToken
     */
    function mintToReserve(address _reserve, uint256 _amount, uint256 _index) external override onlyBucket {
        uint256 amountScaled = _amount.rdiv(_index);
        if (amountScaled == 0) {
            return;
        }
        _mint(_reserve, amountScaled);
        emit Mint(_reserve, _amount);
    }

    /**
     * @inheritdoc IPToken
     */
    function burn(address _user, uint256 _amount, uint256 _index) external override onlyBucket returns (uint256) {
        _require(_user != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        uint256 amountScaled;
        (_amount, amountScaled) = _getAvailableBalance(_user, _amount, _index);
        if (address(interestIncreaser) != address(0)) {
            //in this case the _index will be equal to the getNormalizedIncome()
            try interestIncreaser.updateBonus(_user, scaledBalanceOf(_user), address(bucket), _index) {} catch {
                emit Errors.Log(Errors.INTEREST_INCREASER_CALL_FAILED.selector);
            }
        }

        _burn(_user, amountScaled);

        if (address(lenderRewardDistributor) != address(0)) {
            try
                lenderRewardDistributor.updateUserActivity(
                    bucket,
                    _user,
                    scaledBalanceOf(_user),
                    IActivityRewardDistributor.Role.LENDER
                )
            {} catch {
                emit Errors.Log(Errors.LENDER_REWARD_DISTRIBUTOR_CALL_FAILED.selector);
            }
        }

        emit Burn(_user, _amount);
        return _amount;
    }

    /**
     * @inheritdoc IPToken
     */
    function getDepositIndexById(uint256 id) external view override returns (uint256 index) {
        _require(id < lockedDepositsIndexes.length, Errors.DEPOSIT_DOES_NOT_EXIST.selector);
        return lockedDepositsIndexes[id];
    }

    /**
     * @inheritdoc IPToken
     */
    function getUserLockedBalance(address _user) external view override returns (LockedBalance memory) {
        return lockedBalances[_user];
    }

    /**
     * @dev Transfers the pTokens from 'msg.sender' to recipient.
     * @param _recipient The recipient address
     * @param _amount The amount of pTokens to be transferred.
     * If scpecified amount = type(uint256).max the all tokens of 'msg.sender' will be transferred.
     */
    function transfer(
        address _recipient,
        uint256 _amount
    )
        public
        override(ERC20Upgradeable, IERC20Upgradeable)
        nonReentrant
        isRecipientNotBlackListed(_recipient)
        returns (bool)
    {
        _require(_recipient != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        uint256 amountScaled;
        uint256 index = bucket.getNormalizedIncome();
        (_amount, amountScaled) = _getAvailableBalance(msg.sender, _amount, index);

        _updateBonusesAndRewards(msg.sender, _recipient, index, amountScaled);

        bool transfer_ = super.transfer(_recipient, amountScaled);

        emit BalanceTransfer(msg.sender, _recipient, _amount, index);
        return transfer_;
    }

    /**
     * @dev Transfers the pTokens between 'sender' and 'recipient' using allowance mechanism.
     * @param _sender The source address
     * @param _recipient The recipient address
     * @param _amount The amount of pTokens to be transferred.
     * If scpecified amount = type(uint256).max the all tokens of 'msg.sender' will be transferred.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        public
        override(ERC20Upgradeable, IERC20Upgradeable)
        nonReentrant
        isRecipientNotBlackListed(_recipient)
        returns (bool)
    {
        _require(_recipient != address(0) && _sender != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        uint256 amountScaled;
        uint256 liquidityIndex = bucket.getNormalizedIncome();
        (_amount, amountScaled) = _getAvailableBalance(_sender, _amount, liquidityIndex);
        uint256 currentAllowance = allowance(_sender, msg.sender);

        _require(currentAllowance >= _amount, Errors.TRANSFER_AMOUNT_EXCEED_ALLOWANCE.selector);
        unchecked {
            super._approve(_sender, msg.sender, currentAllowance - _amount);
        }
        _updateBonusesAndRewards(_sender, _recipient, liquidityIndex, amountScaled);
        super._transfer(_sender, _recipient, amountScaled);

        emit BalanceTransfer(_sender, _recipient, _amount, liquidityIndex);
        return true;
    }

    /**
     * @dev Returns the number of decimal places used for token values.
     * @return The number of decimal places as a uint8.
     */
    function decimals() public view override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns (uint8) {
        return tokenDecimals;
    }

    /**
     * @dev Caalculates actual 'user' balance on current block.
     * Calculates as 'principal' + 'interest'.
     * @param _user The owner of pTokens
     * @return The balance of the 'user'
     */
    function balanceOf(address _user) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return super.balanceOf(_user).rmul(bucket.getNormalizedIncome());
    }

    /**
     * @inheritdoc IPToken
     */
    function scaledBalanceOf(address _user) public view override returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @inheritdoc IPToken
     */
    function availableBalanceOf(address _user) public view override returns (uint256 result) {
        result = balanceOf(_user) - lockedBalances[_user].totalLockedBalance;
        if (!bucket.isBucketStable()) {
            // solhint-disable-next-line var-name-mixedcase
            IBucket.LiquidityMiningParams memory LMparams = bucket.getLiquidityMiningParams();
            result -= LMparams.liquidityMiningRewardDistributor.getLenderAmountInMining(bucket.name(), _user);
        }
    }

    /**
     * @dev Calculates the total supply of the pToken.
     * It increments over blocks mining.
     * @return The current total supply of the pToken.
     */
    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        uint256 currentSupplyScaled = super.totalSupply();
        if (currentSupplyScaled == 0) {
            return 0;
        }
        return currentSupplyScaled.rmul(bucket.getNormalizedIncome());
    }

    /**
     * @inheritdoc IPToken
     */
    function scaledTotalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    /// @notice Interface checker
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IPToken).interfaceId || super.supportsInterface(_interfaceId);
    }

    /**
     * @dev Internal function to update bonuses and rewards for the given sender and recipient.
     * @param _sender The address of the sender.
     * @param _recipient The address of the recipient.
     * @param _index The index used for updating bonuses.
     * @param _amountScaled The scaled amount of pTokens to be transferred.
     */
    function _updateBonusesAndRewards(
        address _sender,
        address _recipient,
        uint256 _index,
        uint256 _amountScaled
    ) internal {
        bool hasInterestIncreaser = address(interestIncreaser) != address(0);
        bool hasRewardDistributor = address(lenderRewardDistributor) != address(0);
        if (!hasInterestIncreaser && !hasRewardDistributor) return;

        address[] memory users = new address[](2);
        uint256[] memory scaledBalances = new uint256[](2);
        users[0] = _sender;
        users[1] = _recipient;
        scaledBalances[0] = scaledBalanceOf(_sender);
        scaledBalances[1] = scaledBalanceOf(_recipient);
        if (hasInterestIncreaser) {
            try interestIncreaser.updateBonuses(users, scaledBalances, address(bucket), _index) {} catch {
                emit Errors.Log(Errors.INTEREST_INCREASER_CALL_FAILED.selector);
            }
        }

        if (hasRewardDistributor) {
            scaledBalances[0] -= _amountScaled;
            scaledBalances[1] += _amountScaled;
            try
                lenderRewardDistributor.updateUsersActivities(
                    bucket,
                    users,
                    scaledBalances,
                    users.length,
                    IActivityRewardDistributor.Role.LENDER
                )
            {} catch {
                emit Errors.Log(Errors.LENDER_REWARD_DISTRIBUTOR_CALL_FAILED.selector);
            }
        }
    }

    /**
     * @dev Retrieves available balance for a user.
     * @param _user The address of the user.
     * @param _amount The requested amount.
     * @param _currentIndex The current index.
     * @return _amount The valid amount.
     * @return amountScaled The scaled amount.
     */
    function _getAvailableBalance(
        address _user,
        uint256 _amount,
        uint256 _currentIndex
    ) internal view returns (uint256, uint256) {
        uint256 availableBalance = super.balanceOf(_user).rmul(_currentIndex) -
            lockedBalances[_user].totalLockedBalance;
        if (!bucket.isBucketStable()) {
            // solhint-disable-next-line var-name-mixedcase
            IBucket.LiquidityMiningParams memory LMparams = bucket.getLiquidityMiningParams();
            availableBalance -= LMparams.liquidityMiningRewardDistributor.getLenderAmountInMining(bucket.name(), _user);
        }

        if (_amount == type(uint256).max) {
            _amount = availableBalance;
        } else {
            _require(availableBalance >= _amount, Errors.ACTION_ONLY_WITH_AVAILABLE_BALANCE.selector);
        }
        uint256 amountScaled = _amount.rdiv(_currentIndex);
        _require(amountScaled != 0, Errors.INVALID_AMOUNT.selector);
        return (_amount, amountScaled);
    }
}
