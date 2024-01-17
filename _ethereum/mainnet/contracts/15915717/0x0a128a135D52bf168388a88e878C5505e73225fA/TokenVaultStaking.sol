// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./SettingStorage.sol";
import "./ERC20Upgradeable.sol";
import "./Counters.sol";
import "./OwnableUpgradeable.sol";
import "./ITreasury.sol";
import "./IBnft.sol";
import "./IVault.sol";
import "./Errors.sol";
import "./DataTypes.sol";
import "./TokenVaultStakingLogic.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";
import "./TransferHelper.sol";

contract TokenVaultStaking is
    SettingStorage,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    uint256 constant REWARD_PER_SHARE_PRECISION = 10**24;
    /// @notice vaultToken
    address public vaultToken;

    /// @notice Array of tokens that users can claim
    IERC20[] public rewardTokens;
    mapping(IERC20 => bool) public isRewardToken;
    mapping(IERC20 => DataTypes.RewardInfo) public rewardInfos;

    using Counters for Counters.Counter;

    Counters.Counter stakingId;

    /** @dev Mapping from pool - total amount in pool */
    mapping(uint256 => uint256) public poolBalances;
    /** @dev Mapping from stakingID - stakinginfo*/
    mapping(uint256 => DataTypes.StakingInfo) public stakingInfos;
    /** @dev Mapping from poolId - pollinfo*/
    mapping(uint256 => DataTypes.PoolInfo) public poolInfos;
    /** @dev store convert main token to ve token*/
    mapping(address => uint256) public userFTokens;
    uint256 public totalUserFToken;
    //
    uint256 public changingBalance;
    /// @notice  gap for reserve, minus 1 if use
    uint256[10] public __gapUint256;
    /// @notice  gap for reserve, minus 1 if use
    uint256[5] public __gapAddress;

    /// @notice Emitted when owner removes a token from the reward tokens list
    event RewardTokenRemoved(address token);

    /// @notice Emitted when owner adds a token to the reward tokens list
    event RewardTokenAdded(address token);

    event Deposited(
        address staker,
        uint256 poolId,
        uint256 sId,
        uint256 amount
    );

    event ConvertVeToken(address sender, uint256 amount);
    event RedeemVeToken(address sender, uint256 amount);

    event Withdraw(address staker, uint256 poolId, uint256 sId, uint256 amount);

    constructor(address _settings)
        SettingStorage(_settings)
        ERC20Upgradeable()
    {}

    function initialize(
        string memory _veSymbol,
        string memory _veName,
        uint256 _totalSupply,
        address _vaultToken,
        uint256 _p1Duration,
        uint256 _p2Duration
    ) public initializer {
        __ERC20_init(_veName, _veSymbol);
        __Ownable_init();
        __ERC20Permit_init_unchained(_veName);
        // update data
        require(_vaultToken != address(0), "no zero address");
        vaultToken = _vaultToken;
        uint256 p1Ratio = (10000 * _p1Duration) / (_p1Duration + _p2Duration);

        uint256 p2Ratio = 10000 - p1Ratio;
        poolInfos[1] = DataTypes.PoolInfo(p1Ratio, _p1Duration);
        poolInfos[2] = DataTypes.PoolInfo(p2Ratio, _p2Duration);

        poolBalances[1] = 0;
        poolBalances[2] = 0;

        _mint(address(this), _totalSupply);
    }

    function getStakingTotal() external view returns (uint256) {
        return poolBalances[1] + poolBalances[2];
    }

    modifier validPool(uint256 poolId) {
        require(
            poolId == 1 || poolId == 2,
            Errors.VAULT_STAKING_INVALID_POOL_ID
        );
        _;
    }

    /**
     * @notice Get the number of reward tokens
     * @return The length of the array
     */
    function rewardTokensLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    /**
     * @notice Add a reward token
     * @param _addr The address of the reward token
     */
    function addRewardToken(address _addr) external onlyOwner {
        IERC20 _rewardToken = IERC20(_addr);
        require(
            !isRewardToken[_rewardToken] && address(_rewardToken) != address(0),
            Errors.VAULT_REWARD_TOKEN_INVALID
        );
        require(rewardTokens.length < 25, Errors.VAULT_REWARD_TOKEN_MAX);

        rewardTokens.push(_rewardToken);
        isRewardToken[_rewardToken] = true;

        DataTypes.RewardInfo storage rewardInfo = rewardInfos[_rewardToken];
        rewardInfo.currentBalance = 0;
        rewardInfo.sharedPerTokensByPool[1] = REWARD_PER_SHARE_PRECISION;
        rewardInfo.sharedPerTokensByPool[2] = REWARD_PER_SHARE_PRECISION;

        emit RewardTokenAdded(address(_rewardToken));
    }

    /**
     * @notice Remove a reward token
     * @param _rewardToken The address of the reward token
     */
    function removeRewardToken(IERC20 _rewardToken) external onlyOwner {
        require(isRewardToken[_rewardToken], Errors.VAULT_REWARD_TOKEN_INVALID);
        isRewardToken[_rewardToken] = false;
        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            if (rewardTokens[i] == _rewardToken) {
                rewardTokens[i] = rewardTokens[_len - 1];
                rewardTokens.pop();
                break;
            }
        }
        emit RewardTokenRemoved(address(_rewardToken));
    }

    /**
     * update share reward all reward token
     */
    function updateSharedPerToken() public {
        // share
        ITreasury(IVault(vaultToken).treasury()).shareTreasuryRewardToken();
        //
        uint256 principalBalance = poolBalances[1] + poolBalances[2];
        if (principalBalance > 0) {
            uint256 _len = rewardTokens.length;
            for (uint256 i; i < _len; i++) {
                IERC20 _token = rewardTokens[i];
                uint256 newBalance = _token.balanceOf(address(this));
                // check staking token
                if (address(_token) == address(vaultToken)) {
                    require(
                        newBalance >= totalUserFToken,
                        Errors.VAULT_STAKING_INVALID_BALANCE
                    );
                    newBalance = newBalance - totalUserFToken;
                    require(
                        newBalance >= principalBalance,
                        Errors.VAULT_STAKING_INVALID_BALANCE
                    );
                    newBalance -= principalBalance;
                }
                require(
                    newBalance >= rewardInfos[_token].currentBalance,
                    Errors.VAULT_STAKING_INVALID_BALANCE
                );
                uint256 rewardAmt = newBalance -
                    rewardInfos[_token].currentBalance;
                if (rewardAmt > 0) {
                    uint256 newSharedPerTokenPool1;
                    uint256 newSharedPerTokenPool2;
                    (
                        newSharedPerTokenPool1,
                        newSharedPerTokenPool2
                    ) = TokenVaultStakingLogic.estimateNewSharedRewardAmount(
                        DataTypes.EstimateNewSharedRewardAmount({
                            newRewardAmt: rewardAmt,
                            poolBalance1: poolBalances[1],
                            ratio1: poolInfos[1].ratio,
                            poolBalance2: poolBalances[2],
                            ratio2: poolInfos[2].ratio
                        })
                    );
                    if (newSharedPerTokenPool1 > 0) {
                        rewardInfos[_token].sharedPerTokensByPool[
                                1
                            ] += newSharedPerTokenPool1;
                    }
                    if (newSharedPerTokenPool2 > 0) {
                        rewardInfos[_token].sharedPerTokensByPool[
                                2
                            ] += newSharedPerTokenPool2;
                    }
                    rewardInfos[_token].currentBalance = newBalance;
                }
            }
        }
    }

    /**
     * for deposit staking token
     */
    function deposit(uint256 amount, uint256 poolId)
        external
        validPool(poolId)
    {
        require(!ITreasury(IVault(vaultToken).treasury()).isEnded(), "ended");
        require(amount > 0, "zero amount");
        //
        changingBalance = amount;
        //
        // update share per token
        updateSharedPerToken();
        //create staking info
        stakingId.increment();
        uint256 sId = stakingId.current();
        //transfer vetoken to msg.sender
        _transfer(address(this), msg.sender, amount);
        //transfer token
        uint256 tokenAmt = amount;
        IVault(vaultToken).permitTransferFrom(
            msg.sender,
            address(this),
            tokenAmt
        );
        //
        DataTypes.StakingInfo storage stakingInfo = stakingInfos[sId];
        stakingInfo.staker = msg.sender;
        stakingInfo.poolId = poolId;
        stakingInfo.amount = tokenAmt;
        stakingInfo.createdTime = block.timestamp;
        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            IERC20 _token = rewardTokens[i];
            stakingInfo.sharedPerTokens[_token] = rewardInfos[_token]
                .sharedPerTokensByPool[poolId];
        }
        //update poolBalances
        poolBalances[poolId] += tokenAmt;
        //
        _mintBnft(msg.sender);
        //
        changingBalance = 0;
        //
        emit Deposited(msg.sender, poolId, sId, amount);
    }

    /**
     * for withdraw staking token
     */
    function withdraw(uint256 sId, uint256 amount) external {
        require(amount > 0, "zero amount");
        //
        changingBalance = amount;
        //
        uint256 tokenAmt = amount;
        require(stakingInfos[sId].amount >= tokenAmt, "invalid amount balance");
        require(stakingInfos[sId].staker == msg.sender, "invalid sender");
        uint256 poolId = stakingInfos[sId].poolId;
        require(
            (ITreasury(IVault(vaultToken).treasury()).isEnded() ||
                block.timestamp >=
                stakingInfos[sId].createdTime + poolInfos[poolId].duration),
            "invalid withdraw time"
        );
        // update share token
        updateSharedPerToken();
        //transfer vetoken from msg.sender to this contract
        _transfer(msg.sender, address(this), amount);
        //update pool balance
        poolBalances[poolId] -= tokenAmt;
        //update stakinginfo
        stakingInfos[sId].amount -= tokenAmt;
        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            IERC20 _token = rewardTokens[i];
            uint256 infoSharedPerToken = stakingInfos[sId].sharedPerTokens[
                _token
            ];
            if (infoSharedPerToken == 0) {
                infoSharedPerToken = REWARD_PER_SHARE_PRECISION;
            }
            uint256 rewardAmt = (
                (tokenAmt *
                    (rewardInfos[_token].sharedPerTokensByPool[poolId] -
                        infoSharedPerToken))
            ) / REWARD_PER_SHARE_PRECISION;
            uint256 withdrawAmt = rewardAmt;
            if (address(_token) == address(vaultToken)) {
                withdrawAmt += tokenAmt;
            }
            rewardInfos[_token].currentBalance -= rewardAmt;
            //transfer vaultToken
            if (withdrawAmt > 0) {
                bool success = _token.transfer(msg.sender, withdrawAmt);
                require(success, Errors.VAULT_WITHDRAW_TRANSFER_FAILED);
            }
        }
        if (stakingInfos[sId].amount == 0) {
            for (uint256 i; i < _len; i++) {
                IERC20 _token = rewardTokens[i];
                delete (stakingInfos[sId].sharedPerTokens[_token]);
            }
            delete (stakingInfos[sId]);
        }
        //
        changingBalance = 0;
        //
        _burnBnft(msg.sender);
        //
        emit Withdraw(msg.sender, poolId, sId, amount);
    }

    function estimateWithdrawAmount(
        uint256 sId,
        IERC20 _token,
        uint256 amount
    ) external view returns (uint256) {
        uint256 sharedPerToken1;
        uint256 sharedPerToken2;
        (sharedPerToken1, sharedPerToken2) = TokenVaultStakingLogic
            .getSharedPerToken(
                DataTypes.GetSharedPerTokenParams({
                    token: _token,
                    currentRewardBalance: rewardInfos[_token].currentBalance,
                    stakingToken: vaultToken,
                    sharedPerToken1: rewardInfos[_token].sharedPerTokensByPool[
                        1
                    ],
                    sharedPerToken2: rewardInfos[_token].sharedPerTokensByPool[
                        2
                    ],
                    poolBalance1: poolBalances[1],
                    ratio1: poolInfos[1].ratio,
                    poolBalance2: poolBalances[2],
                    ratio2: poolInfos[2].ratio,
                    totalUserFToken: totalUserFToken
                })
            );
        return
            TokenVaultStakingLogic.estimateWithdrawAmount(
                DataTypes.EstimateWithdrawAmountParams({
                    withdrawAmount: amount,
                    withdrawToken: address(_token),
                    stakingAmount: stakingInfos[sId].amount,
                    stakingToken: address(vaultToken),
                    poolId: stakingInfos[sId].poolId,
                    infoSharedPerToken: stakingInfos[sId].sharedPerTokens[
                        _token
                    ],
                    sharedPerToken1: sharedPerToken1,
                    sharedPerToken2: sharedPerToken2
                })
            );
    }

    function stakingInfoSharedPerToken(uint256 sId, IERC20 _token)
        external
        view
        returns (uint256)
    {
        require(stakingInfos[sId].amount > 0, Errors.VAULT_ZERO_AMOUNT);
        return stakingInfos[sId].sharedPerTokens[_token];
    }

    function stakingInfoSharedPerVaultToken(uint256 sId)
        external
        view
        returns (uint256)
    {
        require(stakingInfos[sId].amount > 0, Errors.VAULT_ZERO_AMOUNT);
        return stakingInfos[sId].sharedPerTokens[IERC20(vaultToken)];
    }

    function rewardInfoTokenBalance(IERC20 _token)
        external
        view
        returns (uint256)
    {
        return rewardInfos[_token].currentBalance;
    }

    function getSharedPerToken(IERC20 _token)
        external
        view
        returns (uint256 sharedPerToken1, uint256 sharedPerToken2)
    {
        return
            TokenVaultStakingLogic.getSharedPerToken(
                DataTypes.GetSharedPerTokenParams({
                    token: _token,
                    currentRewardBalance: rewardInfos[_token].currentBalance,
                    stakingToken: vaultToken,
                    sharedPerToken1: rewardInfos[_token].sharedPerTokensByPool[
                        1
                    ],
                    sharedPerToken2: rewardInfos[_token].sharedPerTokensByPool[
                        2
                    ],
                    poolBalance1: poolBalances[1],
                    ratio1: poolInfos[1].ratio,
                    poolBalance2: poolBalances[2],
                    ratio2: poolInfos[2].ratio,
                    totalUserFToken: totalUserFToken
                })
            );
    }

    /** ve token is untransferable */

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        revert("not allow");
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        revert("not allow");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        revert("not allow");
    }

    /**
     * convert fToken to veToken
     */
    function convertFTokenToVeToken(uint256 amount) external {
        require(!ITreasury(IVault(vaultToken).treasury()).isEnded(), "ended");
        require(amount > 0, "zero amount");
        //
        changingBalance = amount;
        //
        //transfer vaultToken from msg.sender to this contracgtg
        IVault(vaultToken).permitTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        //transfer veToken to msg.sender
        _transfer(address(this), msg.sender, amount);
        //
        uint256 userBalance = userFTokens[msg.sender];
        userBalance = userBalance + amount;
        userFTokens[msg.sender] = userBalance;

        totalUserFToken = totalUserFToken + amount;
        //
        changingBalance = 0;
        //
        _mintBnft(msg.sender);
        //
        emit ConvertVeToken(msg.sender, amount);
    }

    /**
     * redeem veToken to fToken
     */
    function redeemFToken(uint256 amount) external {
        require(amount > 0, "zero amount");
        //
        changingBalance = amount;
        //
        uint256 userBalance = userFTokens[msg.sender];
        require(userBalance >= amount, "invalid amount balance");
        //transfer vaultToken to msg.sender
        TransferHelper.safeTransfer(IERC20(vaultToken), msg.sender, amount);
        //transfer ve-token from msg.sender to this contract
        _transfer(msg.sender, address(this), amount);
        //update balance
        userBalance = userBalance - amount;
        userFTokens[msg.sender] = userBalance;

        totalUserFToken = totalUserFToken - amount;
        //
        changingBalance = 0;
        //
        _burnBnft(msg.sender);
        //
        emit RedeemVeToken(msg.sender, amount);
    }

    // for BNFT

    function _getVault() internal view returns (IVault) {
        return IVault(vaultToken);
    }

    function _getBnft() internal view returns (IBnft) {
        return IBnft(_getVault().bnft());
    }

    function _mintBnft(address user) internal returns (uint256) {
        return _getBnft().mintToUser(user);
    }

    function _burnBnft(address user) internal returns (uint256) {
        if (balanceOf(user) == 0) {
            return _getBnft().burnFromUser(user);
        }
        return 0;
    }

    //FOR PROPOSAL
    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        return ERC20VotesUpgradeable._mint(account, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        virtual
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        return ERC20VotesUpgradeable._burn(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        return ERC20VotesUpgradeable._afterTokenTransfer(from, to, amount);
    }
    //
}
