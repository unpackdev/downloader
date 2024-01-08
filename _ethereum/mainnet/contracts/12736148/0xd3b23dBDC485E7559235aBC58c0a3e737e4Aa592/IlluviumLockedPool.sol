// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ILockedPool.sol";
import "./IERC20.sol";
import "./IlluviumAware.sol";
import "./TokenLocking.sol";
import "./Ownable.sol";

contract IlluviumLockedPool is ILockedPool, IlluviumAware {
    /**
     * @dev Smart contract unique identifier, a random number
     * @dev Should be regenerated each time smart contact source code is changed
     *      and changes smart contract itself is to be redeployed
     * @dev Generated using https://www.random.org/bytes/
     */
    uint256 public constant POOL_UID = 0x620bbda48b8ff3098da2f0033cbf499115c61efdd5dcd2db05346782df6218e7;

    // @dev Data struct to store information about locked token staker
    struct User {
        // @dev Total staked amount
        uint256 tokenAmount;
        // @dev Auxiliary variable for vault rewards calculation
        uint256 subVaultRewards;
    }

    /// @dev Link to deployed IlluviumVault instance
    address public override vault;

    /// @dev Link to deployed TokenLocking instance
    address public override tokenLocking;

    /// @dev Used to calculate vault rewards
    /// @dev This value is different from "reward per weight" used in other pools
    /// @dev Note: locked pool doesn't operate on weights since all stakes are equal in duration
    uint256 public override vaultRewardsPerToken;

    /// @dev Total value of ILV tokens available in the pool
    uint256 public override poolTokenReserve;

    /// @dev Locked pool stakers mapping, maps staker addr => staker data struct (User)
    mapping(address => User) public users;

    /**
     * @dev Rewards per token can be small values, usually fitting into (0, 1) bounds.
     *      We store these values multiplied by 1e12, as integers.
     */
    uint256 private constant REWARD_PER_TOKEN_MULTIPLIER = 1e12;

    /**
     * @dev Fired in _stake()
     *
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     */
    event Staked(address indexed _from, uint256 amount);

    /**
     * @dev Fired in _unstake()
     *
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     */
    event Unstaked(address indexed _to, uint256 amount);

    /**
     * @dev Fired in _processVaultRewards() and dependent functions, like processRewards()
     *
     * @param _by an address which executed the function
     * @param _to an address which received a reward
     * @param amount amount of reward received
     */
    event VaultRewardsClaimed(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in receiveVaultRewards()
     *
     * @param _by an address that sent the rewards, always a vault
     * @param amount amount of tokens received
     */
    event VaultRewardsReceived(address indexed _by, uint256 amount);

    /**
     * @dev Fired in setVault()
     *
     * @param _by an address which executed the function, always a factory owner
     */
    event VaultUpdated(address indexed _by, address _fromVal, address _toVal);

    /**
     * @dev Defines TokenLocking only access
     */
    modifier onlyTokenLocking() {
        // verify the access
        require(msg.sender == tokenLocking, "access denied");
        // execute rest of the function marked with the modifier
        _;
    }

    /**
     * @dev Deploys LockedPool linked to the previously deployed ILV token
     *      and TokenLocking addresses
     *
     * @param _ilv ILV ERC20 token instance deployed address
     * @param _tokenLocking TokenLocking instance deployed address the pool is bound to
     */
    constructor(address _ilv, address _tokenLocking) IlluviumAware(_ilv) {
        // verify the inputs
        require(_tokenLocking != address(0), "TokenLocking address is not set");

        // verify token locking smart contract is an expected one
        require(
            TokenLocking(_tokenLocking).LOCKING_UID() ==
                0x76ff776d518e4c1b71ef4a1af2227a94e9868d7c9ecfa08e9255d2360e18f347,
            "unexpected LOCKING_UID"
        );

        // internal state init
        tokenLocking = _tokenLocking;
    }

    /**
     * @dev Converts stake amount to ILV reward value, applying the 1e12 division on the token amount
     *      to correct for the fact that "rewards per token" are stored multiplied by 1e12
     *
     * @param _tokens amount of tokens to convert to reward
     * @param _rewardPerToken reward per token
     *      (this value is supplied multiplied by 1e12 and thus the need for division on the result)
     * @return _reward reward value normalized to 1e12
     */
    function tokensToReward(uint256 _tokens, uint256 _rewardPerToken) public pure returns (uint256 _reward) {
        // apply the formula and return
        return (_tokens * _rewardPerToken) / REWARD_PER_TOKEN_MULTIPLIER;
    }

    /**
     * @dev Derives reward per token given total reward and total tokens value
     *      Naturally the result would by just a division _reward/_tokens if not
     *      the requirement to store the result as an integer - therefore the result
     *      is represented multiplied by 1e12, as an integer
     *
     * @param _reward total amount of reward
     * @param _tokens total amount of tokens
     * @return _rewardPerToken reward per token (this value is returned multiplied by 1e12)
     */
    function rewardPerToken(uint256 _reward, uint256 _tokens) public pure returns (uint256 _rewardPerToken) {
        // apply the formula and return
        return (_reward * REWARD_PER_TOKEN_MULTIPLIER) / _tokens;
    }

    /**
     * @notice Calculates current vault rewards value available for address specified
     *
     * @dev Performs calculations based on current smart contract state only,
     *      not taking into account any additional time/blocks which might have passed
     *
     * @param _staker an address to calculate vault rewards value for
     * @return pending calculated vault reward value for the given address
     */
    function pendingVaultRewards(address _staker) public view override returns (uint256 pending) {
        User memory user = users[_staker];

        return tokensToReward(user.tokenAmount, vaultRewardsPerToken) - user.subVaultRewards;
    }

    /**
     * @dev Returns locked holder staked balance
     *
     * @param _staker address to check locked tokens balance
     */
    function balanceOf(address _staker) external view override returns (uint256 balance) {
        balance = users[_staker].tokenAmount;
    }

    /**
     * @dev Executed only by the factory owner to Set the vault
     *
     * @param _vault an address of deployed IlluviumVault instance
     */
    function setVault(address _vault) external {
        // verify function is executed by the factory owner
        require(Ownable(tokenLocking).owner() == msg.sender, "access denied");

        // verify input is set
        require(_vault != address(0), "zero input");

        // emit an event
        emit VaultUpdated(msg.sender, vault, _vault);

        // update vault address
        vault = _vault;
    }

    /**
     * @dev Executed by the TokenLocking instance to stake
     *      locked tokens on behalf of their holders
     *
     * @param _staker locked tokens holder address
     * @param _amount amount of the tokens staked
     */
    function stakeLockedTokens(address _staker, uint256 _amount) external override onlyTokenLocking {
        _stake(_staker, _amount);
    }

    /**
     * @dev Executed by the TokenLocking instance to unstake
     *      locked tokens on behalf of their holders
     *
     * @param _staker locked tokens holder address
     * @param _amount amount of the tokens to be unstaked
     */
    function unstakeLockedTokens(address _staker, uint256 _amount) external override onlyTokenLocking {
        _unstake(_staker, _amount);
    }

    /**
     * @dev Calculates vault rewards for the transaction sender and sends these rewards immediately
     *
     * @dev calls internal _processVaultRewards and passes _staker as msg.sender
     */
    function processVaultRewards() external {
        _processVaultRewards(msg.sender);
    }

    /**
     * @dev Executed by the vault to transfer vault rewards ILV from the vault
     *      into the pool
     *
     * @param _rewardsAmount amount of ILV rewards to transfer into the pool
     */
    function receiveVaultRewards(uint256 _rewardsAmount) external override {
        require(msg.sender == vault, "access denied");
        // return silently if there is no reward to receive
        if (_rewardsAmount == 0) {
            return;
        }
        require(poolTokenReserve > 0, "zero reserve");

        transferIlvFrom(msg.sender, address(this), _rewardsAmount);

        vaultRewardsPerToken += rewardPerToken(_rewardsAmount, poolTokenReserve);
        poolTokenReserve += _rewardsAmount;

        emit VaultRewardsReceived(msg.sender, _rewardsAmount);
    }

    /**
     * @dev Executed by token locking contract, by changing a locked token owner
     *      after verifying the signature.
     * @dev Inputs are validated by the caller - TokenLocking smart contract
     *
     * @param _from account to move tokens from
     * @param _to account to move tokens to
     */
    function changeLockedHolder(address _from, address _to) external override onlyTokenLocking {
        users[_to] = users[_from];
        delete users[_from];
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     */
    function _stake(address _staker, uint256 _amount) private {
        // validate the inputs
        require(_amount > 0, "zero amount");
        _processVaultRewards(_staker);

        User storage user = users[_staker];
        user.tokenAmount += _amount;
        poolTokenReserve += _amount;
        user.subVaultRewards = tokensToReward(user.tokenAmount, vaultRewardsPerToken);

        // emit an event
        emit Staked(_staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     * @param _amount amount of tokens to unstake
     */
    function _unstake(address _staker, uint256 _amount) private {
        // verify an amount is set
        require(_amount > 0, "zero amount");
        User storage user = users[_staker];
        require(user.tokenAmount >= _amount, "not enough balance");
        _processVaultRewards(_staker);
        user.tokenAmount -= _amount;
        poolTokenReserve -= _amount;
        user.subVaultRewards = tokensToReward(user.tokenAmount, vaultRewardsPerToken);

        // emit an event
        emit Unstaked(_staker, _amount);
    }

    /**
     * @dev Calculates vault rewards for the `_staker` and sends these rewards immediately
     *
     * @dev Used internally to process vault rewards for the staker
     *
     * @param _staker address of the user (staker) to process rewards for
     */
    function _processVaultRewards(address _staker) private {
        User storage user = users[_staker];
        uint256 pendingVaultClaim = pendingVaultRewards(_staker);
        if (pendingVaultClaim == 0) return;
        // read ILV token balance of the pool via standard ERC20 interface
        uint256 ilvBalance = IERC20(ilv).balanceOf(address(this));
        require(ilvBalance >= pendingVaultClaim, "contract ILV balance too low");
        // protects against rounding errors
        poolTokenReserve -= pendingVaultClaim > poolTokenReserve ? poolTokenReserve : pendingVaultClaim;

        user.subVaultRewards = tokensToReward(user.tokenAmount, vaultRewardsPerToken);

        transferIlv(_staker, pendingVaultClaim);

        emit VaultRewardsClaimed(msg.sender, _staker, pendingVaultClaim);
    }
}
