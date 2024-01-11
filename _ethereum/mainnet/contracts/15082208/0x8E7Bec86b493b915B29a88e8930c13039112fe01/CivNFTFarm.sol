// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./ERC1155Holder.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ICivRT.sol";

/// @title  Civ NFT Farm
/// @author Lorenz-Ren

/// @notice This contract creates a simple yield farming dApp that rewards users for
///         locking up their NFTs with 0NE reward token
/// @dev  The calculateYieldTotal function
///      takes care of current yield calculations for frontend data.
///      At any time user can withdraw yield rewards. We can modify this and execute this during withdraw of LPTokens
///      Ownership of the reward NFT Token contract should be transferred to the xCIVNFTFarm contract after deployment

contract CivNFTFarm is Ownable, ERC1155Holder, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // At any point in time, the amount of 0NE Tokens
        // entitled to a user but pending to be distributed is:
        //
        //   pending reward = (user.amount  * accTokenPerShare) - user.rewardDebt              <<<< Wallet Earn (WE)
        //
        // Whenever an user deposits or withdraws LP tokens to the pool, here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC1155 parentNFT; // Address of NFT contract.
        uint256 allocPoint; // TP logic>>>> How many allocation points assigned to this pool. reward tokens (0NE) to distribute per block.
        uint256 lastRewardBlock; // Last block number that xTokens distribution occurs.
        uint256 accTokensPerShare; // Accumulated xTokens per share, times 1e18. See below.
        uint256 tokenid; // NFT token id
        ICivRT representToken;
    }

    // Represent Token
    ICivRT public representToken;
    // The reward NFT
    IERC20 public rewardToken;
    // 0NE tokens rewards per block. FR logic, Farming Rate logic
    uint256 public tokensPerBlock;
    // Bonus multiplier for early farm makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // pools structure with Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes NFTs tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.   TP logic, TPpool 1 + TPpool 2 + ... + TPpool z = Total TPS
    uint256 public totalAllocPoint = 104;
    // The block number when farm starts.
    uint256 public startBlock;

    uint256 public immutable MAX_UINT = 2**256-1;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event YieldWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AddPool(
        uint256 indexed pid,
        uint256 indexed allocPoint,
        IERC1155 parentNFT,
        uint256 tokenId,
        IERC20 representToken
    );
    event SetPool(
        uint256 indexed pid,
        uint256 indexed prevAllocPoint,
        uint256 indexed newAllocPoint
    );
    event SetTotalAllocPoint(
        uint256 indexed prevTotalAllocPoint,
        uint256 indexed newTotalAllocPoint
    );
    event SetTokensPerBlock(
        uint256 indexed prevTokensPerBlock,
        uint256 indexed newTokensPerBlock
    );

    constructor(
        IERC1155 _parentnft,
        IERC20 _stone,
        ICivRT _xNFT
    ) public {
        representToken = _xNFT;
        rewardToken = _stone;
        tokensPerBlock = 1000000; //1M initial setup     Farming Rate FR
        //  startBlock = _startBlock;

        // staking pool
        poolInfo.push(
            PoolInfo({
                parentNFT: _parentnft,
                allocPoint: 5, //pool TP example pool id=0, stake elite emerald 2000 --> reward STN. TP = 5 / 104, FR = 1/block
                lastRewardBlock: startBlock,
                accTokensPerShare: 0,
                tokenid: 11155307892213316102126205517473478203086619238533575936401408031787321393652, //change tokenid
                representToken: _xNFT
            })
        );

        totalAllocPoint = 104; //our total TP considering requirements
        startBlock = block.number; //Farm starts when this Contract is deployed
        emit AddPool(poolInfo.length - 1, 5, _parentnft, 0, _xNFT);
    }

    //update bonus multiplier for early farmers. Can only be called by the owner.
    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    //update Farming Rate, reward tokensdistributed per block. Can only be called by the owner.
    function updateRate(uint256 rateNumber) public onlyOwner {
         emit SetTokensPerBlock(tokensPerBlock, rateNumber);
        tokensPerBlock = rateNumber;
    }

    //number of pools.
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(
        uint256 _allocPoint,
        IERC1155 _parentNFT,
        uint256 _tokenid,
        ICivRT _representToken
    ) public onlyOwner {
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;

        //adding a new LP
        poolInfo.push(
            PoolInfo({
                parentNFT: _parentNFT, //LP NFT Token
                allocPoint: _allocPoint, //TP of the new pool
                lastRewardBlock: lastRewardBlock,
                accTokensPerShare: 0, //init = always 0
                tokenid: _tokenid,
                representToken: _representToken
            })
        );
        emit AddPool(
            poolInfo.length - 1,
            _allocPoint,
            _parentNFT,
            _tokenid,
            _representToken
        );
    }

    // Update the given pool's reward token allocation point. Can only be called by the owner.
    function setPool(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        require(poolInfo.length > _pid, "Pool does not exist");
        emit SetPool(_pid, poolInfo[_pid].allocPoint, _allocPoint);

        if (poolInfo[_pid].allocPoint != _allocPoint) {
            updatePool(_pid);
        }
    }

    function setTotalAllocPoint(uint256 _totalAllocPoint) public onlyOwner {
        emit SetTotalAllocPoint(totalAllocPoint, _totalAllocPoint);
        totalAllocPoint = _totalAllocPoint;
    }

    // Returns reward multiplier over the given _from to _to block considering possible MULTIPLIER for EARLY FARMERS/STAKERS
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return (_to - _from) * (BONUS_MULTIPLIER);
    }

    // Returns Lp provided by user on a given pool
    function getUserLP(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_pid][_user];
        return user.amount;
    }

    // View function to see pending Tokens on frontend.
    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 lpSupply = pool.parentNFT.balanceOf(
            address(this),
            pool.tokenid
        );
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 tokensReward = (multiplier *
                (tokensPerBlock) *
                (10**18) *
                (pool.allocPoint)) / (totalAllocPoint);
            accTokensPerShare =
                accTokensPerShare +
                ((tokensReward * (10**18)) / lpSupply);
        }
        uint256 pending = (user.amount * accTokensPerShare) /
            (10**18) -
            (user.rewardDebt);
        return pending;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.parentNFT.balanceOf(
            address(this),
            pool.tokenid
        );
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokensReward = (multiplier *
            (tokensPerBlock) *
            (10**18) *
            (pool.allocPoint)) / (totalAllocPoint);

        pool.accTokensPerShare =
            pool.accTokensPerShare +
            ((tokensReward * (10**18)) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    // Stake NFTs to CIVNFT Farm
    function enterStaking(uint256 _pid, uint256 _amount) public nonReentrant whenNotPaused{
        
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 length = poolLength();
        require(length > _pid, "Can't find pool!");
        require(_amount <= uint256(MAX_UINT), "Wrong amount");

        uint256 actualRepresentToken = _amount * 10**18;

        updatePool(_pid);

        PoolInfo memory pool = poolInfo[_pid];
        
        uint256 pending = ((user.amount * pool.accTokensPerShare) /
            (10**18)) - (user.rewardDebt);
        user.rewardDebt = ((user.amount + _amount) * (pool.accTokensPerShare)) / (10**18);

        if (pending > 0) {
            rewardToken.safeTransfer(msg.sender, pending);
            emit YieldWithdraw(msg.sender, _pid, pending);
        }
        if (_amount > 0) {
            pool.parentNFT.safeTransferFrom(
                msg.sender,
                address(this),
                pool.tokenid,
                _amount,
                "0x00"
            );
            user.amount = user.amount + (_amount);
        }
        

        pool.representToken.mint(msg.sender, actualRepresentToken);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw NFTS tokens from STAKING.
    function leaveStaking(uint256 _pid, uint256 _amount) public nonReentrant whenNotPaused {
        
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(poolLength() > _pid, "Can't find pool");
        require(_amount <= uint256(MAX_UINT), "Wrong amount");
        require(user.amount >= _amount, "amount exceeds user's balance");

        uint256 actualRepresentToken = _amount * 10**18;

        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];

        uint256 pending = (user.amount * pool.accTokensPerShare) /
            (10**18) -
            (user.rewardDebt);
        user.rewardDebt = ((user.amount - _amount) * pool.accTokensPerShare) / (10**18);

        if (pending > 0) {
            rewardToken.safeTransfer(msg.sender, pending);
            emit YieldWithdraw(msg.sender, _pid, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - (_amount);
            pool.parentNFT.safeTransferFrom(
                address(this),
                msg.sender,
                pool.tokenid,
                _amount,
                "0x00"
            );
        }
        
        pool.representToken.burnFrom(
            msg.sender,
            actualRepresentToken
        );
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Transfers accrued 0NE Tokens yield to the user
    /// @dev The if conditional statement checks for a stored xToken balance.

    function withdrawYield(uint256 _pid) public whenNotPaused {
        
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        PoolInfo memory pool = poolInfo[_pid];
        
        uint256 toTransfer = (user.amount * pool.accTokensPerShare) /
            (10**18) -
            (user.rewardDebt);
        user.rewardDebt = (user.amount * pool.accTokensPerShare) / (10**18);

        require(toTransfer > 0, "Nothing to withdraw Sir");

        rewardToken.safeTransfer(msg.sender, toTransfer);

        emit YieldWithdraw(msg.sender, _pid, toTransfer);
    }

    /*
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    */

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public whenNotPaused nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount > 0, "Not enough token in this pool to withdraw");
        uint256 actualRepresentToken = user.amount * 10**18;
    
        pool.representToken.burnFrom(
            msg.sender,
            actualRepresentToken
        );

        pool.parentNFT.safeTransferFrom(
            address(this),
            msg.sender,
            pool.tokenid,
            user.amount,
            "0x00"
        );

        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* Just in case anyone sends tokens by accident to this contract */

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "CivFarm");
    }

    function withdrawETH() external payable onlyOwner {
        safeTransferETH(_msgSender(), address(this).balance);
    }

    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        _tokenContract.safeTransfer(
            _msgSender(),
            _tokenContract.balanceOf(address(this))
        );
    }

    /**
     * @dev allow the contract to receive ETH
     * without payable fallback and receive, it would fail
     */
    fallback() external payable {}

    receive() external payable {}
}