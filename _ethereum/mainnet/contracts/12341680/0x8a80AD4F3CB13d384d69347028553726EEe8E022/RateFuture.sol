pragma solidity 0.7.6;

import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";

import "./Future.sol";

/**
 * @title Main future abstraction contract for the rate futures
 * @notice Handles the rates future mecanisms
 * @dev Basis of all mecanisms for futures (registrations, period switch)
 */
abstract contract RateFuture is Future {
    using SafeMathUpgradeable for uint256;

    uint256[] private IBTRates;

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
    ) public virtual override initializer {
        super.initialize(_controller, _ibt, _periodDuration, _platformName, _deployerAddress, _admin);
        IBTRates.push(getIBTRate());
        IBTRates.push();
    }

    /**
     * @notice Sender unregisters an amount of IBT for the next period
     * @param _user user addresss
     * @param _amount amount of IBT to be unregistered
     * @dev 0 unregisters all
     */
    function unregister(address _user, uint256 _amount) public virtual override nonReentrant withdrawalsEnabled {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to unregister");

        uint256 nextIndex = getNextPeriodIndex();
        require(registrations[_user].startIndex == nextIndex, "The is not ongoing registration for the next period");

        uint256 currentRegistered = registrations[_user].scaledBalance;
        uint256 toRefund;

        if (_amount == 0) {
            delete registrations[_user];
            toRefund = currentRegistered;
        } else {
            require(currentRegistered >= _amount, "Invalid amount to unregister");
            registrations[_user].scaledBalance = registrations[_user].scaledBalance.sub(_amount);
            toRefund = _amount;
        }

        ibt.transfer(_user, toRefund);
    }

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() public virtual override nextPeriodAvailable periodsActive nonReentrant {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to start the next period");

        uint256 nextPeriodID = getNextPeriodIndex();
        uint256 currentRate = getIBTRate();

        IBTRates[nextPeriodID] = currentRate;
        registrationsTotals[nextPeriodID] = ibt.balanceOf(address(this));

        /* Yield */
        uint256 oldIBTBalanceForUnderlying = (10**ibt.decimals()).mul(apwibt.totalSupply()).div(IBTRates[nextPeriodID - 1]);
        uint256 newIBTBalanceForUnderlying = (10**ibt.decimals()).mul(apwibt.totalSupply()).div(currentRate);
        uint256 yield = oldIBTBalanceForUnderlying.sub(newIBTBalanceForUnderlying);
        futureWallet.registerExpiredFuture(yield); // Yield deposit in the futureWallet contract
        if (yield > 0) assert(ibt.transferFrom(address(futureVault), address(futureWallet), yield));

        /* Period Switch*/
        if (registrationsTotals[nextPeriodID] > 0) {
            apwibt.mint(
                address(this),
                registrationsTotals[nextPeriodID].mul(IBTRates[nextPeriodID]).div(10**ibt.decimals())
            ); // Mint new apwIBTs
            ibt.transfer(address(futureVault), registrationsTotals[nextPeriodID]); // Send IBT to future for the new period
        }

        registrationsTotals.push();
        IBTRates.push();

        /* Future Yield Token */
        address fytAddress = deployFutureYieldToken(nextPeriodID);
        emit NewPeriodStarted(nextPeriodID, fytAddress);
    }

    /**
     * @notice Getter for user registered amount
     * @param _user user to return the registered funds of
     * @return the registered amount, 0 if no registrations
     * @dev the registration can be older than the next period
     */
    function getRegisteredAmount(address _user) public view override returns (uint256) {
        uint256 periodID = registrations[_user].startIndex;
        if (periodID == getNextPeriodIndex()) {
            return registrations[_user].scaledBalance;
        } else {
            return 0;
        }
    }

    /**
     * @notice Getter for the amount of apwIBT that the user can claim
     * @param _user user to check the check the claimable apwIBT of
     * @return the amount of apwIBT claimable by the user
     */
    function getClaimableAPWIBT(address _user) public view override returns (uint256) {
        if (!hasClaimableAPWIBT(_user)) return 0;
        return registrations[_user].scaledBalance.mul(IBTRates[registrations[_user].startIndex]).div(10**ibt.decimals());
    }

    /**
     * @notice Getter for user IBT amount that is unlockable
     * @param _user user to unlock the IBT from
     * @return the amount of IBT the user can unlock
     */
    function getUnlockableFunds(address _user) public view override returns (uint256) {
        return super.getUnlockableFunds(_user).mul(10**ibt.decimals()).div(getIBTRate());
    }

    /**
     * @notice Getter for yield that is generated by the user funds during the current period
     * @param _user user to check the unrealised yield of
     * @return the yield (amount of IBT) currently generated by the locked funds of the user
     */
    function getUnrealisedYield(address _user) public view override returns (uint256) {
        uint256 initialTotalUserDeposit =
            (apwibt.balanceOf(_user)).mul(10**ibt.decimals()).div(IBTRates[getNextPeriodIndex() - 1]);
        return initialTotalUserDeposit.sub(getUnlockableFunds(_user));
    }

    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view virtual returns (uint256);

    function forceSetRegisteredBalance(address _user, uint256 _amount) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to fix");
        registrations[_user].scaledBalance = _amount;
    }
}
