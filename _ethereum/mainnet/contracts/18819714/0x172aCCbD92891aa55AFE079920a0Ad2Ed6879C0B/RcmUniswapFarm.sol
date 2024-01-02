// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IERC20Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Pool.sol";

contract RcmUniswapFarm is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IERC721ReceiverUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct UserInfo {
        address wallet;
        uint256 tokenId;
        uint256 liquidity;
        uint256 pendingDebt;
        uint256 paidOut;
        uint256 enterBlock;
        uint256 exitBlock;
    }

    struct ProgramInfo {
        IUniswapV3Pool pool;
        uint256 rewardPerBlock;
        uint256 totalRewards;
        uint256 paidRewards;
        uint256 lastRewardBlock;
        uint256 liquidity;
        uint256 participants;
        uint256 accRewardPerStake;
        uint256 startBlock;
        uint256 endBlock;
    }

    struct UserTracker {
        uint256 pid;
        uint256 tokenId;
        uint256 index;
    }

    // Address of the Reward Token contract.
    IERC20Upgradeable public rewardToken;
    // NFT manager
    INonfungiblePositionManager public nonfungiblePositionManager;
    // Programs
    ProgramInfo[] public programs;
    // Participants
    mapping(uint256 => UserInfo[]) private _userInfo;
    mapping(address => UserTracker[]) private _userPositions;
    mapping(address => mapping(uint256 => bool)) public unstaked;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    // constructor(IERC20Upgradeable _rewardToken, INonfungiblePositionManager _nonfungiblePositionManager) {
    //     rewardToken = _rewardToken;
    //     nonfungiblePositionManager = _nonfungiblePositionManager;
    // }

    function initialize(IERC20Upgradeable _rewardToken, INonfungiblePositionManager _nonfungiblePositionManager) initializer public {
        __ReentrancyGuard_init();
        __Ownable_init();
        rewardToken = _rewardToken;
        nonfungiblePositionManager = _nonfungiblePositionManager;
    }

    // Create a new program, only owner
    function create(IUniswapV3Pool _pool, uint256 _rewardPerBlock, uint256 _startBlock, uint256 _amount) external onlyOwner {
        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        programs.push(ProgramInfo({
            pool: _pool,
            rewardPerBlock: _rewardPerBlock,
            totalRewards: _amount,
            paidRewards: 0,
            lastRewardBlock: lastRewardBlock,
            liquidity: 0,
            participants: 0,
            accRewardPerStake: 0,
            startBlock: _startBlock,
            endBlock: _startBlock.add(_amount.div(_rewardPerBlock))
        }));
    }

    function updateRewardPerBlock(uint256 _pid, uint256 _reward) external onlyOwner {
        require(block.number < programs[_pid].endBlock, "updateRewardPerBlock: program has ended");
        _updatePool(_pid);
        programs[_pid].rewardPerBlock = _reward;
        uint256 remainingReward = programs[_pid].totalRewards.sub(programs[_pid].paidRewards);
        uint256 remainingBlock = remainingReward.div(programs[_pid].rewardPerBlock);
        programs[_pid].endBlock = block.number + remainingBlock;
    }

    function fund(uint256 _pid, uint256 _amount) external onlyOwner {
        // require(block.number < programs[_pid].endBlock, "fund: program has ended");
        rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        programs[_pid].endBlock += _amount.mul(1e18).div(programs[_pid].rewardPerBlock).div(1e18);
    }

    function withdrawFunds(uint256 _pid, uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);
        programs[_pid].endBlock -= _amount.mul(1e18).div(programs[_pid].rewardPerBlock).div(1e18);
    }

    function updatePool(uint256 _pid) external onlyOwner {
        _updatePool(_pid);
    }

    function positions(address _wallet) public view returns (UserTracker[] memory) {
        return _userPositions[_wallet];
    }

    function deposit(uint256 _pid, uint256 _tokenId) external {
        require(!_isEnded(_pid), "deposit: program has ended");
        (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(_tokenId);
        require(tickLower == -887200 && tickUpper == 887200, "deposit: token must be full ranges");
        nonfungiblePositionManager.safeTransferFrom(address(msg.sender), address(this), _tokenId);
        _enter(_pid, _tokenId, liquidity);
    }

    function withdraw(uint256 _pid, uint256 _tokenId, uint256 _index) external {
        require(_userInfo[_pid][_index].wallet == msg.sender, "withdraw: invalid user");
        require(_userInfo[_pid][_index].tokenId == _tokenId, "withdraw: invalid token");
        require(_userInfo[_pid][_index].exitBlock == 0, "withdraw: token has been withdrawn");
        nonfungiblePositionManager.safeTransferFrom(address(this), address(msg.sender), _tokenId);
        _exit(_pid, _index);
    }

    function claim(uint256 _pid, uint256 _tokenId, uint256 _index, uint256 _amount) external nonReentrant {
        require(_userInfo[_pid][_index].wallet == msg.sender, "claim: invalid user");
        require(_userInfo[_pid][_index].tokenId == _tokenId, "claim: invalid token");
        _updatePool(_pid);
        uint256 availableAmount = _userInfo[_pid][_index].pendingDebt;
        require(_amount <= availableAmount, "claim: requested amount too high");
        rewardToken.safeTransfer(address(msg.sender), _amount);
        _userInfo[_pid][_index].pendingDebt -= _amount;
        _userInfo[_pid][_index].paidOut += _amount;
        programs[_pid].paidRewards += _amount;
    }

    function stake(uint256 _pid, uint256 _tokenId) external nonReentrant {
        require(!_isEnded(_pid), "stake: program has ended");
        require(unstaked[msg.sender][_tokenId] == true, "stake: token is not unstaked");
        (, , , , , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(_tokenId);
        _enter(_pid, _tokenId, liquidity);
        // set unstaked to false
        unstaked[msg.sender][_tokenId] = false;
    }

    function unstake(uint256 _pid, uint256 _tokenId, uint256 _index) external {
        require(_userInfo[_pid][_index].wallet == msg.sender, "unstake: invalid user");
        require(_userInfo[_pid][_index].tokenId == _tokenId, "unstake: invalid token");
        require(_userInfo[_pid][_index].exitBlock == 0, "unstake: token has been withdrawn");
        _exit(_pid, _index);
        // set unstaked to true
        unstaked[msg.sender][_tokenId] = true;
    }

    function stakeInfo(address _wallet, uint256 _pid, uint256 _index) external view returns (UserInfo memory) {
        require(_userInfo[_pid][_index].wallet == _wallet, "stakeInfo: address mismatch");
        // get the program
        ProgramInfo storage program = programs[_pid];
        // if there is no liquidity on the program
        if (program.liquidity == 0 || _userInfo[_pid][_index].exitBlock != 0) {
            return _userInfo[_pid][_index];
        }
        UserInfo memory usrInfo =  _userInfo[_pid][_index];
        // get block passed since last reward block
        uint256 currentBlock = block.number > program.endBlock ? program.endBlock : block.number;
        uint256 lastRewardBlock = program.lastRewardBlock;
        if (lastRewardBlock > currentBlock) {
            lastRewardBlock = currentBlock;
        }
        uint256 blocksPassed = currentBlock.sub(lastRewardBlock);
        // get accumulated reward since last reward block
        uint256 accumulatedReward = blocksPassed.mul(program.rewardPerBlock);
        // calculate accRewardPerStake to distribute
        // multiplied by 1e18 to make sure it's greater than the liquidity
        uint256 accRewardPerStake = accumulatedReward.mul(1e18).div(program.liquidity);
        // estimate user pendingDebt
        uint256 pendingDebt = usrInfo.pendingDebt.add(usrInfo.liquidity.mul(accRewardPerStake).div(1e18));
        return UserInfo({
            wallet: _wallet,
            tokenId: usrInfo.tokenId,
            liquidity: usrInfo.liquidity,
            pendingDebt: pendingDebt,
            paidOut: usrInfo.paidOut,
            enterBlock: usrInfo.enterBlock,
            exitBlock: usrInfo.exitBlock
        });
    }

    function _updatePool(uint256 _pid) internal {
        // get the program
        ProgramInfo storage program = programs[_pid];
        uint256 currentBlock = block.number > program.endBlock ? program.endBlock : block.number;
        // prevent update when program not started yet
        if (currentBlock < program.startBlock) {
            return;
        }
        if (program.lastRewardBlock > program.endBlock) {
            program.lastRewardBlock = program.endBlock;
        }
        // if there is no liquidity on the program
        if (program.liquidity == 0) {
            // only mark the lastRewardBlock
            // this runs only for the first person participating the program
            // so that the person really get the correct block reward and not since the beginning
            program.lastRewardBlock = currentBlock;
            return;
        }
        // get block passed since last reward block
        uint256 blocksPassed = currentBlock.sub(program.lastRewardBlock);
        // get accumulated reward since last reward block
        uint256 accumulatedReward = blocksPassed.mul(program.rewardPerBlock);
        // calculate accRewardPerStake to distribute
        // multiplied by 1e18 to make sure it's greater than the liquidity
        program.accRewardPerStake = accumulatedReward.mul(1e18).div(program.liquidity);
        // distribute accRewardPerStake to all participants
        for (uint256 i = 0; i < _userInfo[_pid].length; ++i) {
            // only look for user that is not exited
            if (_userInfo[_pid][i].exitBlock == 0) {
                // divided by 1e18 because the multiplication above
                _userInfo[_pid][i].pendingDebt += _userInfo[_pid][i].liquidity.mul(program.accRewardPerStake).div(1e18);
            }
        }
        // mark the lastRewardBlock
        program.lastRewardBlock = currentBlock;
    }

    function _enter(uint256 _pid, uint256 _tokenId, uint128 _liquidity) internal {
        // update pool first to calculate latest program state
        _updatePool(_pid);
        // add new participant
        uint256 enterBlock = block.number > programs[_pid].startBlock ? block.number : programs[_pid].startBlock;
        UserInfo memory usrInfo = UserInfo({
            wallet: msg.sender,
            tokenId: _tokenId,
            liquidity: _liquidity,
            pendingDebt: 0,
            paidOut: 0,
            enterBlock: enterBlock,
            exitBlock: 0
        });
        _userInfo[_pid].push(usrInfo);
        // add liquidity
        programs[_pid].liquidity += _liquidity;
        programs[_pid].participants += 1;
        // set tracker
        _userPositions[msg.sender].push(UserTracker({
            pid: _pid,
            tokenId: _tokenId,
            index: _userInfo[_pid].length - 1
        }));
    }

    function _exit(uint256 _pid, uint256 _index) internal {
        // update pool first to calculate latest program state
        _updatePool(_pid);
        // exit participant
        _userInfo[_pid][_index].exitBlock = block.number;
        // reduce liquidity
        programs[_pid].liquidity -= _userInfo[_pid][_index].liquidity;
        programs[_pid].participants -= 1;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _isEnded(uint256 _pid) internal view returns (bool) {
        return programs[_pid].endBlock < block.number;
    }
}
