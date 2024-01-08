pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./GrailToken.sol";
import "./AccessControlEnumerable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract MasterChef is AccessControlEnumerable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // The Protocol Token!
    GrailToken public grail;
    // Dev address.
    address public devaddr;
    // grail tokens created per block.
    uint256 public grailPerBlock;
    // Deposit Fee address
    address public feeAddress;
    // Tokens Burned
    uint256 public tokensBurned;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(
        GrailToken _grail,
        address _devaddr,
        address _feeAddress,
        uint256 _grailPerBlock,
        uint256 _startBlock
    ) public {
        grail = _grail;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        grailPerBlock = _grailPerBlock;
        startBlock = _startBlock;

        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has user provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //      pending reward = (user.amount * pool.accgrailPerShare) - user.rewardDebt

        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accgrailPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // Portion of reward allocation to this pool.
        uint256 lastRewardBlock; // Block number when last distribution happened on a pool.
        uint256 accGRAILPerShare; // Accumulated GRAIL's per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when GRAIL mining starts.
    uint256 public startBlock;

    // Calculate how many pools exist.
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(ERC20 => bool) public poolExistence;
    // Prevents creation of a pool with the same token.
    modifier nonDuplicated(ERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Create a new pool. Can only be called by the owner.
    // You define the token address.
    // You set the weightto the pool - allocPoint. It determine how much rewards will go to stakers of this pool relative to other pools.
    // You also define the deposit fee. This fee is moved to fee collecter address.
    function add(
        uint256 _allocPoint,
        ERC20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public nonDuplicated(_lpToken) {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "Must have minter role to mint"
        );
        // The deposit fee has to be below 100%
        require(
            _depositFeeBP <= 10000,
            "add: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }

        // In case Farm already running set the lastRewardBlock to curenct block number.
        // In case farm is launched in the future, set it to the farm startBlock number.
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        // Adjust totalAllocPoint to weight of all pools, accounting for new pool added.
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        // You set the pool as it already exists so you wouln't be able to create the same exact pool twice.
        poolExistence[_lpToken] = true;
        // Store the information of the new pool.
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accGRAILPerShare: 0,
                depositFeeBP: _depositFeeBP
            })
        );
    }

    // Update reward variables for all pools.
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // View pending GRAILs rewards.
    function pendingGRAIL(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGRAILPerShare = pool.accGRAILPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blockDifference = block.number.sub(pool.lastRewardBlock);
            uint256 grailReward = blockDifference
            .mul(grailPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
            accGRAILPerShare = accGRAILPerShare.add(
                grailReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accGRAILPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        // if the pool reward block number is in the future the farm has not started yet.
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        // Total of pool token that been supplied.
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        // If pool has no LP tokens or pool weight is set to 0 don't distribute rewards.
        // Just update the update to last block.
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // If none of the above is true mint tokens and distribute rewards.
        // First we get the number of blocks that we have advanced forward since the last time we updated the farm.
        uint256 blockDifference = block.number.sub(pool.lastRewardBlock);
        //  After we got to the block timeframe defference, we calculate how much we mint.
        // For each farm we consider the weight it has compared to the other farms.
        uint256 grailReward = blockDifference
        .mul(grailPerBlock)
        .mul(pool.allocPoint)
        .div(totalAllocPoint);

        // A % of reward is going to the developers address so that would be a portion of total reward.
        grail.mint(devaddr, grailReward.div(10));
        // We are minting to the protocol address the address the reward tokens.
        grail.mint(address(this), grailReward);

        //  Calculates how many tokens does each supplied of token get.
        pool.accGRAILPerShare = pool.accGRAILPerShare.add(
            grailReward.mul(1e12).div(lpSupply)
        );
        // We update the farm to the current block number.
        pool.lastRewardBlock = block.number;
    }

    // Deposit pool tokens for GRAIL allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // Update pool when user interacts with the contract.
        updatePool(_pid);

        // If the user has previously deposited money to the farm.
        if (user.amount > 0) {
            // Calculate how much does the farm owe the user.
            uint256 pending = user
            .amount
            .mul(pool.accGRAILPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
            // When user executes deposit, pending rewards get sent to the user.
            if (pending > 0) {
                safeGRAILTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            // If the pool has a deposit fee
            if (pool.depositFeeBP > 0) {
                // Calculate what does it represent in token terms.
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                // Send the deposit fee to the feeAddress
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                // Add the user token to the farm and substract the deposit fee.
                user.amount = user.amount.add(_amount).sub(depositFee);
                // If there is no deposit fee just add the money to the total amount that a user has deposited.
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        // Generate Debt for the previous rewards that the user is not entitled to. Because he just entered.
        user.rewardDebt = user.amount.mul(pool.accGRAILPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw pool tokens,
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        // Check's what is the pending amount considering current block.
        // Assuming that we distribute 5 Tokens for every 1 token.
        //  if user deposited 0.5 tokens, he recives 2.5 tokens.
        uint256 pending = user.amount.mul(pool.accGRAILPerShare).div(1e12).sub(
            user.rewardDebt
        );
        // If the user has a reward pending, send the user his rewards.
        if (pending > 0) {
            safeGRAILTransfer(msg.sender, pending);
        }
        // If the user is withdrawing from the farm more than 0 tokens
        if (_amount > 0) {
            // reduce from the user DB the ammount he is trying to withdraw.
            user.amount = user.amount.sub(_amount);
            // Send  the user the amount of LP tokens he is withdrawing.
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accGRAILPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // In case if rounding error causes pool to not have enough GRAIL TOKENS
    function safeGRAILTransfer(address _to, uint256 _amount) internal {
        // Check how many GRAIL token's on the protocol address.
        uint256 GRAILBal = grail.balanceOf(address(this));
        // In case if the amount requested is higher than the money on the protocol balance.
        if (_amount > GRAILBal) {
            // Transfer absolutely everything from the balance to the contract.
            grail.transfer(_to, GRAILBal);
        } else {
            // If there is enough tokens on the protocol, make the usual transfer.
            grail.transfer(_to, _amount);
        }
    }

    // Update developer fee address.
    function dev(address _devaddr) public {
        // Can be done only by developer
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // Address that collects fees on the protocol.
    // Fees will be used to buy back GRAIL tokens.
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    // Function that sets the new amount of how many new GRAIL Tokens will be minted per each block.
    // TEMP DISABLE ONLY OWNER.
    function updateEmissionRate(uint256 _GRAILPerBlock) public {
        require(hasRole(MANAGER_ROLE, _msgSender()));
        massUpdatePools();
        grailPerBlock = _GRAILPerBlock;
    }

    function burnTokens(uint256 _amount) public {
        require(hasRole(MANAGER_ROLE, _msgSender()));
        grail.transferFrom(address(msg.sender), address(this), _amount);
        grail.burn(_amount);
        tokensBurned = tokensBurned + _amount;
    }
}
