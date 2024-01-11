//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game OG Staking
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;
import "./ERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./ILL420OGToken.sol";
import "./ILL420Wallet.sol";

contract LL420OGStaking is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC1155HolderUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    /// @dev Address of OG Pass contract
    IERC1155Upgradeable public OG_PASS_CONTRACT;
    /// @dev Initial start bonus
    uint64 public constant START_BONUS = 6900;
    /// @dev OG Pass is ERC1155 and token id is `1`
    uint64 public constant OG_ID = 1;
    /// @dev OG pass staking reward is $4 HIGH per day, update in every 1/80 day
    uint64 public constant INITIAL_REWARD = 25;
    /// @dev calculate reward per each duration, 1080 seconds 1080 x 80 = 3600 * 24
    uint64 public constant DURATION = 1080;
    /// @dev divide a day with 80
    uint64 public constant TIME_FRAME = 80;
    /// @dev total staked og pass count
    uint256 public stakeCount;
    /// @dev Address of reward token address which should be set by LL420.
    address public rewardTokenAddress;
    /// @dev Address of OG token address
    address public ogTokenAddress;

    struct UserInfo {
        uint256 reward;
        uint256 lastCheckpoint;
    }

    /// @dev mapping from staker address to staked og pass balance
    mapping(address => uint256) private _balances;
    /// @dev mapping from staker address to reward and timestamp struct
    mapping(address => UserInfo) private _userInfo;

    /* ==================== Added slots ==================== */

    /// @dev Address of Wallet address which should be set by LL420.
    address public walletContractAddress;

    /* ==================== EVENTS ==================== */

    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event WithdrawToWallet(address indexed user, uint256 amount);
    event WithdrawToPoint(address indexed user, uint256 amount, uint256 timestamp);

    /* ==================== MODIFIERS ==================== */

    /* ==================== METHODS ==================== */

    /**
     * initialize contract with OG pass contract address
     * it will pause contract after initialized,
     * owner should unpause the contract manually
     *
     * @param _ogPass Address of OG pass contract
     */
    function initialize(address _ogPass) external initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __ERC1155Holder_init();
        OG_PASS_CONTRACT = IERC1155Upgradeable(_ogPass);

        _pause();
    }

    /**
     * @dev stake OG pass
     *
     * @param amount Amount of OG pass to stake
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Invalid amount");
        require(ogTokenAddress != address(0), "OG token address is not set yet");
        require(OG_PASS_CONTRACT.balanceOf(_msgSender(), OG_ID) >= amount, "Invalid balance");

        UserInfo storage user = _userInfo[_msgSender()];
        if (_balances[_msgSender()] > 0) {
            uint256 pending = _pendingReward(_msgSender());
            user.reward += pending;
        }
        user.lastCheckpoint = block.timestamp;

        _balances[_msgSender()] += amount;
        stakeCount += amount;
        OG_PASS_CONTRACT.safeTransferFrom(_msgSender(), address(this), OG_ID, amount, "");

        ILL420OGToken OG_TOKEN_CONTRACT = ILL420OGToken(ogTokenAddress);
        OG_TOKEN_CONTRACT.mint(_msgSender(), amount * 10**18);

        emit Stake(_msgSender(), amount);
    }

    /**
     * @dev unstake OG pass
     *
     * @param amount Amount of OG pass to unstake
     */
    function unstake(uint256 amount) external nonReentrant whenNotPaused {
        require(_balances[_msgSender()] >= amount, "Invalid amount");
        require(ogTokenAddress != address(0), "OG token address is not set yet");

        UserInfo storage user = _userInfo[_msgSender()];
        if (_balances[_msgSender()] > 0) {
            uint256 pending = _pendingReward(_msgSender());
            user.reward += pending;
        }
        user.lastCheckpoint = block.timestamp;

        OG_PASS_CONTRACT.safeTransferFrom(address(this), _msgSender(), OG_ID, amount, "");
        _balances[_msgSender()] -= amount;
        stakeCount -= amount;

        ILL420OGToken OG_TOKEN_CONTRACT = ILL420OGToken(ogTokenAddress);
        OG_TOKEN_CONTRACT.burn(_msgSender(), amount * 10**18);

        emit Unstake(_msgSender(), amount);
    }

    /**
     * @dev returns the daily reward
     */
    function userDailyReward(address _staker) external view returns (uint256) {
        require(_staker != address(0), "Wrong Address");

        return _balances[_staker] * INITIAL_REWARD * TIME_FRAME;
    }

    /**
     * @dev returns the current reward + pending reward of staker
     *
     * @param _staker Address of staker
     */
    function userReward(address _staker) external view returns (uint256) {
        require(_staker != address(0), "Wrong address");

        return _userInfo[_staker].reward + _pendingReward(_staker);
    }

    /**
     * @dev returns the staked OG pass balance of staker
     *
     * @param _staker Address of staker
     */
    function userBalance(address _staker) external view returns (uint256) {
        require(_staker != address(0), "Wrong address");

        return _balances[_staker];
    }

    /**
     * @dev Withdraw balance to in-game wallet
     */
    function withdrawToWallet(uint256 _amount) external nonReentrant {
        require(walletContractAddress != address(0), "Wallet Address is not set yet.");

        UserInfo storage user = _userInfo[_msgSender()];
        if (_balances[_msgSender()] > 0) {
            uint256 pending = _pendingReward(_msgSender());
            user.reward += pending;
        }

        require(user.reward > 0, "No reward to withdraw");
        require(user.reward >= _amount, "Not enough reward to withdraw");

        ILL420Wallet WALLET_CONTRACT = ILL420Wallet(walletContractAddress);
        WALLET_CONTRACT.deposit(_msgSender(), _amount);

        emit WithdrawToWallet(_msgSender(), _amount);

        user.reward -= _amount;
        user.lastCheckpoint = block.timestamp;
    }

    /**
     * @dev Withdraw balance to in-game breeding points.
     *
     * @param _amount Withdrawal amount
     */
    function withdrawToPoint(uint256 _amount) external nonReentrant {
        UserInfo storage user = _userInfo[_msgSender()];

        if (_balances[_msgSender()] > 0) {
            uint256 pending = _pendingReward(_msgSender());
            user.reward += pending;
        }
        require(user.reward > 0, "LL420BudStaking: No reward to withdraw");
        require(user.reward >= _amount, "No enough reward to withdraw");

        emit WithdrawToPoint(_msgSender(), _amount, block.timestamp);

        user.reward -= _amount;
        user.lastCheckpoint = block.timestamp;
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     */
    function _pendingReward(address _staker) internal view returns (uint256) {
        require(_staker != address(0), "Wrong address");

        UserInfo memory user = _userInfo[_staker];
        return ((block.timestamp - user.lastCheckpoint) / DURATION) * INITIAL_REWARD * _balances[_staker];
    }

    /* ==================== CALLBACK METHODS ==================== */

    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        require(operator == address(this), "invalid operator");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        revert("batches not accepted");
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev owner can unapuse the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev owner can set OG Pass contract address
     *
     * @param _address Address of new OG pass contract
     */
    function setOGAddress(address _address) external onlyOwner {
        OG_PASS_CONTRACT = IERC1155Upgradeable(_address);
    }

    /**
     * @dev Function allows to set HIGH token address.
     *
     * @param _address address of HIGH token address.
     */
    function setWalletContractAddress(address _address) external onlyOwner {
        require(_address != address(0), "Wallet contract address can't be zero ");
        walletContractAddress = _address;
    }

    /**
     * @dev Function allows to set OG token address.
     *
     * @param _token address of OG token address.
     */
    function setOGTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), "Token address can't be zero ");
        ogTokenAddress = _token;
    }
}
