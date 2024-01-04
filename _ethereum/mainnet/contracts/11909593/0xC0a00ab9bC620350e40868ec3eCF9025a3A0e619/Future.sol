pragma solidity 0.7.6;

import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IProxyFactory.sol";
import "./IFutureYieldToken.sol";
import "./IAPWineMath.sol";

import "./IAPWineIBT.sol";
import "./IFutureWallet.sol";

import "./IController.sol";
import "./IFutureVault.sol";
import "./ILiquidityGauge.sol";
import "./IRegistry.sol";

/**
 * @title Main future abstraction contract
 * @notice Handles the future mechanisms
 * @dev Basis of all mecanisms for futures (registrations, period switch)
 */
abstract contract Future is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    /* Structs */
    struct Registration {
        uint256 startIndex;
        uint256 scaledBalance;
    }

    uint256[] internal registrationsTotals;

    /* ACR */
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FUTURE_DEPLOYER = keccak256("FUTURE_DEPLOYER");

    /* State variables */
    mapping(address => uint256) internal lastPeriodClaimed;
    mapping(address => Registration) internal registrations;
    IFutureYieldToken[] public fyts;

    /* External contracts */
    IFutureVault internal futureVault;
    IFutureWallet internal futureWallet;
    ILiquidityGauge internal liquidityGauge;
    ERC20 internal ibt;
    IAPWineIBT internal apwibt;
    IController internal controller;

    /* Settings */
    uint256 public PERIOD_DURATION;
    string public PLATFORM_NAME;

    bool public PAUSED;
    bool public WITHRAWALS_PAUSED;
    bool public DEPOSITS_PAUSED;

    /* Events */
    event UserRegistered(address _userAddress, uint256 _amount, uint256 _periodIndex);
    event NewPeriodStarted(uint256 _newPeriodIndex, address _fytAddress);
    event FutureVaultSet(address _futureVault);
    event FutureWalletSet(address _futureWallet);
    event LiquidityGaugeSet(address _liquidityGauge);
    event FundsWithdrawn(address _user, uint256 _amount);
    event PeriodsPaused();
    event PeriodsResumed();
    event DepositsPaused();
    event DepositsResumed();
    event WithdrawalsPaused();
    event WithdrawalsResumed();
    event APWIBTSet(address _apwibt);
    event LiquidityTransfersPaused();
    event LiquidityTransfersResumed();

    /* Modifiers */
    modifier nextPeriodAvailable() {
        uint256 controllerDelay = controller.STARTING_DELAY();
        require(
            controller.getNextPeriodStart(PERIOD_DURATION) < block.timestamp.add(controllerDelay),
            "Next period start range not reached yet"
        );
        _;
    }

    modifier periodsActive() {
        require(!PAUSED, "New periods are currently paused");
        _;
    }

    modifier withdrawalsEnabled() {
        require(!WITHRAWALS_PAUSED, "withdrawals are disabled");
        _;
    }

    modifier depositsEnabled() {
        require(!DEPOSITS_PAUSED, "desposits are disabled");
        _;
    }

    /* Initializer */
    /**
     * @notice Intializer
     * @param _controller the address of the controller
     * @param _ibt the address of the corresponding IBT
     * @param _periodDuration the length of the period (in days)
     * @param _platformName the name of the platform and tools
     * @param _admin the address of the ACR admin
     */
    function initialize(
        address _controller,
        address _ibt,
        uint256 _periodDuration,
        string memory _platformName,
        address _deployerAddress,
        address _admin
    ) public virtual initializer {
        controller = IController(_controller);
        ibt = ERC20(_ibt);
        PERIOD_DURATION = _periodDuration * (1 days);
        PLATFORM_NAME = _platformName;
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ADMIN_ROLE, _admin);
        _setupRole(CONTROLLER_ROLE, _controller);
        _setupRole(FUTURE_DEPLOYER, _deployerAddress);

        registrationsTotals.push();
        registrationsTotals.push();
        fyts.push();

        IRegistry registry = IRegistry(controller.getRegistryAddress());

        string memory ibtSymbol = controller.getFutureIBTSymbol(ibt.symbol(), _platformName, PERIOD_DURATION);
        bytes memory payload =
            abi.encodeWithSignature(
                "initialize(string,string,uint8,address)",
                ibtSymbol,
                ibtSymbol,
                ibt.decimals(),
                address(this)
            );
        apwibt = IAPWineIBT(
            IProxyFactory(registry.getProxyFactoryAddress()).deployMinimal(registry.getAPWineIBTLogicAddress(), payload)
        );
        emit APWIBTSet(address(apwibt));
    }

    /* Period functions */

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() public virtual;

    /**
     * @notice Sender registers an amount of IBT for the next period
     * @param _user address to register to the future
     * @param _amount amount of IBT to be registered
     * @dev called by the controller only
     */
    function register(address _user, uint256 _amount) public virtual periodsActive depositsEnabled periodsActive {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to register");
        uint256 nextIndex = getNextPeriodIndex();
        if (registrations[_user].scaledBalance == 0) {
            // User has no record
            _register(_user, _amount);
        } else {
            if (registrations[_user].startIndex == nextIndex) {
                // User has already an existing registration for the next period
                registrations[_user].scaledBalance = registrations[_user].scaledBalance.add(_amount);
            } else {
                // User had an unclaimed registation from a previous period
                _claimAPWIBT(_user);
                _register(_user, _amount);
            }
        }
        emit UserRegistered(_user, _amount, nextIndex);
    }

    function _register(address _user, uint256 _initialScaledBalance) internal virtual {
        registrations[_user] = Registration({startIndex: getNextPeriodIndex(), scaledBalance: _initialScaledBalance});
    }

    /**
     * @notice Sender unregisters an amount of IBT for the next period
     * @param _user user address
     * @param _amount amount of IBT to be unregistered
     */
    function unregister(address _user, uint256 _amount) public virtual;

    /* Claim functions */

    /**
     * @notice Send the user their owed FYT (and apwIBT if there are some claimable)
     * @param _user address of the user to send the FYT to
     */
    function claimFYT(address _user) public virtual nonReentrant {
        require(hasClaimableFYT(_user), "No FYT claimable for this address");
        if (hasClaimableAPWIBT(_user)) _claimAPWIBT(_user);
        else _claimFYT(_user);
    }

    function _claimFYT(address _user) internal virtual {
        uint256 nextIndex = getNextPeriodIndex();
        for (uint256 i = lastPeriodClaimed[_user] + 1; i < nextIndex; i++) {
            claimFYTforPeriod(_user, i);
        }
    }

    function claimFYTforPeriod(address _user, uint256 _periodIndex) internal virtual {
        assert((lastPeriodClaimed[_user] + 1) == _periodIndex);
        assert(_periodIndex < getNextPeriodIndex());
        assert(_periodIndex != 0);
        lastPeriodClaimed[_user] = _periodIndex;
        fyts[_periodIndex].transfer(_user, apwibt.balanceOf(_user));
    }

    function _claimAPWIBT(address _user) internal virtual {
        uint256 nextIndex = getNextPeriodIndex();
        uint256 claimableAPWIBT = getClaimableAPWIBT(_user);

        if (_hasOnlyClaimableFYT(_user)) _claimFYT(_user);
        apwibt.transfer(_user, claimableAPWIBT);

        for (uint256 i = registrations[_user].startIndex; i < nextIndex; i++) {
            // get unclaimed fyt
            fyts[i].transfer(_user, claimableAPWIBT);
        }

        lastPeriodClaimed[_user] = nextIndex - 1;
        delete registrations[_user];
    }

    /**
     * @notice Sender unlocks the locked funds corresponding to their apwIBT holding
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev will require a transfer of FYT of the ongoing period corresponding to the funds unlocked
     */
    function withdrawLockFunds(address _user, uint256 _amount) public virtual nonReentrant withdrawalsEnabled {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to withdraw locked funds");
        require((_amount > 0) && (_amount <= apwibt.balanceOf(_user)), "Invalid amount");
        if (hasClaimableAPWIBT(_user)) {
            _claimAPWIBT(_user);
        } else if (hasClaimableFYT(_user)) {
            _claimFYT(_user);
        }

        uint256 unlockableFunds = getUnlockableFunds(_user);
        uint256 unrealisedYield = getUnrealisedYield(_user);

        uint256 fundsToBeUnlocked = _amount.mul(unlockableFunds).div(apwibt.balanceOf(_user));
        uint256 yieldToBeUnlocked = _amount.mul(unrealisedYield).div(apwibt.balanceOf(_user));

        uint256 yieldToBeRedeemed;
        if (PAUSED) {
            yieldToBeRedeemed = yieldToBeUnlocked;
        } else {
            yieldToBeRedeemed = (yieldToBeUnlocked.mul(controller.getUnlockYieldFactor(PERIOD_DURATION))).div(1000);
        }

        ibt.transferFrom(address(futureVault), _user, fundsToBeUnlocked.add(yieldToBeRedeemed));

        uint256 treasuryFee = unrealisedYield.sub(yieldToBeRedeemed);
        if (treasuryFee > 0) {
            ibt.transferFrom(
                address(futureVault),
                IRegistry(controller.getRegistryAddress()).getTreasuryAddress(),
                treasuryFee
            );
        }

        apwibt.burnFrom(_user, _amount);
        fyts[getNextPeriodIndex() - 1].burnFrom(_user, _amount);
        emit FundsWithdrawn(_user, _amount);
    }

    /* Utilitary functions */

    function deployFutureYieldToken(uint256 _internalPeriodID) internal returns (address) {
        IRegistry registry = IRegistry(controller.getRegistryAddress());
        string memory tokenDenomination = controller.getFYTSymbol(apwibt.symbol(), PERIOD_DURATION);
        bytes memory payload =
            abi.encodeWithSignature(
                "initialize(string,string,uint8,uint256,address)",
                tokenDenomination,
                tokenDenomination,
                ibt.decimals(),
                _internalPeriodID,
                address(this)
            );
        IFutureYieldToken newToken =
            IFutureYieldToken(
                IProxyFactory(registry.getProxyFactoryAddress()).deployMinimal(registry.getFYTLogicAddress(), payload)
            );
        fyts.push(newToken);
        newToken.mint(address(this), apwibt.totalSupply());
        return address(newToken);
    }

    /* Getters */

    /**
     * @notice Check if a user has unclaimed FYT
     * @param _user the user to check
     * @return true if the user can claim some FYT, false otherwise
     */
    function hasClaimableFYT(address _user) public view returns (bool) {
        return hasClaimableAPWIBT(_user) || _hasOnlyClaimableFYT(_user);
    }

    function _hasOnlyClaimableFYT(address _user) internal view returns (bool) {
        return lastPeriodClaimed[_user] != 0 && lastPeriodClaimed[_user] < getNextPeriodIndex() - 1;
    }

    /**
     * @notice Check if a user has IBT not claimed
     * @param _user the user to check
     * @return true if the user can claim some IBT, false otherwise
     */
    function hasClaimableAPWIBT(address _user) public view returns (bool) {
        return (registrations[_user].startIndex < getNextPeriodIndex()) && (registrations[_user].scaledBalance > 0);
    }

    /**
     * @notice Getter for next period index
     * @return next period index
     * @dev index starts at 1
     */
    function getNextPeriodIndex() public view virtual returns (uint256) {
        return registrationsTotals.length - 1;
    }

    /**
     * @notice Getter for the amount of apwIBT that the user can claim
     * @param _user user to check the check the claimable apwIBT of
     * @return the amount of apwIBT claimable by the user
     */
    function getClaimableAPWIBT(address _user) public view virtual returns (uint256);

    /**
     * @notice Getter for the amount of FYT that the user can claim for a certain period
     * @param _user the user to check the claimable FYT of
     * @param _periodID period ID to check the claimable FYT of
     * @return the amount of FYT claimable by the user for this period ID
     */
    function getClaimableFYTForPeriod(address _user, uint256 _periodID) public view virtual returns (uint256) {
        if (
            _periodID >= getNextPeriodIndex() ||
            registrations[_user].startIndex == 0 ||
            registrations[_user].scaledBalance == 0 ||
            registrations[_user].startIndex > _periodID
        ) {
            return 0;
        } else {
            return getClaimableAPWIBT(_user);
        }
    }

    /**
     * @notice Getter for user IBT amount that is unlockable
     * @param _user the user to unlock the IBT from
     * @return the amount of IBT the user can unlock
     */
    function getUnlockableFunds(address _user) public view virtual returns (uint256) {
        return apwibt.balanceOf(_user);
    }

    /**
     * @notice Getter for user registered amount
     * @param _user the user to return the registered funds of
     * @return the registered amount, 0 if no registrations
     * @dev the registration can be older than the next period
     */
    function getRegisteredAmount(address _user) public view virtual returns (uint256);

    /**
     * @notice Getter for yield that is generated by the user funds during the current period
     * @param _user the user to check the unrealized yield of
     * @return the yield (amount of IBT) currently generated by the locked funds of the user
     */
    function getUnrealisedYield(address _user) public view virtual returns (uint256);

    /**
     * @notice Getter for controller address
     * @return the controller address
     */
    function getControllerAddress() public view returns (address) {
        return address(controller);
    }

    /**
     * @notice Getter for future wallet address
     * @return future wallet address
     */
    function getFutureVaultAddress() public view returns (address) {
        return address(futureVault);
    }

    /**
     * @notice Getter for futureWallet address
     * @return futureWallet address
     */
    function getFutureWalletAddress() public view returns (address) {
        return address(futureWallet);
    }

    /**
     * @notice Getter for liquidity gauge address
     * @return liquidity gauge address
     */
    function getLiquidityGaugeAddress() public view returns (address) {
        return address(liquidityGauge);
    }

    /**
     * @notice Getter for the IBT address
     * @return IBT address
     */
    function getIBTAddress() public view returns (address) {
        return address(ibt);
    }

    /**
     * @notice Getter for future apwIBT address
     * @return apwIBT address
     */
    function getAPWIBTAddress() public view returns (address) {
        return address(apwibt);
    }

    /**
     * @notice Getter for FYT address of a particular period
     * @param _periodIndex period index
     * @return FYT address
     */
    function getFYTofPeriod(uint256 _periodIndex) public view returns (address) {
        require(_periodIndex < getNextPeriodIndex(), "No FYT for this period yet");
        return address(fyts[_periodIndex]);
    }

    /* Admin function */

    /**
     * @notice Pause registrations and the creation of new periods
     */
    function pausePeriods() public {
        require(
            (hasRole(ADMIN_ROLE, msg.sender) || hasRole(CONTROLLER_ROLE, msg.sender)),
            "Caller is not allowed to pause future"
        );
        PAUSED = true;
        emit PeriodsPaused();
    }

    /**
     * @notice Resume registrations and the creation of new periods
     */
    function resumePeriods() public {
        require(
            (hasRole(ADMIN_ROLE, msg.sender) || hasRole(CONTROLLER_ROLE, msg.sender)),
            "Caller is not allowed to resume future"
        );
        PAUSED = false;
        emit PeriodsResumed();
    }

    /**
     * @notice Pause withdrawals
     */
    function pauseWithdrawals() public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to pause withdrawals");
        WITHRAWALS_PAUSED = true;
        emit WithdrawalsPaused();
    }

    /**
     * @notice Resume withdrawals
     */
    function resumeWithdrawals() public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to resume withdrawals");
        WITHRAWALS_PAUSED = false;
        emit WithdrawalsResumed();
    }

    /**
     * @notice Pause deposits
     */
    function pauseDeposits() public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to pause deposits");
        DEPOSITS_PAUSED = true;
        emit DepositsPaused();
    }

    /**
     * @notice Resume deposits
     */
    function resumeDeposits() public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to resume deposits");
        DEPOSITS_PAUSED = false;
        emit DepositsResumed();
    }

    /**
     * @notice Pause liquidity transfers
     */
    function pauseLiquidityTransfers() public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to pause liquidity transfer");
        apwibt.pause();
        emit LiquidityTransfersPaused();
    }

    /**
     * @notice Resume liquidity transfers
     */
    function resumeLiquidityTransfers() public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to resume liquidity transfer");
        apwibt.unpause();
        emit LiquidityTransfersResumed();
    }

    /**
     * @notice Set future wallet address
     * @param _futureVault the address of the new future wallet
     * @dev needs corresponding permissions for sender
     */
    function setFutureVault(address _futureVault) public {
        require(hasRole(FUTURE_DEPLOYER, msg.sender), "Caller is not allowed to set the future vault address");
        futureVault = IFutureVault(_futureVault);
        emit FutureVaultSet(_futureVault);
    }

    /**
     * @notice Set futureWallet address
     * @param _futureWallet the address of the new futureWallet
     * @dev needs corresponding permissions for sender
     */
    function setFutureWallet(address _futureWallet) public {
        require(hasRole(FUTURE_DEPLOYER, msg.sender), "Caller is not allowed to set the future wallet address");
        futureWallet = IFutureWallet(_futureWallet);
        emit FutureWalletSet(_futureWallet);
    }

    /**
     * @notice Set liquidity gauge address
     * @param _liquidityGauge the address of the new liquidity gauge
     * @dev needs corresponding permissions for sender
     */
    function setLiquidityGauge(address _liquidityGauge) public {
        require(hasRole(FUTURE_DEPLOYER, msg.sender), "Caller is not allowed to set the liquidity gauge address");
        liquidityGauge = ILiquidityGauge(_liquidityGauge);
        emit LiquidityGaugeSet(_liquidityGauge);
    }

    /**
     * @notice Set apwibt address
     * @param _apwibt the address of the new apwibt
     * @dev used only for exceptional purpose
     */
    function setAPWIBT(address _apwibt) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to set the apwibt");
        apwibt = IAPWineIBT(_apwibt);
        emit APWIBTSet(_apwibt);
    }
}
