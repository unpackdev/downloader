pragma solidity 0.7.6;

import "./EnumerableSetUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";

import "./AccessControlUpgradeable.sol";
import "./IFutureYieldToken.sol";
import "./IFuture.sol";
import "./IRegistry.sol";

import "./IAPWineNaming.sol";
import "./SafeMathUpgradeable.sol";

/**
 * @title Controller contract
 * @notice The controller dictates the future mechanisms and serves as an interface for main user interaction with futures
 */
contract Controller is Initializable, AccessControlUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeMathUpgradeable for uint256;

    /* ACR Roles*/
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /* Attributes */

    IRegistry public registry;
    mapping(uint256 => uint256) private nextPeriodSwitchByDuration;
    mapping(uint256 => uint256) private unlockClaimableFactorByDuration; // represented as x/1000

    EnumerableSetUpgradeable.UintSet private durations;
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private futuresByDuration;
    mapping(uint256 => uint256) private periodIndexByDurations;

    EnumerableSetUpgradeable.AddressSet private pausedFutures;

    /* Events */

    event PlatformRegistered(address _platformControllerAddress);
    event PlatformUnregistered(address _platformControllerAddress);
    event NextPeriodSwitchSet(uint256 _periodDuration, uint256 _nextSwitchTimestamp);
    event FutureRegistered(address _newFutureAddress);
    event FutureUnregistered(address _future);
    event NewUnlockClaimableFactor(uint256 _periodDuration, uint256 _newYieldUnlockFactor);
    event StartingDelaySet(uint256 _startingDelay);

    /* PlatformController Settings */
    uint256 public STARTING_DELAY;

    /* Modifiers */

    modifier futureIsValid(address _future) {
        require(registry.isRegisteredFuture(_future), "incorrect future address");
        _;
    }

    /* Initializer */

    /**
     * @notice Initializer of the Controller contract
     * @param _admin the address of the admin
     */
    function initialize(address _admin, address _registry) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ADMIN_ROLE, _admin);
        registry = IRegistry(_registry);
    }

    /**
     * @notice Change the delay for starting a new period
     * @param _startingDelay the new delay (+-) to start the next period
     */
    function setPeriodStartingDelay(uint256 _startingDelay) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        STARTING_DELAY = _startingDelay;
        emit StartingDelaySet(_startingDelay);
    }

    /**
     * @notice Set the next period switch timestamp for the future with corresponding duration
     * @param _periodDuration the period duration
     * @param _nextPeriodTimestamp the next period switch timestamp
     */
    function setNextPeriodSwitchTimestamp(uint256 _periodDuration, uint256 _nextPeriodTimestamp) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to set next period timestamp");
        nextPeriodSwitchByDuration[_periodDuration] = _nextPeriodTimestamp;
        emit NextPeriodSwitchSet(_periodDuration, _nextPeriodTimestamp);
    }

    /**
     * @notice Set a new factor for the portion of the yield that is claimable when withdrawing funds during an ongoing period
     * @param _periodDuration the duration of the periods
     * @param _claimableYieldFactor the portion of the yield that is claimable
     */
    function setUnlockClaimableFactor(uint256 _periodDuration, uint256 _claimableYieldFactor) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to set the unlock yield factor");
        unlockClaimableFactorByDuration[_periodDuration] = _claimableYieldFactor;
        emit NewUnlockClaimableFactor(_periodDuration, _claimableYieldFactor);
    }

    /* User Methods */

    /**
     * @notice Register an amount of IBT from the sender to the corresponding future
     * @param _future the address of the future to be registered to
     * @param _amount the amount to register
     */
    function register(address _future, uint256 _amount) public futureIsValid(_future) {
        IFuture(_future).register(msg.sender, _amount);
        require(ERC20(IFuture(_future).getIBTAddress()).transferFrom(msg.sender, _future, _amount), "invalid amount");
    }

    /**
     * @notice Unregister an amount of IBT from the sender to the corresponding future
     * @param _future the address of the future to be unregistered from
     * @param _amount the amount to unregister
     */
    function unregister(address _future, uint256 _amount) public futureIsValid(_future) {
        IFuture(_future).unregister(msg.sender, _amount);
    }

    /**
     * @notice Withdraw deposited funds from APWine
     * @param _future the address of the future to withdraw the IBT from
     * @param _amount the amount to withdraw
     */
    function withdrawLockFunds(address _future, uint256 _amount) public futureIsValid(_future) {
        IFuture(_future).withdrawLockFunds(msg.sender, _amount);
    }

    /**
     * @notice Claim FYT of the msg.sender
     * @param _future the future from which to claim the FYT
     */
    function claimFYT(address _future) public futureIsValid(_future) {
        IFuture(_future).claimFYT(msg.sender);
    }

    /**
     * @notice Register the sender to the corresponding platformController
     * @param _user the address of the user
     * @param futuresAddresses the addresses of the futures to claim the FYT from
     */
    function claimSelectedYield(address _user, address[] memory futuresAddresses) public {
        for (uint256 i = 0; i < futuresAddresses.length; i++) {
            require(registry.isRegisteredFuture(futuresAddresses[i]), "Incorrect future address");
            IFuture(futuresAddresses[i]).claimFYT(_user);
        }
    }

    /* User Getter */
    /**
     * @notice Get the list of futures from which a user can claim FYT
     * @param _user the user to check
     */
    function getFuturesWithClaimableFYT(address _user) external view returns (address[] memory) {
        address[] memory selectedFutures = new address[](registry.futureCount());
        uint8 index = 0;
        for (uint256 i = 0; i < registry.futureCount(); i++) {
            if (IFuture(registry.getFutureAt(i)).hasClaimableFYT(_user)) {
                selectedFutures[i] = registry.getFutureAt(i);
                index += 1;
            }
        }
        return selectedFutures;
    }

    /* Getter */

    /**
     * @notice Getter for the registry address of the protocol
     * @return the address of the protocol registry
     */
    function getRegistryAddress() external view returns (address) {
        return address(registry);
    }

    /**
     * @notice Getter for the symbol of the APWine IBT of one future
     * @param _ibtSymbol the IBT of the external protocol
     * @param _platform the external protocol name
     * @param _periodDuration the duration of the periods for the future
     * @return the generated symbol of the APWine IBT
     */
    function getFutureIBTSymbol(
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) public view returns (string memory) {
        return IAPWineNaming(registry.getNamingUtils()).genIBTSymbol(_ibtSymbol, _platform, _periodDuration);
    }

    /**
     * @notice Getter for the symbol of the FYT of one future
     * @param _apwibtSymbol the APWine IBT symbol for this future
     * @param _periodDuration the duration of the periods for this future
     * @return the generated symbol of the FYT
     */
    function getFYTSymbol(string memory _apwibtSymbol, uint256 _periodDuration) public view returns (string memory) {
        return
            IAPWineNaming(registry.getNamingUtils()).genFYTSymbolFromIBT(
                uint8(periodIndexByDurations[_periodDuration]),
                _apwibtSymbol
            );
    }

    /**
     * @notice Getter for the period index depending on the period duration of the future
     * @param _periodDuration the duration of the periods
     * @return the period index
     */
    function getPeriodIndex(uint256 _periodDuration) public view returns (uint256) {
        return periodIndexByDurations[_periodDuration];
    }

    /**
     * @notice Getter for the beginning timestamp of the next period for the futures with a defined period duration
     * @param _periodDuration the duration of the periods
     * @return the timestamp of the beginning of the next period
     */
    function getNextPeriodStart(uint256 _periodDuration) public view returns (uint256) {
        return nextPeriodSwitchByDuration[_periodDuration];
    }

    /**
     * @notice Getter for the factor of claimable yield when unlocking
     * @param _periodDuration the duration of the periods
     * @return the factor of the claimable yield of the last period
     */
    function getUnlockYieldFactor(uint256 _periodDuration) public view returns (uint256) {
        return unlockClaimableFactorByDuration[_periodDuration];
    }

    /**
     * @notice Getter for the list of future durations registered in the contract
     * @return the list of future durations
     */
    function getDurations() public view returns (uint256[] memory) {
        uint256[] memory durationsList = new uint256[](durations.length());
        for (uint256 i = 0; i < durations.length(); i++) {
            durationsList[i] = durations.at(i);
        }
        return durationsList;
    }

    /**
     * @notice Getter for the futures by period duration
     * @param _periodDuration the period duration of the futures to return
     */
    function getFuturesWithDuration(uint256 _periodDuration) public view returns (address[] memory) {
        uint256 listLength = futuresByDuration[_periodDuration].length();
        address[] memory filteredFutures = new address[](listLength);
        for (uint256 i = 0; i < listLength; i++) {
            filteredFutures[i] = futuresByDuration[_periodDuration].at(i);
        }
        return filteredFutures;
    }

    /* Future admin methods */

    /**
     * @notice Register a newly created future in the registry
     * @param _newFuture the address of the new future
     */
    function registerNewFuture(address _newFuture) public {
        require(
            hasRole(ADMIN_ROLE, msg.sender) || registry.isRegisteredFutureFactory(msg.sender),
            "Caller cannot register a future"
        );
        registry.addFuture(_newFuture);
        uint256 futureDuration = IFuture(_newFuture).PERIOD_DURATION();
        if (!durations.contains(futureDuration)) durations.add(futureDuration);
        futuresByDuration[futureDuration].add(_newFuture);
        emit FutureRegistered(_newFuture);
    }

    /**
     * @notice Unregister a future from the registry
     * @param _future the address of the future to unregister
     */
    function unregisterFuture(address _future) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        registry.removeFuture(_future);

        uint256 futureDuration = IFuture(_future).PERIOD_DURATION();
        if (!durations.contains(futureDuration)) durations.remove(futureDuration);
        futuresByDuration[futureDuration].remove(_future);
        emit FutureUnregistered(_future);
    }

    /**
     * @notice Start all futures that have a defined period duration to synchronize them
     * @param _periodDuration the period duration of the futures to start
     */
    function startFuturesByPeriodDuration(uint256 _periodDuration) public {
        for (uint256 i = 0; i < futuresByDuration[_periodDuration].length(); i++) {
            if (!pausedFutures.contains(futuresByDuration[_periodDuration].at(i))) {
                IFuture(futuresByDuration[_periodDuration].at(i)).startNewPeriod();
            }
        }
        nextPeriodSwitchByDuration[_periodDuration] = nextPeriodSwitchByDuration[_periodDuration].add(_periodDuration);
        periodIndexByDurations[_periodDuration] = periodIndexByDurations[_periodDuration].add(1);
    }

    /* Security functions */

    /**
     * @notice Interrupt a future avoiding news registrations
     * @param _future the address of the future to pause
     * @dev should only be called in extraordinary situations by the admin of the contract
     */
    function pauseFuture(address _future) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        IFuture(_future).pausePeriods();
        pausedFutures.add(_future);
    }

    /**
     * @notice Resume a future that has been paused
     * @param _future the address of the future to resume
     * @dev should only be called in extraordinary situations by the admin of the contract
     */
    function resumeFuture(address _future) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        IFuture(_future).resumePeriods();
        pausedFutures.remove(_future);
    }
}
