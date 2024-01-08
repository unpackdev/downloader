// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "./GROBaseVester.sol";

interface ICommunityVester {
    function totalLockedAmount() external view returns (uint256);
}

/// @notice Vesting contract for the GRO DAO - This vesting contract can
///     create vesting positions from both the DAO and community quota and also has
///     The ability to create instantaniously vesting positions. The later has to be
///     done behing a timelock contract, and users are encouraged to check that the
///     TIME_LOCK variable links to a verified timelock contract
contract GRODaoVesting is GROBaseVesting {
    // Contract cannot create vesting positions for the first week after
    //  deployment, this stops a vesting contract with a fake time lock to
    //  insta mint the community QUOTA to itself without anyone being able to react.
    uint256 private constant COOLDOWN = 604800;
    uint256 private immutable deploymentTime;

    struct DaoPosition {
        uint256 total;
        uint256 withdrawn;
        uint256 startTime;
        uint256 endTime;
        uint256 cliff;
        bool community;
    }

    // !Important! Time lock contract
    address public immutable TIME_LOCK;
    // Community quota
    uint256 public immutable COMMUNITY_QUOTA;

    mapping(address => DaoPosition) public daoPositions;
    uint256 private _vestingCommunity;

    // The main community vester, used to read current vesting amount ensure that position that draw from community funds
    //  are not exceeding the community qouta.
    address public communityVester;

    event LogNewVest(address indexed dao, uint256 amount, bool community);
    event LogClaimed(address indexed dao, uint256 amount, uint256 withdrawn, uint256 available, bool community);
    event LogPositionRemoved(address account, uint256 amount, uint256 withdrawn, bool community);
    event LogPositionHalted(address account, uint256 amount, uint256 withdrawn, uint256 available, bool community);
    event LogNewCommunityVester(address communityVester);

    constructor(
        uint256 startTime,
        uint256 quotaDao,
        uint256 quotaCommunity,
        address dao,
        address timeLock
    ) GROBaseVesting(startTime, quotaDao) {
        transferOwnership(dao);
        TIME_LOCK = timeLock;
        COMMUNITY_QUOTA = quotaCommunity;
        deploymentTime = block.timestamp;
    }

    /// @notice set the community vester contract
    /// @param newVester address of community vester
    function setCommunityVester(address newVester) external onlyOwner {
        communityVester = newVester;
        emit LogNewCommunityVester(newVester);
    }

    /// @notice how much assets is vesting in the community vester + the dao vester
    function vestingCommunity() public view returns (uint256) {
        return _vestingCommunity + ICommunityVester(communityVester).totalLockedAmount();
    }

    /// @notice Create a vesting position - uses default vesting paramers from base contract
    /// @param account Account which to add vesting position for
    /// @param amount Amount to add to vesting position
    function baseVest(address account, uint256 amount) external onlyOwner {
        require(block.timestamp > deploymentTime + COOLDOWN, "vest: cannot create a vesting position yet");
        require(account != address(0), "vest: !account");
        require(amount > 0, "vest: !amount");

        DaoPosition storage dp = daoPositions[account];

        require(dp.startTime == 0, "vest: position already exists");
        require((QUOTA - vestingAssets) >= amount, "vest: not enough assets available");
        dp.startTime = block.timestamp;
        dp.endTime = block.timestamp + VESTING_TIME;
        dp.cliff = block.timestamp + VESTING_CLIFF;
        dp.total = amount;
        vestingAssets += amount;

        emit LogNewVest(account, amount, false);
    }

    function vest(
        address account,
        uint256 startDate,
        uint256 amount
    ) external override {}

    /// @notice remove a vesting position
    /// @param account Account which to remove vesting position for
    /// @dev this effectively nulifies the position, no more assets can be withdrawn
    function removePosition(address account) external onlyOwner {
        DaoPosition memory dp = daoPositions[account];
        require(dp.startTime > 0, "removePosition: no position for user");
        delete daoPositions[account];
        bool community = dp.community;
        if (community) {
            _vestingCommunity -= (dp.total - dp.withdrawn);
        } else {
            vestingAssets -= (dp.total - dp.withdrawn);
        }
        emit LogPositionRemoved(account, dp.total, dp.withdrawn, community);
    }

    /// @notice halt a vesting position
    /// @param account Account which to remove vesting position for
    /// @dev this stops the posits, no more assets will vest, but what currently has
    ///     vested can be withdrawn
    function haltPosition(address account) external onlyOwner {
        DaoPosition storage dp = daoPositions[account];
        require(dp.startTime > 0, "haltPosition: no position for user");
        (uint256 unlocked, uint256 available, , ) = unlockedBalance(account);
        uint256 forfeited = dp.total - unlocked;
        bool community = dp.community;
        if (community) {
            _vestingCommunity -= forfeited;
        } else {
            vestingAssets -= forfeited;
        }
        dp.total = unlocked;
        dp.endTime = block.timestamp;
        emit LogPositionHalted(account, unlocked, dp.withdrawn, available, community);
    }

    /// @notice Create a custom vesting position
    /// @param account Account which to add vesting position for
    /// @param amount Amount to add to vesting position
    /// @param vestingTime custom vesting time for the vesting position
    /// @param vestingCliff custom cliff for the vesting position
    /// @param community is the position created from the DAO or community asset pool
    function customVest(
        address account,
        uint256 amount,
        uint256 vestingTime,
        uint256 vestingCliff,
        bool community
    ) external {
        require(block.timestamp > deploymentTime + COOLDOWN, "customVest: cannot create a vesting position yet");
        require(msg.sender == TIME_LOCK, "customVest: Can only create custom vest from timelock");
        require(account != address(0), "customVest: !account");
        require(amount > 0, "customVest: !amount");
        require(vestingTime >= vestingCliff, "customVest: _endDate < _cliff");

        DaoPosition storage dp = daoPositions[account];
        if (community) {
            require((COMMUNITY_QUOTA - vestingCommunity()) >= amount, "customVest: not enough assets available");
            _vestingCommunity += amount;
            dp.community = community;
        } else {
            require((QUOTA - vestingAssets) >= amount, "customVest: not enough assets available");
            vestingAssets += amount;
        }
        require(dp.startTime == 0, "customVest: position already exists");
        dp.startTime = block.timestamp;
        dp.endTime = block.timestamp + vestingTime;
        dp.cliff = block.timestamp + vestingCliff;
        dp.total = amount;

        emit LogNewVest(account, amount, community);
    }

    /// @notice Claim an amount of tokens
    function claim(uint256 amount) external override {
        require(amount > 0, "claim: No amount specified");
        (uint256 unlocked, uint256 available, , ) = unlockedBalance(msg.sender);
        require(available >= amount, "claim: Not enough user assets available");
        DaoPosition storage dp = daoPositions[msg.sender];

        // record contract withdrawals
        bool community = dp.community;

        // record account withdrawals
        uint256 _withdrawn = unlocked - available + amount;
        dp.withdrawn = _withdrawn;
        distributer.mintDao(msg.sender, amount, community);
        emit LogClaimed(msg.sender, amount, _withdrawn, available - amount, community);
    }

    /// @notice See the amount of vested assets the account has accumulated
    /// @param account Account to get vested amount for
    function unlockedBalance(address account)
        internal
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        DaoPosition storage dp = daoPositions[account];
        uint256 startTime = dp.startTime;
        uint256 endTime = dp.endTime;
        uint256 cliff = dp.cliff;
        if (block.timestamp <= cliff) {
            return (0, 0, startTime, endTime);
        }
        uint256 unlocked;
        uint256 available;
        if (block.timestamp < endTime) {
            unlocked = (dp.total * (block.timestamp - startTime)) / (endTime - startTime);
        } else {
            unlocked = dp.total;
        }
        available = unlocked - dp.withdrawn;
        return (unlocked, available, startTime, endTime);
    }

    /// @notice Get total size of position, vested + vesting
    /// @param account Target account
    function totalBalance(address account) external view override returns (uint256 balance) {
        DaoPosition storage dp = daoPositions[account];
        balance = dp.total;
    }
}
