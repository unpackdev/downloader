// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IBurnRedeemable.sol";
import "./IBurnableToken.sol";
import "./DBXenERC20.sol";
import "./ZXN.sol";

contract ZXNProtocol is Context, ReentrancyGuard, IBurnRedeemable {
    using SafeERC20 for ZXN;

    /**
     * @dev Type showing user's burn record for a current cycle
     */
    struct UserBurnDetails {
        address user;
        uint256 numberOfXenBatches;
        uint256 numberOfDxnBatches;
        uint256 cycle;
    }

    /**
     * @dev Type showing active cycle details
     * 1. Global [0, 1, 2, ..., 10, ..., n] - every 24 hours there will be a new global cycle 
     * 2. Active [3, 6, 7, 9, 10, ..., 400] - user was buring during these cycles
     * 3. Inactive [0, 1, 2, 4, 5, 8, ..., 400] - user was inactive during these cycles
     */
    struct CycleDetails {
        uint256 currentCycle;
        uint256 activeCycleCount;
    }


    // PUBLIC CONSTANTS

    /**
     * @dev XEN per batch
     */
    uint256 public constant XEN_PER_BATCH_COUNT = 1_000_000 ether;

    /**
     * @dev DXN per batch
     */
    uint256 public constant DXN_PER_BATCH_COUNT = 1 ether;

    /**
     * @dev Rewards in ZXN per cycle 
     * All supply would be minted in 400 cycles if at least 1 mint per cycle
     */
    uint256 public constant REWARDS_PER_CYCLE = 2_500_000 ether;

    /**
     * @dev Number of maximum active cycles to mint all ZXN supply
     */
    uint256 public constant ACTIVE_CYCLE_COUNT = 400;


    // IMMUTABLE VARIABLES

    /**
     * @dev Reward distribution cycle duration, set in constructor.
     */
    uint256 public immutable cycleDuration;

    /**
     * @dev Contract creation timestamp. Initialized inside constructor.
     */
    uint256 public immutable initTimestamp;

    /**
     * @dev XEN contract address. Initialized inside constructor.
     */
    address public immutable xenAddress;

    /**
     * @dev DBXen Token contract. Initialized inside constructor.
     */
    DBXenERC20 public immutable dxn;

    /**
     * @dev ZXN Reward Token contract. Initialized in constructor.
     */
    ZXN public immutable zxn;


    // PRIVATE VARIABLES

    /**
     * @dev The current cycle index (0-based)
     * Updated upon cycle setup that is triggered by contract interraction
     * with these functions: {burnXenBatch}, {burnDxnBatch}, {claimRewards}
     */
    uint256 private _currentCycle;

    /**
     * @dev The last cycle in which the user has burned XEN
     * address => cycle index
     */
    mapping(address => uint256) private _lastActiveCycle;

    /**
     * @dev Current unclaimed user's ZXN rewards
     * address => zxn rewards
     */
    mapping(address => uint256) private _unclaimedUserZxnRewards;

    /**
     * @dev The total amount of burn credits all accounts have accumulated per cycle.
     * cycle index => burn credits
     */
    mapping(uint256 => uint256) private _cycleTotalBurnCredits;

    /**
     * @dev The amount of burn credits an account accumulated during current cycle
     * Resets during a new cycle when an account performs an action that updates its stats.
     * user address => burn credits
     */
    mapping(address => uint256) private _cycleAccountBurnCredits;

    /**
     * @dev User burn details, can be updated during current cycle
     * Resets at the end of the cycle
     * user address => user burn details
     */
    mapping(address => UserBurnDetails) private _userBurnDetails;


    // PUBLIC VARIABLES

    /**
     * @dev Tracks How many active cycles were there 
     */
    CycleDetails public cycleDetails;

    /**
     * @dev Total number of burn credits
     */
    uint256 public totalBurnCredits;

    /**
     * @dev The total number of XEN burned during the cycle
     * cycle index => xen burned per cycle
     */
    mapping(uint256 => uint256) public cycleXenBurned; 

    /**
     * @dev Total number of XEN burned
     */
    uint256 public totalXenBurned; 

    /**
     * @dev The total number of DXN collected during the cycle by this contract
     * cycle index => dxn collected per cycle
     */
    mapping(uint256 => uint256) public cycleDxnCollectedByContract;

    /**
     * @dev Total DXN collected by the contract
     */
    uint256 public totalDxnCollected;

    /**
     * @dev Total number of burn credits accumulated by user
     */
    mapping(address => uint256) public totalAccountBurnCredits;

    /**
     * @dev DXN rewards claimed by address
     */
    mapping(address => uint256) public claimedAccountDxnRewards;


    // EVENTS

    event RewardsClaimed(
        uint256 indexed cycle,
        address indexed account,
        uint256 reward
    );

    event DxnRewardsClaimed(
        uint256 indexed cycle,
        address indexed account,
        uint256 dxnReward   // in ether
    );

    event NewCycleStarted(
        uint256 indexed cycle,
        uint256 calculatedCycleReward,
        uint256 summedCycleStakes
    );

    event XenBurned(
        address indexed userAddress,
        uint256 numberOfBatches,
        uint256 cycle
    );

    event DxnBurned(
        address indexed userAddress,
        uint256 numberOfBatches,
        uint256 cycle
    );

    event AccountStats(
        address indexed account,
        uint256 currentCycle,
        uint256 lastGlobalCycleUserWasActive,
        uint256 accountCycleBC,
        uint256 totalCycleBC,
        uint256 lastCycleRewards,  // in ether
        uint256 unclaimedRewards   // in ether
    );

    /**
     * Sets user's burn credits
     * Sets total burn credits
     */
    modifier burnWrapper(uint256 numberOfBatches, bool burningXen) {
        _;

        uint256 updatedAccountBC = 0;
        uint256 currentAccountBC = _cycleAccountBurnCredits[_msgSender()];

        if (burningXen) {
            _updateCycleDetails();
            totalXenBurned += numberOfBatches * XEN_PER_BATCH_COUNT;
            cycleXenBurned[_currentCycle] += numberOfBatches * XEN_PER_BATCH_COUNT;
            _userBurnDetails[_msgSender()].numberOfXenBatches += numberOfBatches;
            _userBurnDetails[_msgSender()].cycle = _currentCycle;
        } else {
            _userBurnDetails[_msgSender()].numberOfDxnBatches += numberOfBatches;
            cycleDxnCollectedByContract[_currentCycle] += numberOfBatches * DXN_PER_BATCH_COUNT;
            totalDxnCollected += numberOfBatches * DXN_PER_BATCH_COUNT;
        }

        if (_userBurnDetails[_msgSender()].numberOfDxnBatches > 0) {
            updatedAccountBC = _userBurnDetails[_msgSender()].numberOfXenBatches * _userBurnDetails[_msgSender()].numberOfDxnBatches;
        } else {
            updatedAccountBC = _userBurnDetails[_msgSender()].numberOfXenBatches;
        }

        totalBurnCredits += updatedAccountBC - currentAccountBC;                     
        totalAccountBurnCredits[_msgSender()] += updatedAccountBC - currentAccountBC;

        _cycleTotalBurnCredits[_currentCycle] += updatedAccountBC - currentAccountBC;
        _cycleAccountBurnCredits[_msgSender()] = updatedAccountBC;
    }
    
    /**
     * @dev Constructor - creates `ZXN()` object and sets cycle duration
     * @param _xenAddress XEN contract address
     * @param _dxnAddress DXN contract address
     */
    constructor(address _xenAddress, address _dxnAddress, uint256 _cycleDuration) {
        cycleDuration = _cycleDuration; // PROD: 60 * 60 * 24 == 1 days; TEST: 2 * 60 == 2 min;
        initTimestamp = block.timestamp;
        zxn = new ZXN();
        xenAddress = _xenAddress;
        dxn = DBXenERC20(_dxnAddress);
    }

    /**
     * @dev Returns the index of the current cycle
     */
    function getCurrentCycle() public view returns (uint256) {
        return (block.timestamp - initTimestamp) / cycleDuration;
    }

    /**
     * @dev Returns ZXN total supply
     */
    function getZxnSupply() public view returns (uint256) {
        return zxn.totalSupply();
    }

    /**
     * @dev Burn `numberOfXenBatches` where each batch is 1,000,000 XEN tokens
     * @param numberOfXenBatches number of XEN batches, 1 <= batches < 1000000
     */
    function burnXenBatch(uint256 numberOfXenBatches) 
        external payable nonReentrant() burnWrapper(numberOfXenBatches, true) {
        require(_isValidCycle(), "ZXNProtocol: Active burn cycles finished.");
        require(numberOfXenBatches > 0, "ZXNProtocol: min number of XEN batches is 1.");
        require(numberOfXenBatches <= 1000000, "ZXNProtocol: max number of XEN batches is 1000000.");
        IBurnableToken(xenAddress).burn(_msgSender(), numberOfXenBatches * XEN_PER_BATCH_COUNT);
    }

    /**
     * @dev Implemented {IBurnRedeemable} interface
     * @param user user's account
     * @param amount amount burned in wei
     */
    function onTokenBurned(address user, uint256 amount) external {
        require(msg.sender == address(xenAddress), "ZXNProtocol: Caller must be XENCrypto.");
        _updateCycle();
        _updateAccountStats(user);
        _lastActiveCycle[user] = _currentCycle;
        emit XenBurned(user, amount / XEN_PER_BATCH_COUNT, _currentCycle);
    }

    /**
     * @dev Burn numberOfDxnBatches for multiplier
     * Instead of burning deposit DXN to this contract, all of it would be used as rewards for participantion
     * @param numberOfDxnBatches number of DXN batches, 0 <= batches < 10000
     */
    function burnDxnBatch(uint256 numberOfDxnBatches) 
        external payable nonReentrant() burnWrapper(numberOfDxnBatches, false) {
        require(_hasXenBurnedCurrentCycle(_msgSender()), "ZXNProtocol: Have to burn XEN first before burning DXN in this cycle.");
        require(numberOfDxnBatches > 0, "ZXNProtocol: min number of DXN batches is 1.");
        require(numberOfDxnBatches <= 10000, "ZXNProtocol: max number of DXN batches is 10000.");
        require(dxn.balanceOf(_msgSender()) >= numberOfDxnBatches * DXN_PER_BATCH_COUNT, "ZXNProtocol: not enough DXN tokens for burn.");
        require(dxn.transferFrom(_msgSender(), address(this), numberOfDxnBatches * DXN_PER_BATCH_COUNT), "ZXNProtocol: DXN deposit failed.");
        _onDxnTokenBurned(_msgSender(), numberOfDxnBatches * DXN_PER_BATCH_COUNT);
    }

    /**
     * @dev Called from {burnDxnBatch} after DXN batches were deposited to a contract
     * @param user user's address
     * @param amount amount burned in wei
     */
    function _onDxnTokenBurned(address user, uint256 amount) private {
        _updateCycle();
        _updateAccountStats(user);
        _lastActiveCycle[user] = _currentCycle;
        emit DxnBurned(user, amount / DXN_PER_BATCH_COUNT, _currentCycle);
    }

    /**
     * @dev Mint new tokens and transfer to user's account
     */
    function claimRewards() external nonReentrant() {
        _updateCycle();
        _updateAccountStats(_msgSender());
        uint256 rewards = _unclaimedUserZxnRewards[_msgSender()];
        require(rewards > 0, "ZXNProtocol: account has no rewards.");
        _unclaimedUserZxnRewards[_msgSender()] -= rewards;
        zxn.mintReward(_msgSender(), rewards);
        emit RewardsClaimed(_currentCycle, _msgSender(), rewards / 1e18);
    }

    /**
     * @dev Send user's aquired DXN rewards to their address
     */
    function claimDxnRewards() external nonReentrant() {
         _updateCycle();
        require(totalAccountBurnCredits[_msgSender()] > 0, "ZXNProtocol: Only protocol participants can claim DXN rewards.");
        require(!_isValidCycle(), "ZXNProtocol: Rewards can be claimed only after all active cycles were finished.");
        require(_unclaimedUserZxnRewards[_msgSender()] == 0, "ZXNProtocol: All ZXN rewards must be claimed first.");
        require((claimedAccountDxnRewards[_msgSender()] == 0), "ZXNProtocol: Address already claimed DXN rewards.");
        uint256 dxnReward = accountAcquiredDxnRewards(_msgSender());
        require(dxn.balanceOf(address(this)) >= dxnReward, "ZXNProtocol: Not enough DXN tokens in the contract.");
        claimedAccountDxnRewards[_msgSender()] = dxnReward;
        require(dxn.transfer(_msgSender(), dxnReward), "ZXNProtocol: DXN transfer failed.");
        emit DxnRewardsClaimed(_currentCycle, _msgSender(), dxnReward / 1e18);
    }

    /**
     * @dev Updates active cycle details
     */
    function _updateCycleDetails() private {
        if (cycleDetails.currentCycle == getCurrentCycle()) { 
            if (cycleDetails.currentCycle == 0) {
                cycleDetails.activeCycleCount = 1;
            }
        } else {
            cycleDetails.currentCycle = getCurrentCycle();
            cycleDetails.activeCycleCount += 1;
        }
    }

    /**
     * @dev Return if it's a valid cycle. There must be 400 active cycles to mint all ZXN supply
     * If cycle > 400 it means all ZXN supply was minted and cycle is invalid
     */
    function _isValidCycle() private view returns (bool) {
        return cycleDetails.activeCycleCount <= ACTIVE_CYCLE_COUNT 
            && !(cycleDetails.currentCycle < getCurrentCycle() && cycleDetails.activeCycleCount == ACTIVE_CYCLE_COUNT);
    }

    /**
     * @dev Updates the index of the cycle.
     */
    function _updateCycle() private {
        uint256 newCycle = getCurrentCycle();
        
        if (newCycle > _currentCycle) {
            _currentCycle = newCycle;
        }
    }

    /**
     * @dev Check if user burned XEN this cycle
     * @param account user's account
     */
    function _hasXenBurnedCurrentCycle(address account) private view returns (bool) {
        return _userBurnDetails[account].cycle == getCurrentCycle() && _userBurnDetails[account].numberOfXenBatches > 0;
    }

    /**
     * @dev Add cycle rewards to total unclaimed user's rewards, reset `_userBurnDetails`
     * @param account user's account
     */
    function _updateAccountStats(address account) private {
        if (_currentCycle > _lastActiveCycle[account] &&	_cycleAccountBurnCredits[account] != 0 ) {	
            uint256 lastCycleAccountReward = (_cycleAccountBurnCredits[account] * REWARDS_PER_CYCLE) / 	
                _cycleTotalBurnCredits[_lastActiveCycle[account]];	
            _unclaimedUserZxnRewards[account] += lastCycleAccountReward;

            emit AccountStats(
                account, 
                _currentCycle, 
                _lastActiveCycle[account],
                _cycleAccountBurnCredits[account],
                _cycleTotalBurnCredits[_lastActiveCycle[account]],
                lastCycleAccountReward / 1e18,               // in ether
                _unclaimedUserZxnRewards[account] / 1e18   // in ether
            );

            _userBurnDetails[account].numberOfXenBatches = 0;
            _userBurnDetails[account].numberOfDxnBatches = 0;
            _userBurnDetails[account].cycle = 0;
            _cycleAccountBurnCredits[account] = 0;
        }
    }

    // -------------------- STATISTICS -------------------- //

    /**
     * @dev Returns unclaimed user's ZXN rewards.
     * @param account user's account
     */
    function getUnclaimedUserZxnRewards(address account) public view returns (uint256) {
        uint256 cycle = _userBurnDetails[account].cycle;

        if (_cycleTotalBurnCredits[cycle] == 0) { 
            return 0; 
        }

        return _unclaimedUserZxnRewards[account] + 
               _cycleAccountBurnCredits[account] * 
               REWARDS_PER_CYCLE / 
               _cycleTotalBurnCredits[cycle];
    }

    /**
     * Returns current cycle expected user's ZXN rewards
     * @param account user's account
     */
    function currentCycleExpectedUserZxnRewards(address account) public view returns (uint256) {
        uint256 currentCycle = getCurrentCycle();

        if (currentCycle != _userBurnDetails[account].cycle) {
            return 0;
        }

        if (_cycleTotalBurnCredits[currentCycle] == 0) { 
            return 0; 
        }

        return _cycleAccountBurnCredits[account] * REWARDS_PER_CYCLE / _cycleTotalBurnCredits[currentCycle];
    }

    /**
     * @dev Returns acquired user's DXN rewards
     * @param account user's account
     */
    function accountAcquiredDxnRewards(address account) public view returns (uint256) { 
        if (totalBurnCredits == 0) {
            return 0;
        }
        return (totalAccountBurnCredits[account] * totalDxnCollected) / totalBurnCredits;
    }

    /**
     * @dev Returns user's statistics for easier frontend call
     * @param account user's account
     * @return total unclaimed ZXN rewards
     * @return current cycle expected ZXN rewards
     * @return total acquired DXN rewards by account
     * @return claimed DXN rewards by account
     * @return total account Burn Credits (BCs)
     * @return total Burn Credits (BCs)
     */
    function getAccountStatistics(address account) 
        public 
        view 
        returns (
                uint256, 
                uint256, 
                uint256, 
                uint256, 
                uint256, 
                uint256
            ) 
        {
        return (
            getUnclaimedUserZxnRewards(account),
            currentCycleExpectedUserZxnRewards(account),
            accountAcquiredDxnRewards(account),
            claimedAccountDxnRewards[account],
            totalAccountBurnCredits[account],
            totalBurnCredits
        );
    }

    /**
     * @dev Returns protocol statistics for easier frontend call
     * @return current global cycle
     * @return current global cycle (before any XEN burns)
     * @return current active cycle
     * @return XEN burned during current cycle
     * @return total XEN burned
     * @return DXN "burned" during current cycle
     * @return total DXN "burned"
     * @return total Burn Credits (BCs)
     * @return total ZXN supply (claimed ZXN)
     */
    function getProtocolStatistics() 
        public 
        view 
        returns (
                uint256,
                uint256, 
                uint256, 
                uint256, 
                uint256, 
                uint256, 
                uint256,
                uint256,
                uint256
            ) 
        { 

            uint256 cycle = getCurrentCycle();
        return (
            cycle,
            cycleDetails.currentCycle,
            cycleDetails.activeCycleCount,
            cycleXenBurned[cycle],
            totalXenBurned,
            cycleDxnCollectedByContract[cycle],
            totalDxnCollected,
            totalBurnCredits,
            zxn.totalSupply()
        );
    }

    /**
     * @dev Confirms support for IBurnRedeemable interface
     * @param interfaceId interface id
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IBurnRedeemable).interfaceId;
    }
}