// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721Receiver.sol";
import "./Math.sol";
import "./ICollectionswap.sol";
import "./ILSSVMPair.sol";

contract RewardPoolETH is IERC721Receiver, Initializable {
    using SafeERC20 for IERC20;

    struct LPTokenInfo {
        uint256 amount0;
        uint256 amount1;
        uint256 amount;
        address owner;
    }

    /// @dev The number of NFTs in the pool
    uint128 private reserve0; // uses single storage slot, accessible via getReserves
    /// @dev The amount of ETH in the pool
    uint128 private reserve1; // uses single storage slot, accessible via getReserves

    address protocolOwner;
    address deployer;
    ICollectionswap public lpToken;
    IERC721 nft;
    address bondingCurve;
    uint128 delta;
    uint96 fee;

    uint256 public constant MAX_REWARD_TOKENS = 5;
    uint256 public LOCK_TIME = 30 days;

    /// @dev The total number of tokens minted
    uint256 private _totalSupply;
    mapping(address => uint256) internal _balances;
    /// @dev maps from tokenId to pool LPToken information
    mapping(uint256 => LPTokenInfo) public lpTokenInfo;

    IERC20[] public rewardTokens;
    mapping(IERC20 => bool) public rewardTokenValid;

    uint256 public periodFinish;
    uint256 public rewardSweepTime;
    /// @dev maps from ERC20 token to the reward amount / duration of period
    mapping(IERC20 => uint256) public rewardRates;
    uint256 public lastUpdateTime;
    /**
     * @dev maps from ERC20 token to the reward amount accumulated per unit of
     * reward token
     */ 
    mapping(IERC20 => uint256) public rewardPerTokenStored;
    mapping(IERC20 => mapping(address => uint256))
        public userRewardPerTokenPaid;
    mapping(IERC20 => mapping(address => uint256)) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 tokenId, uint256 amount);
    event Withdrawn(address indexed user, uint256 tokenId, uint256 amount);
    event RewardPaid(
        IERC20 indexed rewardToken,
        address indexed user,
        uint256 reward
    );
    event RewardSwept();
    event RewardPoolRecharged(
        IERC20[] rewardTokens,
        uint256[] rewards,
        uint256 startTime,
        uint256 endTime
    );

    modifier updateReward(address account) {
        // skip update after rewards program starts
        // cannot include equality because
        // multiple accounts can perform actions in the same block
        // and we have to update account's rewards and userRewardPerTokenPaid values
        if (block.timestamp < lastUpdateTime) {
            _;
            return;
        }

        uint256 rewardTokensLength = rewardTokens.length;
        // lastUpdateTime is set to startTime in constructor
        if (block.timestamp > lastUpdateTime) {
            for (uint256 i; i < rewardTokensLength; ) {
                IERC20 rewardToken = rewardTokens[i];
                rewardPerTokenStored[rewardToken] = rewardPerToken(rewardToken);
                unchecked {
                    ++i;
                }
            }
            lastUpdateTime = lastTimeRewardApplicable();
        }
        if (account != address(0)) {
            for (uint256 i; i < rewardTokensLength; ) {
                IERC20 rewardToken = rewardTokens[i];
                rewards[rewardToken][account] = earned(account, rewardToken);
                userRewardPerTokenPaid[rewardToken][
                    account
                ] = rewardPerTokenStored[rewardToken];
                unchecked {
                    ++i;
                }
            }
        }
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _protocolOwner,
        address _deployer,
        ICollectionswap _lpToken,
        IERC721 _nft,
        address _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        IERC20[] calldata _rewardTokens,
        uint256[] calldata _rewardRates,
        uint256 _startTime,
        uint256 _periodFinish
    ) public initializer {
        protocolOwner = _protocolOwner;
        require(_nft.supportsInterface(0x80ac58cd), "NFT not ERC721"); // check if it supports ERC721
        deployer = _deployer;
        lpToken = _lpToken;
        nft = _nft;
        bondingCurve = _bondingCurve;
        delta = _delta;
        fee = _fee;
        rewardTokens = _rewardTokens;
        unchecked {
            for (uint256 i; i < rewardTokens.length; ++i) {
                require(
                    !rewardTokenValid[_rewardTokens[i]],
                    "Repeated token"
                );
                rewardRates[_rewardTokens[i]] = _rewardRates[i];
                rewardTokenValid[_rewardTokens[i]] = true;
            }
        }
        lastUpdateTime = _startTime == 0 ? block.timestamp : _startTime;
        periodFinish = _periodFinish;
        rewardSweepTime = _periodFinish + LOCK_TIME;
    }

    /**
     * @notice Add ERC20 tokens to the pool and set the `newPeriodFinish` value of
     * the pool
     * 
     * @dev new reward tokens are to be appended to inputRewardTokens
     * 
     * @param inputRewardTokens An array of ERC20 tokens to recharge the pool with
     * @param inputRewardAmounts An array of the amounts of each ERC20 token to 
     * recharge the pool with
     * @param _newPeriodFinish The value to update this pool's `periodFinish` variable to
     */
    function rechargeRewardPool(
        IERC20[] calldata inputRewardTokens,
        uint256[] calldata inputRewardAmounts,
        uint256 _newPeriodFinish
    ) public virtual updateReward(address(0)) {
        require(
            msg.sender == deployer || msg.sender == protocolOwner,
            "Not authorized"
        );
        require(_newPeriodFinish > block.timestamp, "Invalid period finish");
        require(
            block.timestamp > periodFinish,
            "Ongoing rewards"
        );
        uint256 oldRewardTokensLength = rewardTokens.length;
        uint256 newRewardTokensLength = inputRewardTokens.length;
        require(oldRewardTokensLength <= newRewardTokensLength, "Bad token config");
        require(newRewardTokensLength <= MAX_REWARD_TOKENS, "Exceed max tokens");
        require(
            newRewardTokensLength == inputRewardAmounts.length,
            "Inconsistent length"
        );

        // Mark each ERC20 in the input as used by this pool, and ensure no
        // duplicates within the input
        uint256 newReward;
        for (uint256 i; i < newRewardTokensLength; ) {
            IERC20 inputRewardToken = inputRewardTokens[i];
            // ensure same ordering for existing tokens
            if (i < oldRewardTokensLength) {
                require(inputRewardToken == rewardTokens[i], "Reward token mismatch");
            } else {
                // adding new token
                require(
                    !rewardTokenValid[inputRewardToken],
                    "Repeated token"
                );
                rewardTokenValid[inputRewardToken] = true;
            }

            // note that reward amounts can be zero
            newReward = inputRewardAmounts[i];
            // pull tokens
            if (newReward > 0) {
                inputRewardToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    newReward
                );

                // newReward = new reward rate
                newReward /= (_newPeriodFinish - block.timestamp);
                require(newReward != 0, "0 reward rate");
            }
            rewardRates[inputRewardToken] = newReward;

            unchecked {
                ++i;
            }
        }

        rewardTokens = inputRewardTokens;
        lastUpdateTime = block.timestamp;
        periodFinish = _newPeriodFinish;
        rewardSweepTime = _newPeriodFinish + LOCK_TIME;

        emit RewardPoolRecharged(
            inputRewardTokens,
            inputRewardAmounts,
            block.timestamp,
            _newPeriodFinish
        );
    }

    /**
     * @notice Sends all ERC20 token balances of this pool to the deployer.
     */
    function sweepRewards() external {
        require(msg.sender == deployer, "Not authorized");
        require(block.timestamp >= rewardSweepTime, "Too early");
        emit RewardSwept();
        uint256 rewardTokensLength = rewardTokens.length;
        unchecked {
            for (uint256 i; i < rewardTokensLength; ++i) {
                IERC20 rewardToken = rewardTokens[i];
                rewardToken.safeTransfer(
                    msg.sender,
                    rewardToken.balanceOf(address(this))
                );
            }
        }
    }

    function atomicPoolAndVault(
        IERC721 _nft,
        ICurve _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) public payable returns (uint256 currTokenId) {
        ICollectionswap _lpToken = lpToken;
        (,currTokenId) = _lpToken.createDirectPairETH{value:msg.value}(msg.sender, _nft,_bondingCurve, _delta, _fee, _spotPrice, _initialNFTIDs);
        stake(currTokenId);
    }

    function atomicExitAndUnpool(
        uint256 _tokenId
    ) external {
        exit(_tokenId);
        ICollectionswap _lpToken = lpToken;
        _lpToken.useLPTokenToDestroyDirectPairETH(msg.sender, _tokenId);
    }


    /**
     * @notice Add the balances of an LP token to the reward pool and mint 
     * reward tokens
     * @param tokenId The tokenId of the LP token to be added to this reward 
     * pool
     * @return amount The number of tokens minted
     */
    function mint(uint256 tokenId) private returns (uint256 amount) {
        ICollectionswap _lpToken = lpToken;
        require(_lpToken.ownerOf(tokenId) == msg.sender, "Not owner");

        IERC721 _nft = nft;
        require(
            _lpToken.validatePoolParamsLte(
                tokenId,
                address(_nft),
                bondingCurve,
                fee,
                delta
            ),
            "Wrong pool"
        );

        ILSSVMPair _pair = ILSSVMPair(_lpToken.viewPoolParams(tokenId).poolAddress);

        // Calculate the number of tokens to mint. Equal to 
        // sqrt(NFT balance * ETH balance) if there's enough ETH for the pool to
        // buy at least 1 NFT. Else 0.
        (uint128 _reserve0, uint128 _reserve1) = getReserves(); // gas savings
        uint256 amount0 = _nft.balanceOf(address(_pair));
        uint256 amount1 = address(_pair).balance;

        ( , , ,uint256 bidPrice, ) = _pair.getSellNFTQuote(1);
        if (amount1 >= bidPrice) {
            amount = Math.sqrt(amount0 * amount1);
        }

        uint256 balance0 = _reserve0 + amount0;
        uint256 balance1 = _reserve1 + amount1;
        require(
            balance0 <= type(uint128).max && balance1 <= type(uint128).max,
            "Balance overflow"
        );

        reserve0 = uint128(balance0);
        reserve1 = uint128(balance1);
        lpTokenInfo[tokenId] = LPTokenInfo({
            amount0: amount0,
            amount1: amount1,
            amount: amount,
            owner: msg.sender
        });
    }

    /**
     * @notice Remove the balances of an LP token from the reward pool and burn 
     * reward tokens
     * @param tokenId The tokenId of the LP token to be added to this reward 
     * pool
     * @return amount The number of lp tokens burned
     */
    function burn(uint256 tokenId) internal virtual returns (uint256 amount) {
        LPTokenInfo memory lpTokenIdInfo = lpTokenInfo[tokenId];
        require(lpTokenIdInfo.owner == msg.sender, "Not owner");
        amount = lpTokenIdInfo.amount;

        (uint128 _reserve0, uint128 _reserve1) = getReserves(); // gas savings

        uint256 balance0 = _reserve0 - lpTokenIdInfo.amount0;
        uint256 balance1 = _reserve1 - lpTokenIdInfo.amount1;

        reserve0 = uint128(balance0);
        reserve1 = uint128(balance1);

        delete lpTokenInfo[tokenId];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @return The end of the period, or now if earlier
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @notice Calculate the amount of `_rewardToken` rewards accrued per reward
     * token.
     * @param _rewardToken The ERC20 token to be rewarded
     * @return The amount of `_rewardToken` awardable per reward token
     * 
     */
    function rewardPerToken(IERC20 _rewardToken) public view returns (uint256) {
        uint256 lastRewardTime = lastTimeRewardApplicable();
        // latter condition required because calculations will revert when called externally
        // even though internally this function will only be called if lastRewardTime > lastUpdateTime
        if (totalSupply() == 0 || lastRewardTime <= lastUpdateTime) {
            return rewardPerTokenStored[_rewardToken];
        }
        return
            rewardPerTokenStored[_rewardToken] +
            (((lastRewardTime - lastUpdateTime) *
                rewardRates[_rewardToken] *
                1e18) / totalSupply());
    }

    /**
     * @notice Calculate the amount of `_rewardToken` earned by `account`
     * @dev 
     * 
     * @param account The account to calculate earnings for
     * @param _rewardToken The ERC20 token to calculate earnings of
     * @return The amount of ERC20 token earned
     */
    function earned(address account, IERC20 _rewardToken) public view virtual returns (uint256) {
        return balanceOf(account)
                * (rewardPerToken(_rewardToken) - userRewardPerTokenPaid[_rewardToken][account])
                / (1e18)
                + rewards[_rewardToken][account];
    }

    /**
     * @notice Stake an LP token into the reward pool
     * @param tokenId The tokenId of the LP token to stake
     * @return amount The amount of reward token minted as a result
     */
    function stake(uint256 tokenId) public virtual updateReward(msg.sender) returns (uint256 amount) {
        require(tx.origin == msg.sender, "Caller must be EOA");
        amount = mint(tokenId);
        require(amount > 0, "Cannot stake one-sided LPs");

        _totalSupply += amount;
        _balances[msg.sender] += amount;
        lpToken.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Staked(msg.sender, tokenId, amount);
    }

    function withdraw(uint256 tokenId) public updateReward(msg.sender) {
        // amount will never be 0 because it is checked in stake()
        uint256 amount = burn(tokenId);
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        lpToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Withdrawn(msg.sender, tokenId, amount);
    }

    function exit(uint256 tokenId) public {
        withdraw(tokenId);
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < rewardTokensLength; ) {
            IERC20 rewardToken = rewardTokens[i];
            uint256 reward = earned(msg.sender, rewardToken);
            if (reward > 0) {
                rewards[rewardToken][msg.sender] = 0;
                emit RewardPaid(rewardToken, msg.sender, reward);
                rewardToken.safeTransfer(msg.sender, reward);
            }
            unchecked {
                ++i;
            }
        }
    }

    function getReserves()
        public
        view
        returns (uint128 _reserve0, uint128 _reserve1)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
}
