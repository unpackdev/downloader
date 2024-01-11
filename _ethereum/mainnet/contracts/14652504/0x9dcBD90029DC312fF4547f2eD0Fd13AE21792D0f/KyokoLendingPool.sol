// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./CreditSystem.sol";
import "./IKToken.sol";
import "./KToken.sol";
import "./ILendingPool.sol";
import "./LendingPoolStorage.sol";
import "./ReserveLogic.sol";
import "./DataTypes.sol";
import "./ValidationLogic.sol";

/**
 * @dev kyoko ERC20 lending pool
 */
contract KyokoLendingPool is
    ILendingPool,
    LendingPoolStorage,
    AccessControlEnumerableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using SafeMathUpgradeable for uint256;

    bytes32 public constant LENDING_POOL_ADMIN =
        keccak256("LENDING_POOL_ADMIN");

    uint256 public constant LENDINGPOOL_REVISION = 0x0;

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    function _whenNotPaused() internal view {
        require(!_paused, "LP_IS_PAUSED");
    }

    CreditSystem public creditContract;

    /**
     * @dev only the lending pool admin can operate.
     */
    modifier onlyLendingPoolAdmin() {
        require(
            hasRole(LENDING_POOL_ADMIN, _msgSender()),
            "Only the lending pool admin has permission to do this operation"
        );
        _;
    }

    /**
     * @dev initialize lending pool with credit system
     */
    function initialize(address _creditContract) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        creditContract = CreditSystem(_creditContract);
    }

    /**
    * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    * - E.g. User deposits 100 USDT and gets in return 100 kUSDT
    * @param asset The address of the underlying asset to deposit
    * @param amount The amount to be deposited
    * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    *   is a different wallet
    **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external override whenNotPaused {
        DataTypes.ReserveData storage reserve = _reserves[asset];

        ValidationLogic.validateDeposit(reserve, amount);

        address kToken = reserve.kTokenAddress;
        reserve.updateState();
        reserve.updateInterestRates(asset, kToken, amount, 0);

        IERC20Upgradeable(asset).safeTransferFrom(msg.sender, kToken, amount);

        IKToken(kToken).mint(onBehalfOf, amount, reserve.liquidityIndex);

        emit Deposit(asset, msg.sender, onBehalfOf, amount);
    }

    /**
    * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent kTokens owned
    * E.g. User has 100 kUSDT, calls withdraw() and receives 100 USDT, burning the 100 kUSDT
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole kToken balance
    * @param to Address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    * @return The final amount withdrawn
    **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external override whenNotPaused returns (uint256) {
        DataTypes.ReserveData storage reserve = _reserves[asset];

        address kToken = reserve.kTokenAddress;
        uint256 userBalance = IKToken(kToken).balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        ValidationLogic.validateWithdraw(
            asset,
            amountToWithdraw,
            userBalance,
            _reserves
        );
        reserve.updateState();
        reserve.updateInterestRates(asset, kToken, 0, amountToWithdraw);
        IKToken(kToken).burn(
            msg.sender,
            to,
            amountToWithdraw,
            reserve.liquidityIndex
        );
        emit Withdraw(asset, msg.sender, to, amountToWithdraw);
        return amountToWithdraw;
    }

    /**
    * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
    * already had enough credit line, or he was given enough allowance by a credit delegator on the
    * corresponding debt token
    * - E.g. User borrows 100 USDT passing as `onBehalfOf` his own address, receiving the 100 USDT in his wallet
    *   and 100 variable debt tokens
    * @param asset The address of the underlying asset to borrow
    * @param amount The amount to be borrowed
    * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
    * calling the function if he wants to borrow against his own credit line, or the address of the credit delegator
    * if he has been given credit delegation allowance
    **/
    function borrow(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external override whenNotPaused {
        require(amount > 0, "BORROW_AMOUNT_LESS_THAN_ZERO");
        DataTypes.ReserveData storage reserve = _reserves[asset];
        _executeBorrow(
            ExecuteBorrowParams(
                asset,
                msg.sender,
                onBehalfOf,
                amount,
                reserve.kTokenAddress,
                true
            )
        );
    }

    /**
    * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
    * - E.g. User repays 100 USDT, burning 100 variable debt tokens of the `onBehalfOf` address
    * @param asset The address of the borrowed underlying asset previously borrowed
    * @param amount The amount to repay
    * - Send the value type(uint256).max in order to repay the whole debt for `asset`
    * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
    * user calling the function if he wants to reduce/remove his own debt, or the address of any other
    * other borrower whose debt should be removed
    * @return The final amount repaid
    **/
    function repay(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external override whenNotPaused returns (uint256) {
        DataTypes.ReserveData storage reserve = _reserves[asset];

        uint256 variableDebt = IERC20Upgradeable(
            reserve.variableDebtTokenAddress
        ).balanceOf(onBehalfOf);

        ValidationLogic.validateRepay(
            reserve,
            amount,
            onBehalfOf,
            variableDebt
        );

        uint256 paybackAmount = variableDebt;

        if (amount < paybackAmount) {
            paybackAmount = amount;
        }

        reserve.updateState();

        IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
            onBehalfOf,
            paybackAmount,
            reserve.variableBorrowIndex
        );

        address kToken = reserve.kTokenAddress;
        reserve.updateInterestRates(asset, kToken, paybackAmount, 0);

        IERC20Upgradeable(asset).safeTransferFrom(
            msg.sender,
            kToken,
            paybackAmount
        );

        IKToken(kToken).handleRepayment(msg.sender, paybackAmount);

        emit Repay(asset, onBehalfOf, msg.sender, paybackAmount);

        return paybackAmount;
    }

    /**
    * @dev Initializes a reserve, activating it, assigning an kToken and debt tokens and an
    * interest rate strategy
    * - Only callable by the LendingPoolAdmin role
    * @param asset The address of the underlying asset of the reserve
    * @param kTokenAddress The address of the kToken that will be assigned to the reserve
    * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
    * @param interestRateStrategyAddress The address of the interest rate strategy contract
    * @param reserveDecimals The decimals of the underlying asset of the reserve
    * @param reserveFactor The factor of the underlying asset of the reserve
    **/
    function initReserve(
        address asset,
        address kTokenAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress,
        uint8 reserveDecimals,
        uint16 reserveFactor
    ) external override onlyLendingPoolAdmin {
        require(AddressUpgradeable.isContract(asset), "NOT_CONTRACT");

        _reserves[asset].init(
            kTokenAddress,
            variableDebtAddress,
            interestRateStrategyAddress
        );

        _addReserveToList(asset, reserveDecimals, reserveFactor);
        emit InitReserve(asset, kTokenAddress, variableDebtAddress, interestRateStrategyAddress, reserveDecimals, reserveFactor);
    }

    function _addReserveToList(
        address asset,
        uint8 reserveDecimals,
        uint16 reserveFactor
    ) internal {
        uint256 reservesCount = _reservesCount;

        bool reserveAlreadyAdded = _reserves[asset].id != 0 ||
            _reservesList[0] == asset;

        if (!reserveAlreadyAdded) {
            _reserves[asset].id = uint8(reservesCount);
            _reserves[asset].decimals = uint8(reserveDecimals);
            _reserves[asset].factor = uint16(reserveFactor);
            _reservesList[reservesCount] = asset;

            _reservesCount = reservesCount + 1;
        }
    }

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        override
        returns (uint256)
    {
        return _reserves[asset].getNormalizedDebt();
    }

    function paused() external view override returns (bool) {
        return _paused;
    }

    /**
    * @dev Set the _pause state of a reserve
    * - Only callable by the LendingPoolAdmin role
    * @param val `true` to pause the reserve, `false` to un-pause it
    */
    function setPause(bool val) external override onlyLendingPoolAdmin {
        _paused = val;
        if (_paused) {
            emit Paused();
        } else {
            emit Unpaused();
        }
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        address kTokenAddress;
        bool releaseUnderlying;
    }

    function _executeBorrow(ExecuteBorrowParams memory vars) internal {
        DataTypes.ReserveData storage reserve = _reserves[vars.asset];

        (
            uint256 totalDebtInWEI,
            uint256 availableBorrowsInWEI
        ) = getUserAccountData(vars.user);

        ValidationLogic.validateBorrow(
            availableBorrowsInWEI,
            reserve,
            vars.amount
        );

        reserve.updateState();

        IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
            vars.user,
            vars.onBehalfOf,
            vars.amount,
            reserve.variableBorrowIndex
        );

        reserve.updateInterestRates(
            vars.asset,
            vars.kTokenAddress,
            0,
            vars.releaseUnderlying ? vars.amount : 0
        );

        if (vars.releaseUnderlying) {
            IKToken(vars.kTokenAddress).transferUnderlyingTo(
                vars.user,
                vars.amount
            );
        }

        emit Borrow(
            vars.asset,
            vars.user,
            vars.onBehalfOf,
            vars.amount,
            reserve.currentVariableBorrowRate
        );
    }

    /**
    * @dev Returns the state and configuration of the reserve
    * @param asset The address of the underlying asset of the reserve
    * @return The state of the reserve
    **/
    function getReserveData(address asset)
        external
        view
        override
        returns (DataTypes.ReserveData memory)
    {
        return _reserves[asset];
    }

    /**
    * @dev Returns the user account data across all the reserves
    * @param user The address of the user
    * @return totalDebtInWEI the total debt in WEI of the user
    * @return availableBorrowsInWEI the borrowing power left of the user
    **/
    function getUserAccountData(address user)
        public
        view
        override
        returns (uint256 totalDebtInWEI, uint256 availableBorrowsInWEI)
    {
        totalDebtInWEI = GenericLogic.calculateUserAccountData(
            user,
            _reserves,
            _reservesList,
            _reservesCount
        );
        uint256 creditLine = creditContract.getG2GCreditLine(user);

        availableBorrowsInWEI = totalDebtInWEI >= creditLine
            ? 0
            : creditLine.sub(totalDebtInWEI);
    }

    /**
    * @dev Updates the address of the interest rate strategy contract
    * - Only callable by the LendingPoolAdmin role
    * @param asset The address of the underlying asset of the reserve
    * @param rateStrategyAddress The address of the interest rate strategy contract
    **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external override onlyLendingPoolAdmin {
        _reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
    }

    /**
    * @dev Returns the normalized income per unit of asset
    * @param asset The address of the underlying asset of the reserve
    * @return The reserve's normalized income
    */
    function getReserveNormalizedIncome(address asset)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _reserves[asset].getNormalizedIncome();
    }

    /**
    * @dev Returns the list of the initialized reserves
    **/
    function getReservesList()
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory _activeReserves = new address[](_reservesCount);

        for (uint256 i = 0; i < _reservesCount; i++) {
            _activeReserves[i] = _reservesList[i];
        }
        return _activeReserves;
    }

    /**
    * @dev Sets the reserve factor of the reserve
    * @param asset The address of the underlying asset in reserve
    * @param reserveFactor The reserve factor
    **/
    function setReserveFactor(address asset, uint16 reserveFactor)
        external
        onlyLendingPoolAdmin
    {
        DataTypes.ReserveData storage reserve = _reserves[asset];
        reserve.setReserveFactor(reserveFactor);
        emit ReserveFactorChanged(asset, reserveFactor);
    }

    /**
    * @dev Sets the active state of the reserve
    * @param asset The address of the underlying asset in reserve
    * @param active The active state
    **/
    function setActive(address asset, bool active)
        external
        onlyLendingPoolAdmin
    {
        DataTypes.ReserveData storage reserve = _reserves[asset];
        reserve.setActive(active);
        emit ReserveActiveChanged(asset, active);
    }

    /**
    * @dev Gets the active state of the reserve
    * @param asset The address of the underlying asset in reserve
    * @return The active state
    **/
    function getActive(address asset) external view override returns (bool) {
        DataTypes.ReserveData storage reserve = _reserves[asset];
        return reserve.getActive();
    }

    /**
    * @dev Sets the credit system address of the lending pool
    * @param _creditContract The address of the underlying asset in reserve
    * - Only callable by the LendingPoolAdmin role
    **/
    function setCreditStrategy(address _creditContract)
        external
        override
        onlyLendingPoolAdmin
    {
        creditContract = CreditSystem(_creditContract);
        emit CreditStrategyChanged(_creditContract);
    }

    /**
    * @dev Gets the credit system address of the lending pool
    **/
    function getCreditStrategy() external view override returns (address) {
        return address(creditContract);
    }
}
