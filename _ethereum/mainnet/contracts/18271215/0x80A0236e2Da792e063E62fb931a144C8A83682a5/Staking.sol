//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract Staking is Initializable, OwnableUpgradeable, PausableUpgradeable {
    uint256 public planId;
    IERC20Upgradeable public token;

    struct Plan {
        uint256 minAmount;
        uint256 maxAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 minLock;
        bool isActive;
    }

    struct UserStake {
        uint256 amount;
        uint256 planNo;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint256 => Plan) public plan;
    mapping(address => uint256) public userId;
    mapping(address => mapping(uint256 => UserStake)) public userStake;

    event StakePlanUpdated(uint256 _planId, Plan _plan, uint256 timestamp);
    event StakeCreated(
        address user,
        uint256 _userId,
        uint256 amount,
        uint256 _planId,
        uint256 endTime
    );
    event StakeRemoved(
        address user,
        uint256 _userId,
        uint256 amount,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _token) external initializer {
        require(_token != address(0), "Zero token address");
        __Pausable_init_unchained();
        __Ownable_init_unchained();

        token = IERC20Upgradeable(_token);
    }

    function createStakePlans(
        Plan[] calldata _plans
    ) external onlyOwner returns (bool) {
        require(_plans.length > 0, "Zero plans");
        for (uint i; i < _plans.length; ) {
            require(
                _plans[i].maxAmount > _plans[i].minAmount &&
                    _plans[i].minAmount >= 0,
                "Invalid min and max stake values"
            );

            require(
                _plans[i].endTime > _plans[i].startTime &&
                    _plans[i].startTime > block.timestamp,
                "Invalid start and end times"
            );

            plan[planId] = _plans[i];

            emit StakePlanUpdated(planId, _plans[i], block.timestamp);

            unchecked {
                ++planId;
                ++i;
            }
        }

        return true;
    }

    function updateStakePlans(
        uint256[] calldata _planIds,
        Plan[] calldata _plans
    ) external onlyOwner returns (bool) {
        for (uint i; i < _plans.length; ) {
            require(_planIds[i] < planId, "Invalid Plan Id");
            require(
                _plans[i].maxAmount > _plans[i].minAmount &&
                    _plans[i].minAmount >= 0,
                "Invalid min and max stake values"
            );

            plan[_planIds[i]] = _plans[i];

            emit StakePlanUpdated(_planIds[i], _plans[i], block.timestamp);

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function updateStakePlanStatus(
        uint256[] calldata _planIds,
        bool[] calldata _status
    ) external onlyOwner returns (bool) {
        for (uint i; i < _planIds.length; ) {
            require(_planIds[i] < planId, "Invalid Plan Id");
            plan[_planIds[i]].isActive = _status[i];

            emit StakePlanUpdated(
                _planIds[i],
                plan[_planIds[i]],
                block.timestamp
            );

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function createStake(
        uint256 _planId,
        uint256 amount
    ) external returns (bool) {
        require(_planId < planId, "Invalid Plan Id");
        Plan memory _plan = plan[_planId];
        require(_plan.isActive, "Plan disabled");
        require(
            amount <= _plan.maxAmount && amount >= _plan.minAmount,
            "Invalid stake amount"
        );
        require(
            block.timestamp >= _plan.startTime &&
                block.timestamp <= _plan.endTime,
            "Invalid stake time for this plan"
        );

        userStake[msg.sender][userId[msg.sender]] = UserStake(
            amount,
            _planId,
            block.timestamp,
            block.timestamp + _plan.minLock
        );
        userId[msg.sender]++;
        token.transferFrom(msg.sender, address(this), amount);
        emit StakeCreated(
            msg.sender,
            userId[msg.sender],
            amount,
            _planId,
            block.timestamp + _plan.minLock
        );
        return true;
    }

    function removeStake(uint256 _userId) external returns (bool) {
        require(_userId < userId[msg.sender], "Invalid user Id");
        UserStake memory _userStake = userStake[msg.sender][_userId];
        require(_userStake.amount > 0, "Invalid user stake Id");
        require(block.timestamp >= _userStake.endTime, "Can't withdraw early");
        token.transfer(msg.sender, _userStake.amount);
        delete userStake[msg.sender][_userId];
        emit StakeRemoved(
            msg.sender,
            _userId,
            _userStake.amount,
            block.timestamp
        );
        return true;
    }

    function userAllStakes(
        address _user
    ) external view returns (UserStake[] memory) {
        UserStake[] memory _userStakes = new UserStake[](userId[_user]);
        for (uint i; i < userId[_user]; ) {
            _userStakes[i] = userStake[_user][i];
            unchecked {
                ++i;
            }
        }
        return _userStakes;
    }

    function userStakes(
        address _user,
        uint256[] memory _userStakeIds
    ) external view returns (UserStake[] memory) {
        require(_userStakeIds.length > 0, "Zero array length");
        UserStake[] memory _userStakes = new UserStake[](_userStakeIds.length);
        for (uint i; i < _userStakeIds.length; ) {
            _userStakes[i] = userStake[_user][_userStakeIds[i]];
            unchecked {
                ++i;
            }
        }
        return _userStakes;
    }

    function userActiveStakesIds(
        address _user
    ) external view returns (uint256[] memory, uint256) {
        uint256[] memory _userIds = new uint256[](userId[_user]);
        uint256 j;
        for (uint i; i < userId[_user]; ) {
            if (userStake[_user][i].amount > 0) {
                _userIds[j] = i;
                j++;
            }
            unchecked {
                ++i;
            }
        }
        return (_userIds, j);
    }
}
