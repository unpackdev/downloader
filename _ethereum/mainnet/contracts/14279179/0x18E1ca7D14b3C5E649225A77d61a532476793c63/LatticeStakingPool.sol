// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract LatticeStakingPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct StakingPool {
        uint256 maxStakingAmountPerUser;
        uint256 totalAmountStaked;
        address[] usersStaked;
    }

    struct Project {
        string name;
        uint256 totalAmountStaked;
        uint256 numberOfPools;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    struct UserInfo {
        address userAddress;
        uint256 poolId;
        uint256 percentageOfTokensStakedInPool;
        uint256 amountOfTokensStakedInPool;
    }

    IERC20 public stakingToken;

    address private owner;

    Project[] public projects;

    /// @notice ProjectID => Pool ID => User Address => amountStaked
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        public userStakedAmount;

    /// @notice ProjectID => Pool ID => User Address => didUserWithdrawFunds
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public didUserWithdrawFunds;

    /// @notice ProjectID => Pool ID => StakingPool
    mapping(uint256 => mapping(uint256 => StakingPool)) public stakingPoolInfo;

    /// @notice ProjectName => isProjectNameTaken
    mapping(string => bool) public isProjectNameTaken;

    /// @notice ProjectName => ProjectID
    mapping(string => uint256) public projectNameToProjectId;

    event Deposit(
        address indexed _user,
        uint256 indexed _projectId,
        uint256 indexed _poolId,
        uint256 _amount
    );
    event Withdraw(
        address indexed _user,
        uint256 indexed _projectId,
        uint256 indexed _poolId,
        uint256 _amount
    );
    event PoolAdded(uint256 indexed _projectId, uint256 indexed _poolId);
    event ProjectDisabled(uint256 indexed _projectId);
    event ProjectAdded(uint256 indexed _projectId, string _projectName);

    constructor(IERC20 _stakingToken) {
        require(
            address(_stakingToken) != address(0),
            "constructor: _stakingToken must not be zero address"
        );

        owner = msg.sender;
        stakingToken = _stakingToken;
    }

    function addProject(
        string memory _name,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external {
        require(msg.sender == owner, "addNewProject: Caller is not the owner");
        require(
            bytes(_name).length > 0,
            "addNewProject: Project name cannot be empty string."
        );
        require(
            _startTimestamp >= block.timestamp,
            "addNewProject: startTimestamp is less than the current block timestamp."
        );
        require(
            _startTimestamp < _endTimestamp,
            "addNewProject: startTimestamp is greater than or equal to the endTimestamp."
        );
        require(
            !isProjectNameTaken[_name],
            "addNewProject: project name already taken."
        );

        Project memory project;
        project.name = _name;
        project.startTimestamp = _startTimestamp;
        project.endTimestamp = _endTimestamp;
        project.numberOfPools = 0;
        project.totalAmountStaked = 0;

        uint256 projectsLength = projects.length;
        projects.push(project);
        projectNameToProjectId[_name] = projectsLength;
        isProjectNameTaken[_name] = true;

        emit ProjectAdded(projectsLength, _name);
    }

    function addStakingPool(
        uint256 _projectId,
        uint256 _maxStakingAmountPerUser
    ) external {
        require(
            msg.sender == owner,
            "addStakingPool: Caller is not the owner."
        );
        require(
            _projectId < projects.length,
            "addStakingPool: Invalid project ID."
        );

        StakingPool memory stakingPool;
        stakingPool.maxStakingAmountPerUser = _maxStakingAmountPerUser;
        stakingPool.totalAmountStaked = 0;

        uint256 numberOfPoolsInProject = projects[_projectId].numberOfPools;
        stakingPoolInfo[_projectId][numberOfPoolsInProject] = stakingPool;
        projects[_projectId].numberOfPools =
            projects[_projectId].numberOfPools +
            1;

        emit PoolAdded(_projectId, projects[_projectId].numberOfPools);
    }

    function disableProject(uint256 _projectId) external {
        require(msg.sender == owner, "disableProject: Caller is not the owner");
        require(
            _projectId < projects.length,
            "disableProject: Invalid project ID."
        );

        projects[_projectId].endTimestamp = block.timestamp;

        emit ProjectDisabled(_projectId);
    }

    function deposit(
        uint256 _projectId,
        uint256 _poolId,
        uint256 _amount
    ) external nonReentrant {
        require(_amount > 0, "deposit: Amount not specified.");
        require(_projectId < projects.length, "deposit: Invalid project ID.");
        require(
            _poolId < projects[_projectId].numberOfPools,
            "deposit: Invalid pool ID."
        );
        require(
            block.timestamp <= projects[_projectId].endTimestamp,
            "deposit: Staking no longer permitted for this project."
        );
        require(
            block.timestamp >= projects[_projectId].startTimestamp,
            "deposit: Staking is not yet permitted for this project."
        );

        uint256 _userStakedAmount = userStakedAmount[_projectId][_poolId][
            msg.sender
        ];
        if (stakingPoolInfo[_projectId][_poolId].maxStakingAmountPerUser > 0) {
            require(
                _userStakedAmount.add(_amount) <=
                    stakingPoolInfo[_projectId][_poolId]
                        .maxStakingAmountPerUser,
                "deposit: Cannot exceed max staking amount per user."
            );
        }

        if (userStakedAmount[_projectId][_poolId][msg.sender] == 0) {
            stakingPoolInfo[_projectId][_poolId].usersStaked.push(msg.sender);
        }

        projects[_projectId].totalAmountStaked = projects[_projectId]
            .totalAmountStaked
            .add(_amount);

        stakingPoolInfo[_projectId][_poolId]
            .totalAmountStaked = stakingPoolInfo[_projectId][_poolId]
            .totalAmountStaked
            .add(_amount);

        userStakedAmount[_projectId][_poolId][msg.sender] = userStakedAmount[
            _projectId
        ][_poolId][msg.sender].add(_amount);

        stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        emit Deposit(msg.sender, _projectId, _poolId, _amount);
    }

    function withdraw(uint256 _projectId, uint256 _poolId)
        external
        nonReentrant
    {
        require(_projectId < projects.length, "withdraw: Invalid project ID.");
        require(
            _poolId < projects[_projectId].numberOfPools,
            "withdraw: Invalid pool ID."
        );
        require(
            block.timestamp > projects[_projectId].endTimestamp,
            "withdraw: Not yet permitted."
        );
        require(
            !didUserWithdrawFunds[_projectId][_poolId][msg.sender],
            "withdraw: User has already withdrawn funds for this pool."
        );

        uint256 _userStakedAmount = userStakedAmount[_projectId][_poolId][
            msg.sender
        ];
        require(_userStakedAmount > 0, "withdraw: No stake to withdraw.");
        didUserWithdrawFunds[_projectId][_poolId][msg.sender] = true;

        stakingToken.safeTransfer(msg.sender, _userStakedAmount);

        emit Withdraw(msg.sender, _projectId, _poolId, _userStakedAmount);
    }

    function getTotalStakingInfoForProjectPerPool(
        uint256 _projectId,
        uint256 _poolId,
        uint256 _pageNumber,
        uint256 _pageSize
    ) external view returns (UserInfo[] memory) {
        require(
            msg.sender == owner,
            "getTotalStakingInfoForProjectPerPool: Caller is not the owner."
        );
        require(
            _projectId < projects.length,
            "getTotalStakingInfoForProjectPerPool: Invalid project ID."
        );
        require(
            _poolId < projects[_projectId].numberOfPools,
            "getTotalStakingInfoForProjectPerPool: Invalid pool ID."
        );
        uint256 _usersStakedInPool = stakingPoolInfo[_projectId][_poolId]
            .usersStaked
            .length;
        require(
            _usersStakedInPool > 0,
            "getTotalStakingInfoForProjectPerPool: Nobody staked in this pool."
        );
        require(
            _pageSize > 0,
            "getTotalStakingInfoForProjectPerPool: Invalid page size."
        );
        require(
            _pageNumber > 0,
            "getTotalStakingInfoForProjectPerPool: Invalid page number."
        );
        uint256 _startIndex = _pageNumber.sub(1).mul(_pageSize);

        if (_pageNumber > 1) {
            require(
                _startIndex < _usersStakedInPool,
                "getTotalStakingInfoForProjectPerPool: Specified parameters exceed number of users in the pool."
            );
        }

        uint256 _endIndex = _pageNumber.mul(_pageSize);
        if (_endIndex > _usersStakedInPool) {
            _endIndex = _usersStakedInPool;
        }

        UserInfo[] memory _result = new UserInfo[](_endIndex.sub(_startIndex));
        uint256 _resultIndex = 0;

        for (uint256 i = _startIndex; i < _endIndex; i++) {
            UserInfo memory _userInfo;
            _userInfo.userAddress = stakingPoolInfo[_projectId][_poolId]
                .usersStaked[i];
            _userInfo.poolId = _poolId;
            _userInfo
                .percentageOfTokensStakedInPool = getPercentageAmountStakedByUserInPool(
                _projectId,
                _poolId,
                _userInfo.userAddress
            );

            _userInfo.amountOfTokensStakedInPool = getAmountStakedByUserInPool(
                _projectId,
                _poolId,
                _userInfo.userAddress
            );

            _result[_resultIndex] = _userInfo;
            _resultIndex = _resultIndex + 1;
        }

        return _result;
    }

    function numberOfProjects() external view returns (uint256) {
        return projects.length;
    }

    function numberOfPools(uint256 _projectId) external view returns (uint256) {
        require(
            _projectId < projects.length,
            "numberOfPools: Invalid project ID."
        );
        return projects[_projectId].numberOfPools;
    }

    function getTotalAmountStakedInProject(uint256 _projectId)
        external
        view
        returns (uint256)
    {
        require(
            _projectId < projects.length,
            "getTotalAmountStakedInProject: Invalid project ID."
        );

        return projects[_projectId].totalAmountStaked;
    }

    function getTotalAmountStakedInPool(uint256 _projectId, uint256 _poolId)
        external
        view
        returns (uint256)
    {
        require(
            _projectId < projects.length,
            "getTotalAmountStakedInPool: Invalid project ID."
        );
        require(
            _poolId < projects[_projectId].numberOfPools,
            "getTotalAmountStakedInPool: Invalid pool ID."
        );

        return stakingPoolInfo[_projectId][_poolId].totalAmountStaked;
    }

    function getAmountStakedByUserInPool(
        uint256 _projectId,
        uint256 _poolId,
        address _address
    ) public view returns (uint256) {
        require(
            _projectId < projects.length,
            "getAmountStakedByUserInPool: Invalid project ID."
        );
        require(
            _poolId < projects[_projectId].numberOfPools,
            "getAmountStakedByUserInPool: Invalid pool ID."
        );

        return userStakedAmount[_projectId][_poolId][_address];
    }

    function getPercentageAmountStakedByUserInPool(
        uint256 _projectId,
        uint256 _poolId,
        address _address
    ) public view returns (uint256) {
        require(
            _projectId < projects.length,
            "getPercentageAmountStakedByUserInPool: Invalid project ID."
        );
        require(
            _poolId < projects[_projectId].numberOfPools,
            "getPercentageAmountStakedByUserInPool: Invalid pool ID."
        );

        return
            userStakedAmount[_projectId][_poolId][_address].mul(1e8).div(
                stakingPoolInfo[_projectId][_poolId].totalAmountStaked
            );
    }
}
