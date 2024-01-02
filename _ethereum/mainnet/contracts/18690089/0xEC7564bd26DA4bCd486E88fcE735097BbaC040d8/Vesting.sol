// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IBEP20.sol";

contract Vesting is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public poolIndex;
    mapping(uint256 => Pool) public pools;

    event CreatePoolEvent(uint256 poolId);
    event AddFundEvent(uint256 poolId, address user, uint256 fundAmount);
    event RemoveFundEvent(uint256 poolId, address user);
    event ClaimFundEvent(uint256 poolId, address user, uint256 fundClaimed);

    uint8 private constant VESTING_TYPE_MILESTONE_UNLOCK_FIRST = 1;
    uint8 private constant VESTING_TYPE_MILESTONE_CLIFF_FIRST = 2;
    uint8 private constant VESTING_TYPE_LINEAR_UNLOCK_FIRST = 3;
    uint8 private constant VESTING_TYPE_LINEAR_CLIFF_FIRST = 4;

    uint256 private constant ONE_HUNDRED_PERCENT_SCALED = 10000;
    uint256 private constant TEN_YEARS_IN_S = 311040000;

    enum PoolState {
        NEW,
        STARTING,
        PAUSE,
        SUCCESS
    }

    struct Pool {
        IBEP20 tokenFund;
        uint256 id;
        string name;
        uint8 vestingType;
        uint256 tge;
        uint256 cliff;
        uint256 unlockPercent;
        uint256 linearVestingDuration;
        uint256[] milestoneTimes;
        uint256[] milestonePercents;
        mapping(address => uint256) funds;
        mapping(address => uint256) released;
        uint256 fundsTotal;
        uint256 fundsClaimed;
        PoolState state;
    }

    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        poolIndex = 1;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Restricted to admins!"
        );
        _;
    }

    function createPool(
        address _tokenFund,
        string memory _name,
        uint8 _vestingType,
        uint256 _tge,
        uint256 _cliff,
        uint256 _unlockPercent,
        uint256 _linearVestingDuration,
        uint256[] memory _milestoneTimes,
        uint256[] memory _milestonePercents
    ) external nonReentrant onlyAdmin {
        _validateSetup(
            _vestingType,
            _unlockPercent,
            _tge,
            _cliff,
            _linearVestingDuration,
            _milestoneTimes,
            _milestonePercents
        );

        uint256 index = poolIndex++;
        Pool storage pool = pools[index];
        pool.id = index;
        pool.tokenFund = IBEP20(_tokenFund);
        pool.name = _name;
        pool.vestingType = _vestingType;
        pool.tge = _tge;
        pool.cliff = _cliff;
        pool.unlockPercent = _unlockPercent;
        pool.linearVestingDuration = _linearVestingDuration;
        pool.milestoneTimes = _milestoneTimes;
        pool.milestonePercents = _milestonePercents;
        pool.fundsTotal = 0;
        pool.fundsClaimed = 0;
        pool.state = PoolState.NEW;

        emit CreatePoolEvent(index);
    }

    function start(uint256 poolId) external nonReentrant onlyAdmin {
        Pool storage pool = pools[poolId];
        require(
            pool.state == PoolState.NEW || pool.state == PoolState.PAUSE,
            "Invalid action"
        );
        pool.state = PoolState.STARTING;
    }

    function pause(uint256 poolId) external nonReentrant onlyAdmin {
        Pool storage pool = pools[poolId];
        require(pool.state != PoolState.PAUSE, "Invalid action");
        pool.state = PoolState.PAUSE;
    }

    function end(uint256 poolId) external nonReentrant onlyAdmin {
        Pool storage pool = pools[poolId];
        require(pool.state == PoolState.STARTING, "Invalid action");
        pool.state = PoolState.SUCCESS;
    }

    function addFunds(
        uint256 poolId,
        uint256[] memory fundAmounts,
        address[] memory users
    ) external nonReentrant onlyAdmin {
        require(
            users.length == fundAmounts.length,
            "Input arrays length mismatch"
        );

        //
        uint256 totalFundDeposit = 0;
        for (uint256 u = 0; u < fundAmounts.length; u++) {
            totalFundDeposit = totalFundDeposit.add(fundAmounts[u]);
        }

        Pool storage pool = pools[poolId];

        require(
            pool.tokenFund.balanceOf(_msgSender()) >= totalFundDeposit,
            "Error: not enough Token"
        );
        pool.tokenFund.transferFrom(_msgSender(), address(this), totalFundDeposit);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 fundAmount = fundAmounts[i];
            uint256 oldFund = pool.funds[user];
            if (oldFund > 0) {
                pool.fundsTotal = pool.fundsTotal.add(fundAmount);
                pool.funds[user] = pool.funds[user].add(fundAmount);
            } else {
                pool.fundsTotal = pool.fundsTotal.add(fundAmount);
                pool.funds[user] = pool.funds[user].add(fundAmount);
                pool.released[user] = 0;
            }
            emit AddFundEvent(poolId, user, fundAmount);
        }
    }

    function removeFunds(
        uint256 poolId,
        address[] memory users
    ) external nonReentrant onlyAdmin {
        Pool storage pool = pools[poolId];
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 oldFund = pool.funds[user];
            if (oldFund > 0) {
                pool.funds[user] = 0;
                pool.released[user] = 0;
                pool.fundsTotal = pool.fundsTotal.sub(oldFund);
                pool.tokenFund.transfer(_msgSender(), oldFund);

                emit RemoveFundEvent(poolId, user);
            }
        }
    }

    function claimFund(uint256 poolId) external nonReentrant {
        _validateClaimFund(poolId);

        Pool storage pool = pools[poolId];
        uint256 _now = block.timestamp;
        require(_now >= pool.tge, "Invalid Time");
        uint256 claimPercent = computeClaimPercent(poolId, _now);
        require(claimPercent > 0, "Invalid value");

        uint256 claimTotal = (pool.funds[_msgSender()].mul(claimPercent)).div(
            ONE_HUNDRED_PERCENT_SCALED
        );
        require(claimTotal > pool.released[_msgSender()], "Invalid value");
        uint256 claimRemain = claimTotal.sub(pool.released[_msgSender()]);

        pool.tokenFund.transfer(_msgSender(), claimRemain);

        pool.released[_msgSender()] = pool.released[_msgSender()].add(
            claimRemain
        );
        pool.fundsClaimed = pool.fundsClaimed.add(claimRemain);

        emit ClaimFundEvent(poolId, _msgSender(), claimRemain);
    }

    function computeClaimPercent(
        uint256 poolId,
        uint256 _now
    ) public view returns (uint256) {
        Pool storage pool = pools[poolId];
        uint256[] memory milestoneTimes = pool.milestoneTimes;
        uint256[] memory milestonePercents = pool.milestonePercents;
        uint256 totalPercent = 0;
        uint256 tge = pool.tge;
        if (pool.vestingType == VESTING_TYPE_MILESTONE_CLIFF_FIRST) {
            if (_now >= tge.add(pool.cliff)) {
                totalPercent = totalPercent.add(pool.unlockPercent);
                for (uint i = 0; i < milestoneTimes.length; i++) {
                    uint256 milestoneTime = milestoneTimes[i];
                    uint256 milestonePercent = milestonePercents[i];
                    if (_now >= milestoneTime) {
                        totalPercent = totalPercent.add(milestonePercent);
                    }
                }
            }
        } else if (pool.vestingType == VESTING_TYPE_MILESTONE_UNLOCK_FIRST) {
            if (_now >= tge) {
                totalPercent = totalPercent.add(pool.unlockPercent);
                if (_now >= tge.add(pool.cliff)) {
                    for (uint i = 0; i < milestoneTimes.length; i++) {
                        uint256 milestoneTime = milestoneTimes[i];
                        uint256 milestonePercent = milestonePercents[i];
                        if (_now >= milestoneTime) {
                            totalPercent = totalPercent.add(milestonePercent);
                        }
                    }
                }
            }
        } else if (pool.vestingType == VESTING_TYPE_LINEAR_UNLOCK_FIRST) {
            if (_now >= tge) {
                totalPercent = totalPercent.add(pool.unlockPercent);
                if (_now >= tge.add(pool.cliff)) {
                    uint256 delta = _now.sub(tge).sub(pool.cliff);
                    totalPercent = totalPercent.add(delta.mul(ONE_HUNDRED_PERCENT_SCALED.sub(pool.unlockPercent))
                    .div(pool.linearVestingDuration)
                    );
                }
            }
        } else if (pool.vestingType == VESTING_TYPE_LINEAR_CLIFF_FIRST) {
            if (_now >= tge.add(pool.cliff)) {
                totalPercent = totalPercent.add(pool.unlockPercent);
                uint256 delta = _now.sub(tge).sub(pool.cliff);
                totalPercent = totalPercent.add(
                    delta
                    .mul(ONE_HUNDRED_PERCENT_SCALED.sub(pool.unlockPercent))
                    .div(pool.linearVestingDuration)
                );
            }
        }
        return (totalPercent < ONE_HUNDRED_PERCENT_SCALED) ? totalPercent : ONE_HUNDRED_PERCENT_SCALED;
    }

    function getFundByUser(
        uint256 poolId,
        address user
    ) public view returns (uint256, uint256) {
        return (pools[poolId].funds[user], pools[poolId].released[user]);
    }

    function getInfoUserReward(
        uint256 poolId
    ) public view returns (uint256, uint256) {
        Pool storage pool = pools[poolId];
        uint256 tokenTotal = pool.fundsTotal;
        uint256 claimedTotal = pool.fundsClaimed;

        return (tokenTotal, claimedTotal);
    }

    function getPool(
        uint256 poolId
    )
    public
    view
    returns (
        address,
        string memory,
        uint8,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] memory,
        uint256[] memory,
        uint256,
        uint256,
        PoolState
    )
    {
        Pool storage pool = pools[poolId];
        return (
            address(pool.tokenFund),
            pool.name,
            pool.vestingType,
            pool.tge,
            pool.cliff,
            pool.unlockPercent,
            pool.linearVestingDuration,
            pool.milestoneTimes,
            pool.milestonePercents,
            pool.fundsTotal,
            pool.fundsClaimed,
            pool.state
        );
    }

    function _validateAddFund(
        uint256 poolId,
        uint256 fundAmount,
        address user
    ) private {
        require(fundAmount > 0, "Amount must be greater than zero");
    }

    function _validateRemoveFund(uint256 poolId, address user) private {
        require(
            pools[poolId].funds[user] > 0,
            "Amount must be greater than zero"
        );
    }

    function _validateClaimFund(uint256 poolId) private {
        Pool storage pool = pools[poolId];
        require(pool.state == PoolState.STARTING, "Invalid action");
        require(
            pool.funds[_msgSender()] > 0,
            "Amount must be greater than zero"
        );
        require(
            pool.funds[_msgSender()] > pool.released[_msgSender()],
            "All money has been claimed"
        );
    }

    function _validateSetup(
        uint8 vestingType,
        uint256 unlockPercent,
        uint256 tge,
        uint256 cliff,
        uint256 linearVestingDuration,
        uint256[] memory milestoneTimes,
        uint256[] memory milestonePercents
    ) private {
        require(
            vestingType >= VESTING_TYPE_MILESTONE_UNLOCK_FIRST &&
            vestingType <= VESTING_TYPE_LINEAR_CLIFF_FIRST,
            "Invalid action"
        );
        require(
            tge >= block.timestamp &&
            unlockPercent > 0 &&
            unlockPercent <= ONE_HUNDRED_PERCENT_SCALED &&
            cliff >= 0,
            "Invalid input parameter"
        );
        if (
            vestingType == VESTING_TYPE_MILESTONE_CLIFF_FIRST ||
            vestingType == VESTING_TYPE_MILESTONE_UNLOCK_FIRST
        ) {
            require(
                milestoneTimes.length == milestonePercents.length && milestoneTimes.length >= 0
                && linearVestingDuration >= 0, "Invalid vesting parameter");
            uint256 total = unlockPercent;
            uint256 curTime = 0;
            for (uint i = 0; i < milestoneTimes.length; i++) {
                total = total + milestonePercents[i];
                uint256 tmpTime = milestoneTimes[i];
                require(tmpTime >= tge + cliff && tmpTime > curTime, "Invalid input parameter");
                curTime = tmpTime;
            }
            require(
                total == ONE_HUNDRED_PERCENT_SCALED,
                "Invalid vesting parameter"
            );
        } else {
            require(milestoneTimes.length == 0 && milestonePercents.length == 0
            && (linearVestingDuration > 0 && linearVestingDuration < TEN_YEARS_IN_S),
                "Invalid vesting parameter"
            );
        }
    }
}