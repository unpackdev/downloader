// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

import "./AssetLib.sol";

import "./IStaking.sol";
import "./IStakingFactory.sol";
import "./IPancakePair.sol";

contract StakingFactory is AccessControl, ReentrancyGuard, IStakingFactory {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address public immutable YDR_TOKEN;
    address public immutable FACTORY;
    address public immutable DEX_ROUTER;
    address public immutable DEX_FACTORY;

    address public masterStaking;
    address[] public stakes;

    mapping(address => address) public pools;
    mapping(address => uint256) public rewardPerBlock;
    mapping(address => bool) internal _isAllowedToken;

    struct Reward {
        address token;
        uint256 rewardPerBlock;
    }

    event Deposit(address token, address sender, uint256 amount);
    event Withdraw(address token, address sender, uint256 amount);
    event StakeCreate(address token, address newStaking);
    event RewardAdded(Reward[] rewards, uint256 currentTimestamp);

    modifier onlyManagerOrAdmin {
        address sender = _msgSender();
        address factory = FACTORY;
        require(
            AccessControl(factory).hasRole(MANAGER_ROLE, sender) ||
                AccessControl(factory).hasRole(0x00, sender),
            "Access error"
        );
        _;
    }

    modifier onlyFactory {
        require(_msgSender() == FACTORY, "Access error");
        _;
    }

    modifier isInitialize {
        require(masterStaking != address(0), "Not initialized yet");
        _;
    }

    constructor(
        address ydrToken,
        address factory,
        address dexRouter,
        address dexFactory
    ) {
        YDR_TOKEN = ydrToken;
        FACTORY = factory;
        DEX_ROUTER = dexRouter;
        DEX_FACTORY = dexFactory;
        _isAllowedToken[ydrToken] = true;
    }

    /**
     * @notice Create stake with allowed index, lp index, ydr and ydr lp
     * @param token: address of token which must be allowed
     */
    function createStaking(address token) external onlyManagerOrAdmin isInitialize {
        require(token != address(0), "Input error");
        require(_isAllowedTokenCheck(token), "Wrong token");
        require(pools[token] == address(0), "Already create pool");
        address newStaking = Clones.clone(masterStaking);
        IStaking(newStaking).initialize(token);
        pools[token] = newStaking;
        IERC20(YDR_TOKEN).approve(newStaking, type(uint256).max);
        stakes.push(newStaking);
        emit StakeCreate(token, newStaking);
    }

    /**
     * @notice Input reward to stake
     * @param rewards: {address token, rewardPerBlock}
     */
    function inputReward(Reward[] calldata rewards) external onlyManagerOrAdmin isInitialize {
        for (uint256 i = 0; i < rewards.length; i++) {
            if (pools[rewards[i].token] != address(0)) {
                rewardPerBlock[rewards[i].token] = rewards[i].rewardPerBlock;
            }
        }
        emit RewardAdded(rewards, block.timestamp);
    }

    /**
     * @notice Add token to allowed token
     * @dev must call just from assetFactory
     * @param token: address of asset
     */
    function createPool(address token) external override onlyFactory {
        _isAllowedToken[token] = true;
    }

    /**
     * @notice Change master staking
     * @param newMasterStaking: address of new master staking
     */
    function changeMasterStaking(address newMasterStaking) external onlyManagerOrAdmin {
        require(masterStaking == address(0) && newMasterStaking != address(0), "Bad use");
        masterStaking = newMasterStaking;
    }

    /**
     * @notice Get stake count
     * @return stakes count
     */
    function getStakedCount() external view returns (uint256) {
        return stakes.length;
    }

    function _isAllowedTokenCheck(address token) private view returns (bool) {
        if (_isAllowedToken[token]) {
            return true;
        } else {
            address token0;
            try IPancakePair(token).token0() returns (address _token0) {
                token0 = _token0;
            } catch (bytes memory) {
                return false;
            }

            address token1;
            try IPancakePair(token).token1() returns (address _token1) {
                token1 = _token1;
            } catch (bytes memory) {
                return false;
            }

            address goodPair = IPancakeFactory(DEX_FACTORY).getPair(token0, token1);
            if (goodPair != token) {
                return false;
            }

            if (!_isAllowedToken[token0] && !_isAllowedToken[token1]) {
                return false;
            }

            return true;
        }
    }
}
