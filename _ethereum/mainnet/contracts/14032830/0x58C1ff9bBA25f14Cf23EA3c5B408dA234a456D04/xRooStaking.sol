pragma solidity ^0.8.7;
import "./INFTXVault.sol";
import "./INFTXLPStaking.sol";
import "./IUniswapV2Router01.sol";
import "./IVaultTokenUpgradeable.sol";
import "./IRewardDistributionToken.sol";
import "./INFTXStakingZap.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./PRBMathUD60x18.sol";

// SPDX-License-Identifier: MIT

contract xRooStaking is Ownable {
    using PRBMathUD60x18 for uint256;
    event Staked(
        address indexed _user,
        uint256 _stake,
        uint256 _liquidity,
        uint256 _weth
    );
    event Unstaked(address indexed _user, uint256 _stake, uint256 _liquidity);

    // --------- NFTX CONTRACTS/VARIABLES -------------
    INFTXVault public NFTXVault;
    INFTXLPStaking public NFTXLPStaking;
    IRewardDistributionToken public NFTXRewardDistributionToken;
    uint256 constant base = 10**18; // 18 decimal places
    uint256 NFTXRewardPerLiquidity;

    IWETH public WETH;

    // --------- SUSHI CONTRACTS ------------
    IUniswapV2Router01 public sushiRouter;
    IERC20 public SLPToken;

    // --------- INTERNAL CONTRACTS/VARIABLES ---------
    IERC20 public RTRewardToken;
    IERC721 public RTStakedToken;

    uint256 public rewardPeriod;
    uint256 public periodicReward;
    uint256 public lockTime;

    // at the start, RT rewards will not be withdrawable
    bool public lockRTRewards = true;

    // --------- STRUCTS --------------------
    struct UserData {
        uint256 stake;
        uint256 liquidity;
        uint256 lastTimestamp;
        int256 RTRewardModifier;
        int256 NFTXRewardModifier;
        uint256 NFTXRewardWithdrawn;
    }

    struct Dividend {
        uint256 RTRewardToken;
        uint256 NFTXRewardToken;
    }

    // --------- CONTRACT DATA --------------
    mapping(address => UserData) public users;

    // ---------- EXTERNAL CONTRACT METHODS ----------
    constructor(
        address _NFTXVault,
        address _NFTXLPStaking,
        address _NFTXRewardDistributionToken,
        address _sushiRouter,
        address _SLPToken,
        address _RTRewardToken,
        address _RTStakedToken,
        uint256 _rewardPeriod,
        uint256 _periodicReward,
        uint256 _lockTime
    ) {
        RTRewardToken = IERC20(_RTRewardToken);
        RTStakedToken = IERC721(_RTStakedToken);
        rewardPeriod = _rewardPeriod;
        periodicReward = _periodicReward;
        lockTime = _lockTime;

        updateExternalReferences(
            _NFTXVault,
            _NFTXLPStaking,
            _NFTXRewardDistributionToken,
            _sushiRouter,
            _SLPToken
        );
    }

    /**
     * Updates all external references (NFTX/Sushiswap/WETH).
     * @dev only for the contract owner to use, particularly in the case of near-FUBAR.
     * @param _NFTXVault the vault token address
     * @param _NFTXLPStaking the NFTXLPStaking contract address
     * @param _NFTXRewardDistributionToken the NFTX Reward distribution token
     * @param _sushiRouter the address of the Sushiswap router
     * @param _SLPToken the address of the liquidity pool WETH/vault token
     */
    function updateExternalReferences(
        address _NFTXVault,
        address _NFTXLPStaking,
        address _NFTXRewardDistributionToken,
        address _sushiRouter,
        address _SLPToken
    ) public onlyOwner {
        // ASSIGNMENTS
        NFTXVault = INFTXVault(_NFTXVault);
        NFTXLPStaking = INFTXLPStaking(_NFTXLPStaking);
        NFTXRewardDistributionToken = IRewardDistributionToken(
            _NFTXRewardDistributionToken
        );
        WETH = IWETH(IUniswapV2Router01(_sushiRouter).WETH());
        sushiRouter = IUniswapV2Router01(_sushiRouter);
        SLPToken = IERC20(_SLPToken);

        // APPROVALS
        IERC20Upgradeable(address(WETH)).approve(
            _sushiRouter,
            type(uint256).max
        );
        SLPToken.approve(_sushiRouter, type(uint256).max);
        NFTXRewardDistributionToken.approve(
            address(NFTXLPStaking),
            type(uint256).max
        );
        NFTXVault.approve(address(sushiRouter), type(uint256).max);
        SLPToken.approve(address(NFTXLPStaking), type(uint256).max);
    }

    /**
     * Updates the address for the reward token.
     * @param _token the token in which rewards will be disbursed.
     */
    function setRTRewardToken(address _token) external onlyOwner {
        RTRewardToken = IERC20(_token);
    }

    /**
     * Locks/unlocks RT reward withdraw
     * @param _locked the value of the lock (boolean)
     */
    function setLock(bool _locked) external onlyOwner {
        lockRTRewards = _locked;
    }

    /**
     * Sets the lock time where assets cannot be removed after staking.
     * @param _lockTime the amount of seconds the lock lasts after staking
     */
    function setLockTime(uint256 _lockTime) external onlyOwner {
        require(_lockTime > 0);
        lockTime = _lockTime;
    }

    /**
     * Adds liquidity to the pool using the stakable ERC721 token
     * and WETH.
     * @param _minWethIn the min amount of WETH that will get sent to the LP
     * @param _wethIn the amount of WETH that has been provided by the call
     * @param _ids the ids of the tokens to stake
     */
    function addLiquidityERC721(
        uint256 _minWethIn,
        uint256 _wethIn,
        uint256[] calldata _ids
    ) external {
        uint256 initialWETH = IERC20Upgradeable(address(WETH)).balanceOf(
            address(this)
        );

        IERC20Upgradeable(address(WETH)).transferFrom(
            msg.sender,
            address(this),
            _wethIn
        );
        _addLiquidityERC721(msg.sender, _minWethIn, _wethIn, _ids);

        uint256 WETHRefund = IERC20Upgradeable(address(WETH)).balanceOf(
            address(this)
        ) - initialWETH;

        if (WETHRefund < _wethIn && WETHRefund > 0)
            WETH.transfer(msg.sender, WETHRefund);
    }

    /**
     * Adds liquidity to the pool using the stakable ERC721 token
     * and ETH.
     * @param _minWethIn the min amount of WETH that will get sent to the LP
     * @param _ids the ids of the tokens to stake
     * @dev the value passed in is converted to WETH and sent to the LP.
     */
    function addLiquidityERC721ETH(uint256 _minWethIn, uint256[] calldata _ids)
        external
        payable
    {
        uint256 initialWETH = IERC20Upgradeable(address(WETH)).balanceOf(
            address(this)
        );

        WETH.deposit{value: msg.value}();

        _addLiquidityERC721(msg.sender, _minWethIn, msg.value, _ids);

        uint256 wethRefund = IERC20Upgradeable(address(WETH)).balanceOf(
            address(this)
        ) - initialWETH;

        // Return extras.
        if (wethRefund < msg.value && wethRefund > 0) {
            WETH.withdraw(wethRefund);
            (bool success, ) = payable(msg.sender).call{value: wethRefund}("");
            require(success, "Refund failed");
        }
    }

    /**
     * Adds liquidity to the pool using the stakable ERC20 token
     * and WETH.
     * @param _minWethIn the min amount of WETH that will get sent to the LP
     * @param _wethIn the amount of WETH that has been provided by the call
     * @param _amount the amount of the ERC20 token to stake
     */
    function addLiquidityERC20(
        uint256 _minWethIn,
        uint256 _wethIn,
        uint256 _amount
    ) external {
        IERC20Upgradeable(address(WETH)).transferFrom(
            msg.sender,
            address(this),
            _wethIn
        );

        (, uint256 amountWETH, ) = _addLiquidityERC20(
            msg.sender,
            _minWethIn,
            _wethIn,
            _amount
        );

        // refund unused WETH
        if (amountWETH < _wethIn && _wethIn - amountWETH > 0) {
            WETH.transfer(msg.sender, _wethIn - amountWETH);
        }
    }

    /**
     * Adds liquidity to the pool using the stakable ERC20 token
     * and ETH.
     * @param _minWethIn the min amount of WETH that will get sent to the LP
     * @param _amount the amount of the ERC20 token to stake
     * @dev the value passed in is converted to WETH and sent to the LP.
     */
    function addLiquidityERC20ETH(uint256 _minWethIn, uint256 _amount)
        external
        payable
    {
        WETH.deposit{value: msg.value}();

        (, uint256 amountWETH, ) = _addLiquidityERC20(
            msg.sender,
            _minWethIn,
            msg.value,
            _amount
        );

        // refund unused ETH
        if (amountWETH < msg.value && msg.value - amountWETH > 0) {
            WETH.withdraw(msg.value - amountWETH);
            (bool sent, ) = payable(msg.sender).call{
                value: msg.value - amountWETH
            }("");
            require(sent, "refund failed");
        }
    }

    /**
     * Removes all liquidity from the LP and claims rewards.
     * @param _amountTokenMin the min amount of the ERC20 staking token to get back
     * @param _amountWETHMin the min amount of WETH to get back
     *
     * NOTE you cannot withdraw until the timelock has expired.
     */
    function removeLiquidity(uint256 _amountTokenMin, uint256 _amountWETHMin)
        external
    {
        require(
            users[msg.sender].lastTimestamp + lockTime < block.timestamp,
            "Locked"
        );
        _removeLiquidity(msg.sender, _amountTokenMin, _amountWETHMin);
    }

    /**
     * Claims all of the dividends currently owed to the caller.
     * Will not claim RT rewards if the lock is set.
     */
    function claimRewards() external {
        _claimRewards(msg.sender);
    }

    /**
     * Gets the rewards owed to the user.
     */
    function dividendOf(address _user) external view returns (Dividend memory) {
        return _dividendOf(_user);
    }

    /**
     * An emergency function that will allow users to pull out their liquidity in the NFTX
     * reward distribution token. DOES NOT DISTRIBUTE REWARDS. This is to be used in the
     * case where our connection with NFTX's contracts causes transaction failures.
     *
     * NOTE you cannot withdraw until the timelock has expired.
     */
    function emergencyExit() external {
        require(
            users[msg.sender].lastTimestamp + lockTime < block.timestamp,
            "Locked"
        );
        _emergencyExit(msg.sender);
    }

    /**
     * Shows the time until the user's funds are unlocked (unix seconds).
     * @param _user the user whose lock time we are checking
     */
    function lockedUntil(address _user) external view returns (uint256) {
        require(users[_user].lastTimestamp != 0, "N/A");
        return users[_user].lastTimestamp + lockTime;
    }

    // ---------- INTERNAL CONTRACT METHODS ----------
    function _totalLiquidityStaked() internal view returns (uint256) {
        return NFTXRewardDistributionToken.balanceOf(address(this));
    }

    /**
     * An emergency escape in the unlikely case of a contract error
     * causing unstaking methods to fail.
     */
    function _emergencyExit(address _user) internal {
        uint256 liquidity = users[_user].liquidity;
        delete users[_user];

        NFTXRewardDistributionToken.transfer(_user, liquidity);
    }

    function _claimContractNFTXRewards() internal {
        uint256 currentRewards = NFTXVault.balanceOf(address(this));
        uint256 dividend = NFTXRewardDistributionToken.dividendOf(
            address(this)
        );
        if (dividend == 0) return;

        NFTXLPStaking.claimRewards(NFTXVault.vaultId());
        require(
            NFTXVault.balanceOf(address(this)) == currentRewards + dividend,
            "Unexpected balance"
        );

        NFTXRewardPerLiquidity += dividend.div(_totalLiquidityStaked());
    }

    function _addLiquidityERC721(
        address _user,
        uint256 _minWethIn,
        uint256 _wethIn,
        uint256[] calldata _ids
    )
        internal
        returns (
            uint256 amountToken,
            uint256 amountWETH,
            uint256 liquidity
        )
    {
        _claimContractNFTXRewards();
        uint256 initialRewardToken = NFTXVault.balanceOf(address(this));

        for (uint256 i = 0; i < _ids.length; i++) {
            RTStakedToken.transferFrom(_user, address(this), _ids[i]);
        }
        RTStakedToken.setApprovalForAll(address(NFTXVault), true);
        NFTXVault.mint(_ids, new uint256[](0));

        uint256 newTokens = NFTXVault.balanceOf(address(this)) -
            initialRewardToken;

        return _stakeAndUpdate(_user, _minWethIn, _wethIn, newTokens);
    }

    /**
     * Adds liquidity in ERC20 (the vault token)
     */
    function _addLiquidityERC20(
        address _user,
        uint256 _minWethIn,
        uint256 _wethIn,
        uint256 _amount
    )
        internal
        returns (
            uint256 amountToken,
            uint256 amountWETH,
            uint256 liquidity
        )
    {
        _claimContractNFTXRewards();

        NFTXVault.transferFrom(_user, address(this), _amount);
        return _stakeAndUpdate(_user, _minWethIn, _wethIn, _amount);
    }

    /**
     * Stakes on the SLP and then on NFTx's platform
     * @dev All vault token and WETH should be owned by the
     * contract before calling.
     */
    function _stakeAndUpdate(
        address _user,
        uint256 _minWethIn,
        uint256 _wethIn,
        uint256 _amount // amount of ERC20 vault token
    )
        internal
        returns (
            uint256 amountToken,
            uint256 amountWETH,
            uint256 liquidity
        )
    {
        // stake on SUSHI
        (
            amountToken,
            amountWETH, // amt used
            liquidity
        ) = sushiRouter.addLiquidity(
            address(NFTXVault),
            address(WETH),
            _amount,
            _wethIn,
            _amount,
            _minWethIn,
            address(this),
            block.timestamp
        );

        NFTXLPStaking.deposit(NFTXVault.vaultId(), liquidity); // DEPOSIT IN NFTX

        UserData memory userData = users[_user];

        uint256 NFTXRewardModifier = liquidity.mul(NFTXRewardPerLiquidity);
        uint256 currentNumPeriods = userData.lastTimestamp == 0
            ? 0
            : (block.timestamp - userData.lastTimestamp) / rewardPeriod;

        userData.liquidity += liquidity;
        userData.RTRewardModifier += int256(
            currentNumPeriods * periodicReward.mul(userData.stake)
        );
        userData.lastTimestamp = block.timestamp;
        userData.stake += _amount;
        userData.NFTXRewardModifier -= int256(NFTXRewardModifier);

        users[_user] = userData;

        // return unstaked vault token
        if (amountToken < _amount) {
            NFTXVault.transfer(_user, _amount - amountToken);
        }

        emit Staked(_user, _amount, liquidity, amountWETH);
    }

    function _dividendOf(address _user)
        internal
        view
        returns (Dividend memory)
    {
        uint256 updatedNFTXRewardPerLiquidity = NFTXRewardPerLiquidity +
            NFTXRewardDistributionToken.dividendOf(address(this)).div(
                _totalLiquidityStaked()
            );

        int256 nftxReward = int256(
            (users[_user].liquidity.mul(updatedNFTXRewardPerLiquidity))
        ) +
            users[_user].NFTXRewardModifier -
            int256(users[_user].NFTXRewardWithdrawn);

        uint256 numPeriods = users[_user].lastTimestamp == 0
            ? 0
            : (block.timestamp - users[_user].lastTimestamp) / rewardPeriod;

        int256 rtReward = int256(
            numPeriods * periodicReward.mul(users[_user].stake)
        ) + users[_user].RTRewardModifier;

        require(nftxReward >= 0 && rtReward >= 0, "Negative Reward");

        Dividend memory dividend;
        dividend.NFTXRewardToken = uint256(nftxReward);
        dividend.RTRewardToken = uint256(rtReward);

        return dividend;
    }

    function _claimRewards(address _user) internal {
        _claimContractNFTXRewards();

        Dividend memory rewards = _dividendOf(_user);
        if (rewards.NFTXRewardToken > 0) {
            users[_user].NFTXRewardWithdrawn += rewards.NFTXRewardToken;
            NFTXVault.transfer(_user, rewards.NFTXRewardToken);
        }
        if (rewards.RTRewardToken > 0 && !lockRTRewards) {
            users[_user].RTRewardModifier -= int256(rewards.RTRewardToken);
            RTRewardToken.transfer(_user, rewards.RTRewardToken);
        }
    }

    function _removeLiquidity(
        address _user,
        uint256 _amountTokenMin,
        uint256 _amountWETHMin
    ) internal {
        uint256 amount = users[_user].liquidity;
        uint256 stake = users[_user].stake;
        _claimRewards(_user);
        delete users[_user];

        // remove from NFTXLPStaking
        NFTXLPStaking.withdraw(NFTXVault.vaultId(), amount); // gives us <amount> SLP
        sushiRouter.removeLiquidity(
            address(NFTXVault),
            address(WETH),
            amount,
            _amountTokenMin,
            _amountWETHMin,
            _user, // send to user
            block.timestamp
        ); // return to user

        emit Unstaked(_user, stake, amount);
    }

    receive() external payable {
        // DO NOTHING
    }
}
