// SPDX-License-Identifier: GPL-3.0

/*
//   ::::::::::::::::::::+***+==:.                                    
//   ::::::::::::::::::::+************+-                              
//   ::::::::::::::::::::+****************+.                          
//   ::::::::::::::::::::+******************-                         
//   ::::::::::::::::::::+********************:                       
//   ::::::::::::::::::::+*********************-                      
//   ::::::::::::::::::::+*********************+                      
//   ....................=++++++++++++++++++++++                      
//                       -======================                      
//                       -=====================                       
//                       -===================-                        
//                       -=================.                          
//                       -=============:                              
//                       -=====-::.                                   
//                       ....
//
*/

pragma solidity ^0.8.9;

import "./IStakingPool.sol";
import "./ICumulativeMerkleDrop.sol";
import "./IBondingOperator.sol";
import "./T.sol";
import "./SafeCastUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./DateTime.sol";
import "./IApplication.sol";
import "./IStaking.sol";

/// @title DELIGHT T staking pool contract main code
/// @author Bryan RHEE <bryan@delightlabs.io>
/// @notice In the past, a staking provider was a singular account bonded with an operator account,
///          necessitating each participant to individually maintain their nodes.
///         However, a staking provider evolves into a dynamic contract from multiple stakers.
/// @dev    As-is: A staking provider is an account, and it should be bonded with another account - operator
///                Because of the bonding procedure, each staker should run their own node
///         To-be: A staking provider is a contract holding Ts from multiple stakers
///                The pool contract acts as one staking provider
///                 and it makes possible to receive multiple stakers.
/// @custom:experimental This contract is not tested on the production environment
contract StakingPool is ITStakingPool, Initializable, OwnableUpgradeable {
    using SafeCastUpgradeable for uint256;

    // unit structure of the snapshot
    struct UnitStatus {
        bool didSettle;
        bool isUnstakingNeeded;
        bool didClaimUnstaking;
        uint96 totalOngoingStaked;
        uint96 totalDeposit;
        uint96 totalNewUnstaking;
        uint96 totalReward;
        uint256 decreaseAuthorizationFinishesAt;
        mapping(address => uint96) stakingSnapshot;
        mapping(address => uint96) depositSnapshot;
        mapping(address => uint96) newUnstakingSnapshot;
    }

    // Admin part

    // address owner -> from Ownable
    // actual contract address -> from upgradable
    uint8 public commissionRateInPercent; // 100% -> 100
    address payable public beneficiaryAddress; // should be account, cannot change after staking is started

    // Asset part
    T public tTokenContract;
    uint96 public totalOngoingStaked;
    uint96 public totalOngoingUnstaked;
    uint96 public totalDeposited;
    uint96 public totalRequestedUnstaking;
    // minimum staking amount which is set in tBTC application (current 40K)
    uint96 public minStaking;
    uint256 public unstakingDelay;

    IStaking public tStakingContract;

    uint256 public lastDistributedAt;

    // Application address
    address[] public applicationLists;
    address public preApplication;

    // Claim contract
    ICumulativeMerkleDrop public merkleDropContract;

    // status
    uint8 public epoch;
    uint256 public nextClaimableTimestamp;
    uint16 public currPeriodNumber;

    mapping(uint16 => UnitStatus) internal statusByPeriod;

    // distinct address maker
    mapping(address => uint256) internal addressIdx;
    address[] internal userAddresses;

    // Distribution part
    mapping(address => uint96) internal staked;
    mapping(address => uint96) internal deposited;
    mapping(address => uint96) internal unstakeRequested;
    mapping(address => uint96) internal unstaking;
    mapping(address => uint96) internal claimableStatus;

    event ApplicationRegistered(address application);
    event ApplicationRemoved(address application);

    event OperatorRegistered(
        address stakingProvider,
        address application,
        address operator
    );

    event InitialDeposit(address owner, address beneficiary, uint96 amount);
    event DepositedForStaking(address staker, uint96 amount);
    event WithdrawFromPendingStaking(address staker, uint96 amount);

    event UnstakingRequest(
        address unstaker,
        uint96 amount,
        uint256 expectedWithdrawableTimestamp
    );

    event CanceledUnstakingRequest(address unstaker, uint96 amount);

    event SnapshotCaptured(
        uint16 period,
        uint96 totalOngoingStake,
        uint96 totalOngoingUnstaking
    );

    event Settled(
        uint16 period,
        uint96 totalReward,
        uint96 userReward,
        uint96 commission
    );

    event Claimed(address claimer, uint96 amount);

    event SettledUnstaking(
        uint16 period,
        uint96 totalUnstaked,
        uint96 toppedUpPendingDeposit
    );

    // ERROR section
    error CommissionRangeNotValid();
    error NotValidAddress();
    error ConfigValueNotChanged();
    error ApplicationAlreadyRegistered();
    error ApplicationNotRegistered();
    error AuthorizationChangeFailed();
    error OperatorCannotBeThisContract();
    error ShouldBePREApplication();
    error ShouldNotBePREApplication();
    error OperatorRegistrationFail(address _input);
    error AmountError(uint256 input, uint256 criteria);
    error UnstakingRequestDisabled(uint256 until);
    error TooEarlyExecution(uint256 _now, uint256 available);
    error AlreadySettled();
    error NoSnapshot(uint16 period);
    error UnstakingNotNeeded();
    error AlreadyClaimed();
    error ContractCallFail();

    /// @dev implemented as an actual constructor for upgradability
    function initialize(
        T _tTokenContract,
        IStaking _tStakingContract,
        ICumulativeMerkleDrop _merkelDropContract,
        address payable _beneficiaryAddress,
        uint8 _epoch,
        uint8 _commissionRateInPercent
    ) external initializer {
        if (0 > _commissionRateInPercent || 100 < _commissionRateInPercent)
            revert CommissionRangeNotValid();

        tTokenContract = _tTokenContract;
        tStakingContract = _tStakingContract;
        beneficiaryAddress = _beneficiaryAddress;
        epoch = _epoch;
        commissionRateInPercent = _commissionRateInPercent;
        merkleDropContract = _merkelDropContract;

        lastDistributedAt = block.timestamp;
        totalDeposited = 0;
        totalRequestedUnstaking = 0;
        totalOngoingStaked = 0;
        totalOngoingUnstaked = 0;
        minStaking = 40000e18;
        unstakingDelay = 45 days;

        applicationLists = new address[](0);
        userAddresses.push(address(0));

        __Ownable_init();
    }

    // admin setting / modifiable functions

    /// @notice T token change method. Only for owner
    /// @param  _tTokenContract renewed T token contract address
    function changeTTokenAddress(T _tTokenContract) external onlyOwner {
        if (address(_tTokenContract) == address(0)) revert NotValidAddress();
        if (tTokenContract == _tTokenContract) revert ConfigValueNotChanged();

        tTokenContract = _tTokenContract;
    }

    /// @notice T token staking change method. Only for owner
    /// @param  _tStakingContract renewed T token staking contract address
    function changeTStakingContract(
        IStaking _tStakingContract
    ) external onlyOwner {
        if (address(_tStakingContract) == address(0)) revert NotValidAddress();
        if (tStakingContract == _tStakingContract)
            revert ConfigValueNotChanged();

        tStakingContract = _tStakingContract;
    }

    /// @notice Distribution contract change method. Only for owner
    /// @param  _merkleDropContract renewed T token staking contract address
    function changeMerkleDropContract(
        ICumulativeMerkleDrop _merkleDropContract
    ) external onlyOwner {
        if (address(_merkleDropContract) == address(0))
            revert NotValidAddress();

        if (merkleDropContract == _merkleDropContract)
            revert ConfigValueNotChanged();

        merkleDropContract = _merkleDropContract;
    }

    /// @notice Beneficiary change method. Only for owner
    /// @param  _beneficiaryAddress a new beneficiary address
    function changeBeneficiary(
        address payable _beneficiaryAddress
    ) external onlyOwner {
        if (address(_beneficiaryAddress) == address(0))
            revert NotValidAddress();

        if (beneficiaryAddress == _beneficiaryAddress)
            revert ConfigValueNotChanged();

        beneficiaryAddress = _beneficiaryAddress;
    }

    /// @notice Pool service commission rate change method. Only for owner
    /// @param  _commissionRateInPercent new commission rate of this pool staking service
    function changeCommissionRateInPercent(
        uint8 _commissionRateInPercent
    ) external onlyOwner {
        if (0 > _commissionRateInPercent || 100 < _commissionRateInPercent)
            revert CommissionRangeNotValid();

        if (commissionRateInPercent == _commissionRateInPercent)
            revert ConfigValueNotChanged();

        commissionRateInPercent = _commissionRateInPercent;
    }

    /// @notice Min staking T token amount change method. Only for owner
    ///         Central T staking contract has minimum staking amount. (40K for now)
    ///         In case of any change, a config method is implemented.
    /// @param  _minStaking new commission rate of this pool staking service
    function changeMinStaking(uint96 _minStaking) external onlyOwner {
        if (minStaking == _minStaking) revert ConfigValueNotChanged();

        minStaking = _minStaking;
    }

    /// @notice Unstaking delay change method. Only for owner
    ///         Central T staking contract has unstaking delay. (45 days for now)
    ///         In case of any change, a config method is implemented.
    /// @param  _unstakingDelay new unstaking delay of the T staking contract
    function changeUnstakingDelay(uint256 _unstakingDelay) external onlyOwner {
        if (unstakingDelay == _unstakingDelay) revert ConfigValueNotChanged();

        unstakingDelay = _unstakingDelay;
    }

    /// @notice Epoch change method. Only for owner
    ///         As reward is distributed by every month, it is set 1 month as default
    ///         But in case of any change, a config method is implemented.
    /// @param  _epoch new epoch of the settlement
    function changeEpoch(uint8 _epoch) external onlyOwner {
        if (epoch == _epoch) revert ConfigValueNotChanged();

        epoch = _epoch;
    }

    /// @notice Adding an application method. Only for owner
    ///         Currently the protocol has PRE, tBTC, random beacon
    ///         But it should be configurable against any change
    /// @param  _application new application address
    function addApplication(
        address _application,
        bool isPRE
    ) external onlyOwner {
        for (uint256 i = 0; i < applicationLists.length; i++) {
            if (applicationLists[i] == _application) {
                revert ApplicationAlreadyRegistered();
            }
        }

        applicationLists.push(_application);

        if (isPRE) {
            preApplication = _application;
        }

        emit ApplicationRegistered(address(_application));
    }

    /// @notice Removing an application method. Only for owner
    ///         Currently the protocol has PRE, tBTC, random beacon
    ///         But it should be configurable against any change
    /// @param  _application new application address
    function removeApplication(address _application) external onlyOwner {
        for (uint256 i = 0; i < applicationLists.length; i++) {
            if (applicationLists[i] == _application) {
                delete applicationLists[i];

                emit ApplicationRemoved(address(_application));
                return;
            }
        }

        revert ApplicationNotRegistered();
    }

    /// Private methods
    /// Generally wrapper methods

    // T token related

    // token transfer approve
    function _approve(address spender, uint96 amount) private {
        tTokenContract.approve(spender, uint256(amount));
    }

    // transfer from mine
    function _transfer(address to, uint96 amount) private {
        tTokenContract.transfer(to, uint256(amount));
    }

    // transfer from somebody else
    function _transferFrom(address from, address to, uint96 amount) private {
        tTokenContract.transferFrom(from, to, uint256(amount));
    }

    // T staking related

    // Central T staking contrat's approve application
    // only for testing purpose
    function _approveApplication(IApplication _app) private {
        tStakingContract.approveApplication(address(_app));
    }

    // initial staking during node initialize
    function _stake(
        address stakingProvider,
        address payable beneficiary,
        address authorizer,
        uint96 amount
    ) private {
        tStakingContract.stake(
            stakingProvider,
            beneficiary,
            authorizer,
            amount
        );
    }

    // applying staking in increasing way
    // not needed for PRE
    function _increaseAuthorization(
        address stakingProvider,
        IApplication application,
        uint96 amount
    ) private {
        tStakingContract.increaseAuthorization(
            stakingProvider,
            address(application),
            amount
        );
    }

    // applying staking in decreasing way
    // it does not effect immediately, need unstaking delay (current 45 days)
    // unstaking flow:
    //   requestAuthorizationDecrease -> 45 days -> approveAuthorizationDecrease -> unstake
    // not needed for PRE
    function _requestAuthorizationDecrease(
        address stakingProvider,
        IApplication application,
        uint96 amount
    ) private {
        tStakingContract.requestAuthorizationDecrease(
            stakingProvider,
            address(application),
            amount
        );
    }

    // adding more stake for existing stakers
    function _topUp(uint96 amount) private {
        tStakingContract.topUp(address(this), amount);
    }

    // after requested authorization decrease, spent 45 days delay, and executed approveAuthorizationDecrease
    //  then, execute it for actual withdraw
    function _unstake(uint96 amount) private {
        tStakingContract.unstakeT(address(this), amount);
    }

    // application related

    // decrease request -> execute at the staking contract side
    // approve the decrease -> execute at the application contract side
    function _approveAuthorizationDecrease(IApplication _application) private {
        if (address(_application) == address(0)) revert NotValidAddress();

        ITBTCApplication(address(_application)).approveAuthorizationDecrease(
            address(this)
        );
    }

    // claim
    function _claim(
        uint256 cumulativeAmount,
        bytes32 expectedMerkleRoot,
        bytes32[] calldata merkleProof
    ) private {
        merkleDropContract.claim(
            address(this),
            beneficiaryAddress,
            cumulativeAmount,
            expectedMerkleRoot,
            merkleProof
        );
    }

    // derive the 1st day of each month
    function _find1stDayAfterEpochMonth(
        uint256 timestamp
    ) private view returns (uint256) {
        (uint256 year, uint256 month, ) = DateTime.timestampToDate(timestamp);

        month += epoch;

        // Don't have to check month overflow like below. The library covers it!
        // if (month > 12) {
        //     year += 1;
        //     month = month % 12 + 1;
        // }

        return DateTime.timestampFromDateTime(year, month, 1, 0, 0, 0);
    }

    // distinct address manager
    function addToAddressArr(address who) private {
        if (!inAddressArr(who)) {
            // Append
            addressIdx[who] = userAddresses.length;
            userAddresses.push(who);
        }
    }

    function inAddressArr(address who) private view returns (bool) {
        // address 0x0 is not valid if pos is 0 is not in the array
        if (who != address(0) && addressIdx[who] > 0) {
            return true;
        }
        return false;
    }

    // Public methods

    /// @notice register operator address on tBTC & tBTC random beacon application
    /// @param  _application application contract address
    ///                      only tBTC & tBTC random beacon application available
    function registerOperator(IApplication _application, address payable _operator) external onlyOwner {
        if (address(_application) == address(0)) revert NotValidAddress();

        if (_operator == address(this))
            revert OperatorCannotBeThisContract();

        if (address(_application) == address(preApplication))
            revert ShouldNotBePREApplication();

        ITBTCApplication(address(_application)).registerOperator(
            _operator
        );

        emit OperatorRegistered(
            address(this),
            address(_application),
            _operator
        );
    }

    /// @notice register operator address on PRE application
    /// @param  _application application contract address
    ///                      only PRE application available
    function bondOperator(IApplication _application, address payable _operator) external onlyOwner {
        if (address(_application) == address(0)) revert NotValidAddress();
        if (_operator == address(this))
            revert OperatorCannotBeThisContract();

        if (address(_application) != address(preApplication))
            revert ShouldBePREApplication();

        IPREApplication(address(_application)).bondOperator(
            address(this),
            _operator
        );

        emit OperatorRegistered(
            address(this),
            address(_application),
            _operator
        );
    }

    /// @notice The first step of staking, start staking with configs
    ///         owner only
    /// @dev    about `stake` method of the central T staking contract,
    ///         stake(address stakingProvider, address beneficiary, address authorizer, uint96 amount)
    ///          address stakingProvider -> certainly this contract
    ///          address beneficiary     -> get from the config.
    ///                                      if you want to use this contract address, please execute changeBeneficiary() before execute this method
    ///          address authorizer      -> used to set same as the staking provider, so the value is this contract's address
    ///         by these description, I put this contract address in "stakingProvider" and "authorizer"
    ///          and beneficiary, use from the config of this contract
    /// @param _amount the amount of the T token to stake
    function initialOwnerStake(uint96 _amount) external onlyOwner {
        if (beneficiaryAddress == address(0)) revert NotValidAddress();
        if (_amount < minStaking) revert AmountError(_amount, minStaking);

        // 1. transfer from the owner address to this contract
        _transferFrom(msg.sender, address(this), _amount);

        // 2. call token transfer approve & stake
        _approve(address(tStakingContract), _amount);
        _stake(address(this), beneficiaryAddress, address(this), _amount);

        // 3. increase authorization to tBTC application
        for (uint256 i = 0; i < applicationLists.length; i++) {
            if (
                applicationLists[i] != preApplication &&
                applicationLists[i] != address(0)
            ) {
                _increaseAuthorization(
                    address(this),
                    IApplication(applicationLists[i]),
                    _amount
                );
            }
        }

        // 4. add the owner into the staker's map
        staked[msg.sender] = _amount; // staked[msg.sender] should be zero in this time
        totalOngoingStaked += _amount;
        addToAddressArr(msg.sender);

        // 6. find the timestamp of the last day of the epoch month later
        // NOTE: Don't execute on the last day of the month
        nextClaimableTimestamp =
            _find1stDayAfterEpochMonth(block.timestamp) -
            1 days;

        // 7. In the first period, only node operator is the staker.
        //    Take period 0 snapshot
        UnitStatus storage unit = statusByPeriod[0]; // period 0

        unit.didSettle = false;
        unit.didClaimUnstaking = false;
        unit.totalOngoingStaked = totalOngoingStaked;
        unit.totalNewUnstaking = 0;
        unit.totalReward = 0;
        unit.isUnstakingNeeded = false;
        unit.stakingSnapshot[msg.sender] = staked[msg.sender];

        // increase period to 1 and welcome other users' staking
        currPeriodNumber = 1;

        emit InitialDeposit(msg.sender, beneficiaryAddress, _amount);
    }

    /// @notice Staking cycle overview
    ///         ~ the end of the month  - receive users' staking
    ///                                   free to request staking by `requestStake()`
    ///                                     & cancel the request by `withdrawFromDeposit()`
    ///         the day of              - do `snapshotThisPeriod()`, including with adjusting the pool's staking amount
    ///           the end of the month    after then, the user's deposit is changed into the stake
    ///                                     and need unstaking delay if you want to unstake
    ///         reward available        - withdraw the rewards from each application, and make them available to claim
    ///         if unstaking is needed  - trigger the decreasing authorization and wait for the delay (45 days).
    ///                                   NO NEW staking & ustaking request ACCEPT during decreasing authorization
    ///         after unstaking delay   - approve decrease authorization, unstake, and disstribute to users

    /// @notice User can request staking on this method
    /// @dev    Staking does not activate immediately the right after the execution
    ///         `snapshotThisPeriod()` method will capture the current stakig status, and activate your staking
    /// @param _amount the amount of staking request from the user
    function requestStake(uint96 _amount) external {
        if (_amount <= 0) revert AmountError(_amount, 0);

        // 1. transfer from user's address
        _transferFrom(msg.sender, address(this), _amount);

        // 2. add the member into the deposit map
        if (deposited[msg.sender] == 0) {
            deposited[msg.sender] = _amount;
            addToAddressArr(msg.sender);
        } else {
            deposited[msg.sender] += _amount;
        }

        // 3. add total deposit amount
        totalDeposited += _amount;

        emit DepositedForStaking(msg.sender, _amount);
    }

    /// @notice If a user requested staking but it is not activated yet, it can be withdrawable.
    /// @dev    Before the end of the month, as the deposit is not changed into the stake,
    ///           the deposit can be withdrawn before the end of the month
    /// @param _amount the amount of withdraw from the deposit
    function withdrawFromDeposit(uint96 _amount) external {
        if (_amount <= 0) revert AmountError(_amount, 0);

        if (_amount > deposited[msg.sender])
            revert AmountError(_amount, deposited[msg.sender]);

        // withdraw token to user
        _transfer(msg.sender, _amount);

        // change the stats
        deposited[msg.sender] -= _amount;
        totalDeposited -= _amount;

        emit WithdrawFromPendingStaking(msg.sender, _amount);
    }

    /// @notice If a user requested staking and it is activated, it can be withdrawable after the unstaking delay.
    ///         If there is existing token unstake, users cannot request unstake during this unstaking delay
    /// @dev    If a user requested unstaking, decrease request is executed by `snapshotThisPeriod()`
    ///         And withdrawable after unstaking delay.
    ///         So the actual delay is (the # of remaining days to the end of the month) + 45 days
    ///         After the delay, the user can withdraw by `claim()`
    /// @param _amount the amount of unstaking
    function requestUnstake(uint96 _amount) public {
        if (staked[msg.sender] < unstakeRequested[msg.sender] + _amount)
            revert AmountError(
                _amount,
                staked[msg.sender] - unstakeRequested[msg.sender]
            );

        if (totalOngoingUnstaked > 0) {
            UnitStatus storage prevUnit = statusByPeriod[currPeriodNumber - 2];
            UnitStatus storage currUnit = statusByPeriod[currPeriodNumber - 1];

            uint256 until;
            if (prevUnit.isUnstakingNeeded)
                until = prevUnit.decreaseAuthorizationFinishesAt;
            else until = currUnit.decreaseAuthorizationFinishesAt;

            revert UnstakingRequestDisabled(until);
        }

        // cannot be unstaking immediately but need a winddown time (45 days)
        // actual deduction on staking map is on distribution
        if (unstakeRequested[msg.sender] == 0) {
            unstakeRequested[msg.sender] = _amount;
        } else {
            // from Solidity 0.8, SafeMath is not needed
            // Overflow is checked from executor
            unstakeRequested[msg.sender] += _amount;
        }

        totalRequestedUnstaking += _amount;

        emit UnstakingRequest(
            msg.sender,
            _amount,
            nextClaimableTimestamp + unstakingDelay
        );
    }

    /// @notice If a user requested unstaking and it is not applied, it can be canceled.
    /// @param _amount the amount of cancel unstaking
    function cancelUnappliedUnstake(uint96 _amount) public {
        if (unstakeRequested[msg.sender] <= 0)
            revert AmountError(unstakeRequested[msg.sender], 0);

        if (unstakeRequested[msg.sender] < _amount)
            revert AmountError(_amount, unstakeRequested[msg.sender]);

        unstakeRequested[msg.sender] -= _amount;
        totalRequestedUnstaking -= _amount;

        emit CanceledUnstakingRequest(msg.sender, _amount);
    }

    /// @notice Unstaking all what the user staked. Please check `requestUnstake()`
    function requestUnstakeAll() external {
        requestUnstake(staked[msg.sender] - unstakeRequested[msg.sender]);
    }

    /// @notice It would be great that the reward is automatically trasferred at the right date
    ///         Unfortunately the reward process is manual and it will not be done on the exact day
    ///         So we need to seperate the step - `snapshotThisPeriod()` & `settle()`
    /// @dev    This method executes every last day of the month.
    ///         Step to take snapshot
    ///          1. Move the current status data into the snapshot structure
    ///          2. Execute Increase or decrease authorization by the staking amount
    ///          3. Start a new period
    function snapshotThisPeriod() external onlyOwner {
        if (block.timestamp < nextClaimableTimestamp)
            revert TooEarlyExecution(block.timestamp, nextClaimableTimestamp);

        UnitStatus storage unit = statusByPeriod[currPeriodNumber];
        bool isUnstakingOngoing = totalOngoingUnstaked > 0;

        // 1. move the current status data into the snapshot structure
        unit.didSettle = false;
        unit.didClaimUnstaking = false;
        unit.totalReward = 0;

        // 2. decrease or increase authorization
        //  1) totalDeposited > totalRequestedUnstaking
        //     - top up (totalDeposited - totalRequestedUnstaking) more
        //     - total ongoing staking amount: add (totalDeposited - totalRequestedUnstaking)
        //  2) totalDeposited < totalRequestedUnstaking
        //     - increase stake (totalDeposited)
        //     - decrease stake (totalRequestedUnstaking)
        if (!isUnstakingOngoing) {
            if (totalDeposited >= totalRequestedUnstaking) {
                if (totalDeposited > totalRequestedUnstaking) {
                    _approve(
                        address(tStakingContract),
                        totalDeposited - totalRequestedUnstaking
                    );

                    _topUp(totalDeposited - totalRequestedUnstaking);

                    for (uint256 i = 0; i < applicationLists.length; i++) {
                        if (
                            applicationLists[i] == preApplication ||
                            address(applicationLists[i]) == address(0)
                        ) continue;

                        _increaseAuthorization(
                            address(this),
                            IApplication(applicationLists[i]),
                            totalDeposited - totalRequestedUnstaking
                        );
                    }
                }

                totalOngoingStaked += (totalDeposited -
                    totalRequestedUnstaking);

                // totalOngoingUnstaked: no change

                unit.isUnstakingNeeded = false;
                unit.totalOngoingStaked = totalOngoingStaked;
                unit.totalNewUnstaking = 0;
            } else if (totalDeposited < totalRequestedUnstaking) {
                if (totalDeposited > 0) {
                    _approve(address(tStakingContract), totalDeposited);
                    _topUp(totalDeposited);
                }

                for (uint256 i = 0; i < applicationLists.length; i++) {
                    if (
                        applicationLists[i] == preApplication ||
                        address(applicationLists[i]) == address(0)
                    ) continue;

                    if (totalDeposited > 0) {
                        _increaseAuthorization(
                            address(this),
                            IApplication(applicationLists[i]),
                            totalDeposited
                        );
                    }

                    _requestAuthorizationDecrease(
                        address(this),
                        IApplication(applicationLists[i]),
                        totalRequestedUnstaking
                    );
                }

                totalOngoingStaked += totalDeposited;
                totalOngoingUnstaked += totalRequestedUnstaking;

                // 3. record when unstaking is available
                unit.isUnstakingNeeded = true;
                unit.totalOngoingStaked = totalOngoingStaked;
                unit.totalNewUnstaking = totalRequestedUnstaking;

                unit.decreaseAuthorizationFinishesAt =
                    block.timestamp +
                    unstakingDelay;
            }
        } else {
            unit.isUnstakingNeeded = false;
            unit.totalOngoingStaked = totalOngoingStaked;
            unit.totalDeposit = totalDeposited;
            unit.totalNewUnstaking = 0;
        }

        emit SnapshotCaptured(
            currPeriodNumber,
            totalOngoingStaked,
            totalOngoingUnstaked
        );

        // 4. initiate deposit & unstaking request
        // 5. calculate each user's status
        /* solhint-disable prettier/prettier */
        for (uint256 i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == address(0)) continue;

            if (!isUnstakingOngoing) {
                if (!unit.isUnstakingNeeded) {
                    if (
                        deposited[userAddresses[i]] >=
                        unstakeRequested[userAddresses[i]]
                    ) {
                        staked[userAddresses[i]] += (deposited[userAddresses[i]] - unstakeRequested[userAddresses[i]]);

                        unit.stakingSnapshot[userAddresses[i]] = staked[userAddresses[i]]; // increasing applied
                        unit.newUnstakingSnapshot[userAddresses[i]] = 0;
                    } else {
                        staked[userAddresses[i]] -= (unstakeRequested[userAddresses[i]] - deposited[userAddresses[i]]);
                        unit.stakingSnapshot[userAddresses[i]] = staked[userAddresses[i]];

                        // make it claimable immediately
                        claimableStatus[userAddresses[i]] += (unstakeRequested[userAddresses[i]] - deposited[userAddresses[i]]);
                    }
                } else {
                    staked[userAddresses[i]] += deposited[userAddresses[i]];
                    unstaking[userAddresses[i]] += unstakeRequested[userAddresses[i]];
                    
                    unit.stakingSnapshot[userAddresses[i]] = staked[userAddresses[i]];
                    unit.newUnstakingSnapshot[userAddresses[i]] = unstakeRequested[userAddresses[i]];
                }
            } else {
                unit.stakingSnapshot[userAddresses[i]] = staked[userAddresses[i]];
                unit.depositSnapshot[userAddresses[i]] = deposited[userAddresses[i]];
            }

            deposited[userAddresses[i]] = 0;
            unstakeRequested[userAddresses[i]] = 0;
        }
        /* solhint-enable prettier/prettier */

        // 6. check next claimable timestamp
        // NOTE: "5 days" doesn't have any big purpose
        //       This method used to execute in the end of the month,
        //        but if it were _find1stDayAfterEpochMonth(block.timestamp)
        //          then nextClaimableTimestamp would be the end of THIS month again
        //       It needs to add some more days to make the parameter date to the next month
        /* solhint-disable prettier/prettier */
        nextClaimableTimestamp =
            _find1stDayAfterEpochMonth(block.timestamp + 5 days) -1 days;

        // 7. reset temporal variables
        totalDeposited = 0;
        totalRequestedUnstaking = 0;

        // 8. increase period number
        currPeriodNumber += 1;
        /* solhint-enable prettier/prettier */
    }

    /// @notice Settlement method.
    ///         Do reward claim & distribution
    /// @param periodNumber         the unique index number of the "period", increasing by each month
    /// @param cumulativeAmount     how much amount it has already been claimed
    /// @param expectedMerkleRoot   expected merkle root
    /// @param merkleProof          Proof of the merkle
    function settle(
        uint16 periodNumber,
        uint256 cumulativeAmount,
        bytes32 expectedMerkleRoot,
        bytes32[] calldata merkleProof
    ) external onlyOwner {
        // it should be executed even though the amount is zero
        // zero amount execution is used for just increasing the period number
        //  and start public staking when initial staking is completed

        UnitStatus storage unit = statusByPeriod[periodNumber];

        if (unit.didSettle) revert AlreadySettled();
        if (unit.totalOngoingStaked <= 0) revert NoSnapshot(periodNumber);

        // 0. withdraw all rewards from the application
        // TODO: if there is any absolute solution how to query the reward, need to be revised that way
        uint256 beforeBalance = tTokenContract.balanceOf(beneficiaryAddress);
        _claim(cumulativeAmount, expectedMerkleRoot, merkleProof);

        // solhint-disable-next-line prettier/prettier
        uint96 rewards = (tTokenContract.balanceOf(beneficiaryAddress) - beforeBalance).toUint96();

        // 1. split commission & user reward
        uint256 commission = (rewards * commissionRateInPercent) / 100;
        uint256 totalUserReward = rewards - commission;

        // 2. transfer asset to this contract
        // Beneficiary or owner should approve the amount first!
        // Beneficiary gets all rewards first, and transfer except the commission
        if (beneficiaryAddress != address(this))
            _transferFrom(
                beneficiaryAddress,
                address(this),
                totalUserReward.toUint96()
            );
        else claimableStatus[beneficiaryAddress] += commission.toUint96();

        // 3. set total reward amount
        unit.totalReward = totalUserReward.toUint96();

        // 3. distribute to each account
        //
        // (net staking request) = (total staking request) - (total unstaking request)
        //
        // Rule
        //  1) If net staking request is in staking direction
        //    - the pool contract stakes the amount of net staking request
        //    - the reward distributes by each stake shares
        //  2) If net staking request is in unstaking direction
        //    - the pool contract firstly stakes and increasing authorization from the deposit
        //    - then, the pool contract execute decreasing authorization
        //    - no reward for unstakers, give rewards to deposit users instead
        /* solhint-disable prettier/prettier */
        if (periodNumber >= 1) {
            UnitStatus storage prevUnit = statusByPeriod[periodNumber - 1];

            uint256 totalShare = unit.totalOngoingStaked - prevUnit.totalNewUnstaking + unit.totalDeposit - unit.totalNewUnstaking;

            for (uint256 i = 0; i < userAddresses.length; i++) {
                if (userAddresses[i] == address(0)) continue;

                uint256 myShare = unit.stakingSnapshot[userAddresses[i]] +
                    unit.depositSnapshot[userAddresses[i]] -
                    prevUnit.newUnstakingSnapshot[userAddresses[i]] -
                    unit.newUnstakingSnapshot[userAddresses[i]];

                claimableStatus[userAddresses[i]] += (uint256(unit.totalReward) * myShare / totalShare).toUint96();
            }
        } else {
            for (uint256 i = 0; i < userAddresses.length; i++) {
                if (userAddresses[i] == address(0)) continue;

                claimableStatus[userAddresses[i]] += (
                      uint256(unit.totalReward)
                    * uint256(unit.stakingSnapshot[userAddresses[i]])
                    / uint256(unit.totalOngoingStaked)
                ).toUint96();
            }
        }
        /* solhint-enable prettier/prettier */

        unit.didSettle = true;
        lastDistributedAt = block.timestamp;

        emit Settled(
            periodNumber,
            rewards,
            totalUserReward.toUint96(),
            commission.toUint96()
        );
    }

    /// @notice After unstaking delay, it finally approves decreasing authorization,
    ///           and receives staked tokens.
    ///         Unstake them and make it claimable
    /// @dev    It calls approveAuthorizationDecrease & unstakeT
    /// @param periodNumber the period number that want to execute unstaking
    function executeUnstaking(uint16 periodNumber) external onlyOwner {
        UnitStatus storage status = statusByPeriod[periodNumber];

        if (!status.isUnstakingNeeded) revert UnstakingNotNeeded();

        if (block.timestamp < status.decreaseAuthorizationFinishesAt)
            revert TooEarlyExecution(
                block.timestamp,
                status.decreaseAuthorizationFinishesAt
            );

        if (status.didClaimUnstaking) revert AlreadyClaimed();

        for (uint256 i = 0; i < applicationLists.length; i++) {
            if (
                applicationLists[i] == preApplication ||
                address(applicationLists[i]) == address(0)
            ) continue;

            _approveAuthorizationDecrease(IApplication(applicationLists[i]));
        }

        // 3. unstake
        _unstake(status.totalNewUnstaking);

        /* solhint-disable prettier/prettier */
        // 4. settle to users
        for (uint256 i = 0; i < userAddresses.length; i++) {
            staked[userAddresses[i]] -= status.newUnstakingSnapshot[userAddresses[i]];
            claimableStatus[userAddresses[i]] += status.newUnstakingSnapshot[userAddresses[i]];
        }

        totalOngoingStaked -= status.totalNewUnstaking;
        totalOngoingUnstaked -= status.totalNewUnstaking;

        // 5. mark as claimed
        status.didClaimUnstaking = true;

        // 6. stake if there are any pending deposit
        UnitStatus storage currStatus = statusByPeriod[periodNumber + 1];
        if (currStatus.totalDeposit > 0) {
            // 6-1. topup
            _approve(address(tStakingContract), currStatus.totalDeposit);
            _topUp(currStatus.totalDeposit);

            // 6-2. increase allowance
            for (uint256 i = 0; i < applicationLists.length; i++) {
                if (applicationLists[i] == preApplication || address(applicationLists[i]) == address(0)) continue;

                _increaseAuthorization(
                    address(this),
                    IApplication(applicationLists[i]),
                    currStatus.totalDeposit
                );
            }

            // 6-3. count addtional stake
            totalOngoingStaked += currStatus.totalDeposit;

            // 6-4. apply users' stake status
            for (uint256 i = 0; i < userAddresses.length; i++) {
                if (userAddresses[i] == address(0)) continue;
                staked[userAddresses[i]] += currStatus.depositSnapshot[userAddresses[i]];
            }
        }
        /* solhint-enable prettier/prettier */

        emit SettledUnstaking(
            periodNumber,
            status.totalNewUnstaking,
            currStatus.totalDeposit
        );
    }

    /// @notice Users can receives their monthly rewards & unstaked tokens
    function claim() external {
        if (claimableStatus[msg.sender] <= 0) revert AlreadyClaimed();

        // 1. transfer to the caller
        _transfer(msg.sender, claimableStatus[msg.sender]);

        emit Claimed(msg.sender, claimableStatus[msg.sender]);

        claimableStatus[msg.sender] = 0;
    }

    //
    //
    // View functions
    //
    //

    /// @notice Get operator address from each application
    /// @dev    Get operator address by application contract call for debugging purpose
    /// @param  _application application contract address
    /// @return address operator addresss
    function getOperatorFromApplication(
        IApplication _application
    ) external view returns (address) {
        address operatorFromQuery;

        if (address(_application) == address(preApplication)) {
            (bool success, bytes memory data) = address(_application)
                .staticcall(
                    abi.encodeWithSignature(
                        "getOperatorFromStakingProvider(address)",
                        address(this)
                    )
                );

            if (!success) revert ContractCallFail();

            operatorFromQuery = abi.decode(data, (address));

            if (operatorFromQuery == address(0)) revert NotValidAddress();
        } else {
            (bool success, bytes memory data) = address(_application)
                .staticcall(
                    abi.encodeWithSignature(
                        "stakingProviderToOperator(address)",
                        address(this)
                    )
                );

            if (!success) revert ContractCallFail();

            operatorFromQuery = abi.decode(data, (address));

            if (operatorFromQuery == address(0)) revert NotValidAddress();
        }

        return operatorFromQuery;
    }

    /// @notice Check staking amount from application
    /// @dev    Get the value from the applications from the application contract call for debugging purpose
    /// @param  _application    application address
    /// @return uint96          staked & authorized token amount
    function authorizedTBTCStake(
        IApplication _application
    ) external view returns (uint96) {
        return
            tStakingContract.authorizedStake(
                address(this),
                address(_application)
            );
    }

    /// @notice Get the staked amount of each period
    /// @param period   the unique number of the period
    /// @param staker   the addres of the user
    /// @return bool    is the given period is settled of not
    /// @return uint96  the amount of the token staked
    function stakedAmountByGivenPeriod(
        uint16 period,
        address staker
    ) external view returns (bool, uint96) {
        UnitStatus storage data = statusByPeriod[period];
        return (data.didSettle, data.stakingSnapshot[staker]);
    }

    /// @notice Get current staking amount
    /// @param staker  the user's address
    /// @return uint96 the amount of the staked token
    function currStakingAmount(address staker) external view returns (uint96) {
        return staked[staker];
    }

    /// @notice Get current deposit (and not staked) amount
    /// @param staker  the user's address
    /// @return uint96 the amount of the deposited token
    function currDepositedAmount(
        address staker
    ) external view returns (uint96) {
        return deposited[staker];
    }

    /// @notice Get current unstaking amount
    /// @param staker  the user's address
    /// @return uint96 the amount of the deposited token
    function currUnstakingAmount(
        address staker
    ) external view returns (uint96) {
        return unstakeRequested[staker];
    }

    /// @notice Get current unclaimed reward
    /// @param staker  the user's address
    /// @return uint96 the amount of the unclaimed reward
    function unclaimedReward(address staker) external view returns (uint96) {
        return claimableStatus[staker];
    }

    /// @notice Check whether the given period is unstakable or not
    /// @param period the unique number of the period
    /// @return bool return that the given period is unstakble or not
    function unstakeExecutable(uint16 period) external view returns (bool) {
        UnitStatus storage data = statusByPeriod[period];
        return
            data.isUnstakingNeeded &&
            !data.didClaimUnstaking &&
            block.timestamp > data.decreaseAuthorizationFinishesAt;
    }
}
