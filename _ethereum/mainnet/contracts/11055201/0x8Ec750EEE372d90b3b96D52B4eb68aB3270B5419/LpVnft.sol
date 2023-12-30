// pragma solidity ^0.6.2;

// import "./IERC721.sol";
// import "./IERC20.sol";
// import "./SafeERC20.sol";
// import "./IERC165.sol";
// import "./SafeMath.sol";
// import "./AccessControl.sol";
// import "./VNFT.sol";

// contract LpVnft is VNFT {
//     using SafeMath for uint256;
//     using SafeERC20 for IERC20;

//     VNFT public vnft;
//     IERC20 public muse = 0xB6Ca7399B4F9CA56FC27cBfF44F4d2e4Eef1fc81;
//     uint256 public nftId;
//     uint256 public itemId = 1;

//     // Info of each user.
//     struct UserInfo {
//         uint256 amount; // How many LP tokens the user has provided.
//         uint256 rewardDebt; // Reward debt. See explanation below.
//         //
//         // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
//         // entitled to a user but is pending to be distributed is:
//         //
//         //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
//         //
//         // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
//         //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
//         //   2. User receives the pending reward sent to his/her address.
//         //   3. User's `amount` gets updated.
//         //   4. User's `rewardDebt` gets updated.
//     }

//     // Info of each pool.
//     struct PoolInfo {
//         IERC20 lpToken; // Address of LP token contract.
//         uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
//         uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
//         uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
//     }

//     // Info of each pool.
//     PoolInfo[] public poolInfo;
//     mapping(uint256 => mapping(address => UserInfo)) public userInfo;

//     constructor(address _vnft, uint256 _nftId) public {
//         vnft = VNFT(_vnft);
//         nftId = _nftId;
//     }

//     function poolLength() external view returns (uint256) {
//         return poolInfo.length;
//     }

//     // Add a new lp to the pool. Can only be called by the owner.
//     // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
//     function add(
//         uint256 _allocPoint,
//         IERC20 _lpToken,
//         bool _withUpdate
//     ) public onlyOperator {
//         if (_withUpdate) {
//             massUpdatePools();
//         }
//         uint256 lastRewardBlock = block.number > startBlock
//             ? block.number
//             : startBlock;
//         totalAllocPoint = totalAllocPoint.add(_allocPoint);
//         poolInfo.push(
//             PoolInfo({
//                 lpToken: _lpToken,
//                 allocPoint: _allocPoint,
//                 lastRewardBlock: lastRewardBlock,
//                 accSushiPerShare: 0
//             })
//         );
//     }

//     // Update the given pool's SUSHI allocation point. Can only be called by the owner.
//     function set(
//         uint256 _pid,
//         uint256 _allocPoint,
//         bool _withUpdate
//     ) public onlyOperator {
//         if (_withUpdate) {
//             massUpdatePools();
//         }
//         totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
//             _allocPoint
//         );
//         poolInfo[_pid].allocPoint = _allocPoint;
//     }

//     function stake(uint256 _amount, uint256 _poolIndex) external {
//         // ransferFrom  the  LP tokens to here.

//         // check if community pet needs to eat or mine, first buy so has enough muse to buy;
//         mineWithVnft();
//         buyAccessory();
//     }

//     // withdraw rewards;
//     function withdraw(uint256 _amount, uint256 _poolIndex) external {}

//     //send back lp tokens to user;
//     function unstake(uint256 _amount, uint256 _poolIndex) external {}

//     function mineWithVnft() public {
//         if (vnft.lastTimeMined[nftId].add(24 hours) <= block.timestamp) {
//             vnft.claimMiningReward(nftId);
//         }
//         _;
//     }

//     function buyAccessory() public {
//         if (
//             vnft.isVnftAlive(nftId) &&
//             vnft.timeUntilStarving < block.timestamp.add(5 hours)
//         ) {
//             vnft.buyAccessory(nftId, itemId);
//         }
//     }

//     function changeNftId(uint256 _newId) external {
//         nftId = _newId;
//     }

//     // change strtegy and buy differnent getm (baed on community vote)
//     function changeGemId(uint256 _newId) external {
//         itemId = _newId;
//     }

//     // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
//     function safeMuseTransfer(address _to, uint256 _amount) internal {
//         uint256 museBal = muse.balanceOf(address(this));
//         if (_amount > museBal) {
//             muse.transfer(_to, museBal);
//         } else {
//             muse.transfer(_to, _amount);
//         }
//     }
// }
