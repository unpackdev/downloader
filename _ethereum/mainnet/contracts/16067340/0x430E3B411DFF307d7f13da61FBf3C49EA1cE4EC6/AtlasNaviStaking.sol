// SPDX-License-Identifier: NO LICENSE

pragma solidity ^0.8.9;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IAtlasNaviERC1155.sol";

contract AtlasNaviStaking is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20;

    uint256 public constant PACKAGE_TYPE_1 = 1;
    uint256 public constant PACKAGE_TYPE_2 = 2;

    struct Package {
        uint256 stakingStartTime;
        uint256 stakingEndTime;
        uint256 stakingMinPeriod;
        uint256 rewardEndTime;
        uint256 minAmount;
        uint256 penaltyPercentage;
    }

    struct Stake {
        uint8 packageId;
        uint48 stakingTime;
        uint48 unstakingTime;
        uint128 amount;
    }

    IERC20 public atlasNaviERC20;
    IAtlasNaviERC1155 public atlasNaviERC1155;

    Package[] public packages;
    mapping(address => Stake[]) public userStakes;

    /**
     * The call must be made after the startTime
     */
    error CallBeforeStartTime();

    /**
     * The call must be made before the endTime
     */
    error CallAfterEndTime();

    /**
     * The stake amount must be valid
     */
    error StakeAmountInvalid();

    /**
     * The stake must be unstaked
     */
    error StakeAlreadyUnstaked();

    /**
     * The reward type must be valid
     */
    error PackageInvalid();

    event Staked(address indexed userAddress, uint256 stakeId);

    event Unstaked(address indexed userAddress, uint256 stakeId);

    /** INITIALIZE */

    /**
     * instantiates contract
     * @param _atlasNaviERC20Address        the address of the atlasNaviERC20 token
     * @param _atlasNaviERC1155Address      the address of the atlasNaviERC1155 contract
     * @param _startTime                    the tge timestamp
     */
    function initialize(
        address _atlasNaviERC20Address,
        address _atlasNaviERC1155Address,
        uint256 _startTime
    ) external initializer {
        __Ownable_init();
        __Pausable_init();

        atlasNaviERC20 = IERC20(_atlasNaviERC20Address);
        atlasNaviERC1155 = IAtlasNaviERC1155(_atlasNaviERC1155Address);

        packages.push();
        packages.push();
        packages.push();

        packages[PACKAGE_TYPE_1].stakingStartTime = _startTime;
        packages[PACKAGE_TYPE_1].stakingEndTime = _startTime + 15552000; // 6 months
        packages[PACKAGE_TYPE_1].stakingMinPeriod = 31536000; // one year
        packages[PACKAGE_TYPE_1].rewardEndTime = 0; // not used for PACKAGE_TYPE_1
        packages[PACKAGE_TYPE_1].minAmount = 1000e18;
        packages[PACKAGE_TYPE_1].penaltyPercentage = 25;

        packages[PACKAGE_TYPE_2].stakingStartTime = _startTime;
        packages[PACKAGE_TYPE_2].stakingEndTime = _startTime + 44064000; // 17 months
        packages[PACKAGE_TYPE_2].stakingMinPeriod = 2592000; // one month
        packages[PACKAGE_TYPE_2].rewardEndTime = _startTime + 46656000; // 18 months
        packages[PACKAGE_TYPE_2].minAmount = 1000e18;
        packages[PACKAGE_TYPE_2].penaltyPercentage = 25;
    }

    function userStakesLength(address _userAddress) external view returns (uint256) {
        return userStakes[_userAddress].length;
    }

    function stake(uint256 _packageId, uint256 _amount) external whenNotPaused {
        if (_packageId < PACKAGE_TYPE_1 || _packageId > PACKAGE_TYPE_2) {
            revert PackageInvalid();
        }

        Package memory _package = packages[_packageId];

        if (block.timestamp < _package.stakingStartTime) {
            revert CallBeforeStartTime();
        }

        if (block.timestamp > _package.stakingEndTime) {
            revert CallAfterEndTime();
        }

        if (_amount < _package.minAmount) {
            revert StakeAmountInvalid();
        }

        atlasNaviERC20.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _userStakesLength = userStakes[msg.sender].length;

        Stake memory _stake;
        _stake.packageId = uint8(_packageId);
        _stake.amount = uint128(_amount);
        _stake.stakingTime = uint48(block.timestamp);

        userStakes[msg.sender].push(_stake);

        emit Staked(msg.sender, _userStakesLength);
    }

    function unstake(uint256 _stakeId) external whenNotPaused {
        Stake storage _stake = userStakes[msg.sender][_stakeId];

        if (_stake.unstakingTime > 0) {
            revert StakeAlreadyUnstaked();
        }

        _stake.unstakingTime = uint48(block.timestamp);

        (uint256 _atlasNaviERC20Amount, uint256 _atlasNaviERC1155Amount) = _calculateRewards(msg.sender, _stakeId);

        atlasNaviERC20.safeTransfer(msg.sender, _atlasNaviERC20Amount);

        if (_atlasNaviERC1155Amount > 0) {
            atlasNaviERC1155.mint(msg.sender, _atlasNaviERC1155Amount);
        }

        emit Unstaked(msg.sender, _stakeId);
    }

    function userStakesInfo(address _userAddress, uint256 _stakeId)
        external view returns (
            uint256 packageId,
            uint256 amount,
            uint256 stakingTime,
            uint256 unstakingTime,
            uint256 atlasNaviERC20Amount,
            uint256 atlasNaviERC1155Amount
    ) {
        Stake memory _stake = userStakes[_userAddress][_stakeId];

        packageId = _stake.packageId;
        amount = _stake.amount;
        stakingTime = _stake.stakingTime;
        unstakingTime = _stake.unstakingTime;
        (atlasNaviERC20Amount, atlasNaviERC1155Amount) = _calculateRewards(_userAddress, _stakeId);
    }

    /** OWNER */

    /**
     * @notice enables owner to pause / unpause stake and unstake methods
     * @param paused   true / false for pausing / unpausing minting
     */
    function setPaused(bool paused) external onlyOwner {
        if (paused)  {
            _pause();
        } else {
            _unpause();
        }
    }

    function updatePackage(
        uint256 _packageId,
        uint256 _stakingStartTime,
        uint256 _stakingEndTime,
        uint256 _stakingMinPeriod,
        uint256 _rewardEndTime,
        uint256 _minAmount,
        uint256 _penaltyPercentage
    ) external onlyOwner {
        if (_packageId < PACKAGE_TYPE_1 || _packageId > PACKAGE_TYPE_2) {
            revert PackageInvalid();
        }

        Package storage _package = packages[_packageId];

        _package.stakingStartTime = _stakingStartTime;
        _package.stakingEndTime = _stakingEndTime;
        _package.stakingMinPeriod = _stakingMinPeriod;
        _package.rewardEndTime = _rewardEndTime;
        _package.minAmount = _minAmount;
        _package.penaltyPercentage = _penaltyPercentage;
    }

    function _calculateRewards(address _userAddress, uint256 _stakeId)
        internal view returns (uint256 atlasNaviERC20Amount, uint256 atlasNaviERC1155Amount)
    {
        Stake memory _stake = userStakes[_userAddress][_stakeId];

        uint256 _unstakingTime = _stake.unstakingTime > 0 ? _stake.unstakingTime : block.timestamp;

        Package memory _package = packages[_stake.packageId];

        if (_stake.stakingTime + _package.stakingMinPeriod > _unstakingTime) {
            atlasNaviERC20Amount = _stake.amount * (100 - _package.penaltyPercentage) / 100;
        } else if (_stake.packageId == PACKAGE_TYPE_1) {
            atlasNaviERC20Amount = _stake.amount * 3 / 2; //50% reward
        } else {
            atlasNaviERC20Amount = _stake.amount;
            uint256 _rewardEndTime = _unstakingTime < _package.rewardEndTime ? _unstakingTime : _package.rewardEndTime;
            uint256 _numberOfStakes = _stake.amount / _package.minAmount;
            uint256 _numberOfMonths = (_rewardEndTime - _stake.stakingTime) / _package.stakingMinPeriod; //one months

            atlasNaviERC1155Amount = _numberOfStakes * _numberOfMonths;
        }
    }
}
