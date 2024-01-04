pragma solidity 0.7.6;
import "./Future.sol";

/**
 * @title Main future abstraction contract for the stream futures
 * @author Gaspard Peduzzi
 * @notice Handles the stream future mecanisms
 * @dev Basis of all mecanisms for futures (registrations, period switch)
 */
abstract contract StreamFuture is Future {
    using SafeMathUpgradeable for uint256;

    uint256[] internal scaledTotals;

    /**
     * @notice Intializer
     * @param _controller the address of the controller
     * @param _ibt the address of the corresponding IBT
     * @param _periodDuration the length of the period (in days)
     * @param _platformName the name of the platform and tools
     * @param _deployerAddress the future deployer address
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
        scaledTotals.push();
        scaledTotals.push();
    }

    /**
     * @notice Sender registers an amount of IBT for the next period
     * @param _user address to register to the future
     * @param _amount amount of IBT to be registered
     * @dev called by the controller only
     */
    function register(address _user, uint256 _amount) public virtual override periodsActive nonReentrant {
        require(_amount > 0, "invalid amount to register");
        IRegistry registry = IRegistry(controller.getRegistryAddress());
        uint256 scaledInput =
            IAPWineMaths(registry.getMathsUtils()).getScaledInput(
                _amount,
                scaledTotals[getNextPeriodIndex()],
                ibt.balanceOf(address(this))
            );
        super.register(_user, scaledInput);
        scaledTotals[getNextPeriodIndex()] = scaledTotals[getNextPeriodIndex()].add(scaledInput);
    }

    /**
     * @notice Sender unregisters an amount of IBT for the next period
     * @param _user user addresss
     * @param _amount amount of IBT to be unregistered
     * @dev 0 unregisters all
     */
    function unregister(address _user, uint256 _amount) public virtual override nonReentrant {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to unregister");
        uint256 nextIndex = getNextPeriodIndex();
        require(registrations[_user].startIndex == nextIndex, "There is no ongoing registration for the next period");
        uint256 userScaledBalance = registrations[_user].scaledBalance;
        IRegistry registry = IRegistry(controller.getRegistryAddress());
        uint256 currentRegistered =
            IAPWineMaths(registry.getMathsUtils()).getActualOutput(
                userScaledBalance,
                scaledTotals[nextIndex],
                ibt.balanceOf(address(this))
            );
        uint256 scaledToUnregister;
        uint256 toRefund;
        if (_amount == 0) {
            scaledToUnregister = userScaledBalance;
            delete registrations[_user];
            toRefund = currentRegistered;
        } else {
            require(currentRegistered >= _amount, "Invalid amount to unregister");
            scaledToUnregister = (registrations[_user].scaledBalance.mul(_amount)).div(currentRegistered);
            registrations[_user].scaledBalance = registrations[_user].scaledBalance.sub(scaledToUnregister);
            toRefund = _amount;
        }
        scaledTotals[nextIndex] = scaledTotals[nextIndex].sub(scaledToUnregister);

        ibt.transfer(_user, toRefund);
    }

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() public virtual override nextPeriodAvailable periodsActive nonReentrant {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to start the next period");

        uint256 nextPeriodID = getNextPeriodIndex();
        registrationsTotals[nextPeriodID] = ibt.balanceOf(address(this));

        /* Yield */
        uint256 yield = ibt.balanceOf(address(futureVault)).sub(apwibt.totalSupply());
        if (yield > 0) assert(ibt.transferFrom(address(futureVault), address(futureWallet), yield));
        futureWallet.registerExpiredFuture(yield); // Yield deposit in the futureWallet contract

        /* Period Switch*/
        if (registrationsTotals[nextPeriodID] > 0) {
            apwibt.mint(address(this), registrationsTotals[nextPeriodID]); // Mint new apwIBTs
            ibt.transfer(address(futureVault), registrationsTotals[nextPeriodID]); // Send IBT to future for the new period
        }

        registrationsTotals.push();
        scaledTotals.push();

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
    function getRegisteredAmount(address _user) public view virtual override returns (uint256) {
        uint256 periodID = registrations[_user].startIndex;
        IRegistry registry = IRegistry(controller.getRegistryAddress());
        if (periodID == getNextPeriodIndex()) {
            return
                IAPWineMaths(registry.getMathsUtils()).getActualOutput(
                    registrations[_user].scaledBalance,
                    scaledTotals[periodID],
                    ibt.balanceOf(address(this))
                );
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
        IRegistry registry = IRegistry(controller.getRegistryAddress());

        return
            IAPWineMaths(registry.getMathsUtils()).getActualOutput(
                registrations[_user].scaledBalance,
                scaledTotals[registrations[_user].startIndex],
                registrationsTotals[registrations[_user].startIndex]
            );
    }

    /**
     * @notice Getter for yield that is generated by the user funds during the current period
     * @param _user user to check the unrealised yield of
     * @return the yield (amount of IBT) currently generated by the locked funds of the user
     */
    function getUnrealisedYield(address _user) public view override returns (uint256) {
        return
            (
                (ibt.balanceOf(address(futureVault)).sub(apwibt.totalSupply())).mul(
                    fyts[getNextPeriodIndex() - 1].balanceOf(_user)
                )
            )
                .div(fyts[getNextPeriodIndex() - 1].totalSupply());
    }
}
