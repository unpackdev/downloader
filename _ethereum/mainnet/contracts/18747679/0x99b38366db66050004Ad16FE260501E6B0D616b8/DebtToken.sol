// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./WadRayMath.sol";

import "./DebtTokenStorage.sol";
import "./Constants.sol";
import "./IDebtToken.sol";

contract DebtToken is IDebtToken, DebtTokenStorage {
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
     * @inheritdoc IDebtToken
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _bucketsFactory
    ) public override initializer {
        __ERC20_init(_name, _symbol);
        __ERC165_init();
        _tokenDecimals = _decimals;
        bucketsFactory = _bucketsFactory;
    }

    /**
     * @inheritdoc IDebtToken
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
     * @inheritdoc IDebtToken
     */
    function setFeeDecreaser(IFeeExecutor _feeDecreaser) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            address(_feeDecreaser) == address(0) ||
                IERC165Upgradeable(address(_feeDecreaser)).supportsInterface(type(IFeeExecutor).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        feeDecreaser = _feeDecreaser;
    }

    /**
     * @inheritdoc IDebtToken
     */
    function setTraderRewardDistributor(
        IActivityRewardDistributor _traderRewardDistributor
    ) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            address(_traderRewardDistributor) == address(0) ||
                IERC165Upgradeable(address(_traderRewardDistributor)).supportsInterface(
                    type(IActivityRewardDistributor).interfaceId
                ),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        traderRewardDistributor = _traderRewardDistributor;
    }

    /**
     * @inheritdoc IDebtToken
     */
    function mint(address _user, uint256 _amount, uint256 _index) external override onlyBucket {
        _require(_user != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        _require(_amount != 0, Errors.AMOUNT_IS_0.selector);
        uint256 amountScaled = _amount.rdiv(_index);
        _require(amountScaled != 0, Errors.INVALID_MINT_AMOUNT.selector);
        if (address(feeDecreaser) != address(0)) {
            //in this case the _index will be equal to the getNormalizedVariableDebt()
            try feeDecreaser.updateBonus(_user, scaledBalanceOf(_user), address(bucket), _index) {} catch {
                emit Errors.Log(Errors.FEE_DECREASER_CALL_FAILED.selector);
            }
        }

        _mint(_user, amountScaled);

        if (address(traderRewardDistributor) != address(0)) {
            try
                traderRewardDistributor.updateUserActivity(
                    bucket,
                    _user,
                    scaledBalanceOf(_user),
                    IActivityRewardDistributor.Role.TRADER
                )
            {} catch {
                emit Errors.Log(Errors.TRADER_REWARD_DISTRIBUTOR_CALL_FAILED.selector);
            }
        }

        emit Mint(_user, _amount);
    }

    /**
     * @inheritdoc IDebtToken
     */
    function burn(address _user, uint256 _amount, uint256 _index) external override onlyBucket {
        _require(_user != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        _require(_amount != 0, Errors.AMOUNT_IS_0.selector); //do we need this?
        uint256 amountScaled = _amount.rdiv(_index);
        _require(amountScaled != 0, Errors.INVALID_BURN_AMOUNT.selector);
        if (address(feeDecreaser) != address(0)) {
            //in this case the _index will be equal to the getNormalizedVariableDebt()
            try feeDecreaser.updateBonus(_user, scaledBalanceOf(_user), address(bucket), _index) {} catch {
                emit Errors.Log(Errors.FEE_DECREASER_CALL_FAILED.selector);
            }
        }

        _burn(_user, amountScaled);

        if (address(traderRewardDistributor) != address(0)) {
            try
                traderRewardDistributor.updateUserActivity(
                    bucket,
                    _user,
                    scaledBalanceOf(_user),
                    IActivityRewardDistributor.Role.TRADER
                )
            {} catch {
                emit Errors.Log(Errors.TRADER_REWARD_DISTRIBUTOR_CALL_FAILED.selector);
            }
        }

        emit Burn(_user, _amount);
    }

    /**
     * @inheritdoc IDebtToken
     */
    function batchBurn(
        address[] memory _users,
        uint256[] memory _amounts,
        uint256 _index,
        uint256 _length
    ) external override onlyBucket {
        uint256[] memory amountsScaled = new uint256[](_length);
        uint256[] memory scaledBalances = new uint256[](_length);
        bool hasFeeDecreaser = address(feeDecreaser) != address(0);
        bool hasRewardDistributor = address(traderRewardDistributor) != address(0);

        for (uint256 i; i < _length; i++) {
            amountsScaled[i] = _amounts[i].rdiv(_index);
            if (hasFeeDecreaser) scaledBalances[i] = scaledBalanceOf(_users[i]);
        }

        if (hasFeeDecreaser) {
            //in this case the _index will be equal to the getNormalizedVariableDebt()
            try feeDecreaser.updateBonuses(_users, scaledBalances, address(bucket), _index) {} catch {
                emit Errors.Log(Errors.FEE_DECREASER_CALL_FAILED.selector);
            }
        }

        for (uint256 i; i < _length; i++) {
            if (amountsScaled[i] > 0) {
                _burn(_users[i], amountsScaled[i]);
                if (hasRewardDistributor) scaledBalances[i] = scaledBalanceOf(_users[i]);
            }
            emit Burn(_users[i], _amounts[i]);
        }

        if (hasRewardDistributor) {
            try
                traderRewardDistributor.updateUsersActivities(
                    bucket,
                    _users,
                    scaledBalances,
                    _length,
                    IActivityRewardDistributor.Role.TRADER
                )
            {} catch {
                emit Errors.Log(Errors.TRADER_REWARD_DISTRIBUTOR_CALL_FAILED.selector);
            }
        }
    }

    /**
     * @dev Locked transfer function to disable DebtToken transfers
     */
    function transfer(
        address,
        uint256
    ) public view virtual override(ERC20Upgradeable, IERC20Upgradeable) returns (bool) {
        _revert(Errors.TRANSFER_NOT_SUPPORTED.selector);
    }

    /**
     * @dev Locked approve function to disable DebtToken transfers
     */
    function approve(
        address,
        uint256
    ) public view virtual override(ERC20Upgradeable, IERC20Upgradeable) returns (bool) {
        _revert(Errors.APPROVE_NOT_SUPPORTED.selector);
    }

    /**
     * @dev Locked transferFrom function to disable DebtToken transfers
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public view virtual override(ERC20Upgradeable, IERC20Upgradeable) returns (bool) {
        _revert(Errors.TRANSFER_NOT_SUPPORTED.selector);
    }

    /**
     * @return decimals of the DebtToken according to bucket borrowedAsset.
     */
    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }

    /**
     * @dev Locked increaseAllowance function to disable DebtToken transfers
     */
    function increaseAllowance(address, uint256) public view virtual override returns (bool) {
        _revert(Errors.APPROVE_NOT_SUPPORTED.selector);
    }

    /**
     * @dev Locked decreaseAllowance function to disable DebtToken transfers
     */
    function decreaseAllowance(address, uint256) public view virtual override returns (bool) {
        _revert(Errors.APPROVE_NOT_SUPPORTED.selector);
    }

    /**
     * @dev Returns current borrower's debt (principal + %)
     * @param _user Address of borrower
     **/
    function balanceOf(address _user) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return super.balanceOf(_user).rmul(bucket.getNormalizedVariableDebt());
    }

    /**
     * @inheritdoc IDebtToken
     */
    function scaledBalanceOf(address _user) public view override returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @inheritdoc IDebtToken
     */
    function scaledTotalSupply() public view virtual override returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @dev Calculets the total supply of the debtToken.
     * It increments over blocks mining.
     * @return The current total supply of the debtToken.
     */
    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return super.totalSupply().rmul(bucket.getNormalizedVariableDebt());
    }

    /// @notice Interface checker
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IDebtToken).interfaceId || super.supportsInterface(_interfaceId);
    }
}
