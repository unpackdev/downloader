// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "./Manageable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./TransferHelper.sol";
import "./Initializable.sol";

contract AxionMine is Initializable, Manageable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Miner {
        uint256 lpDeposit;
        uint256 accReward;
    }

    struct Mine {
        IERC20 lpToken;
        IERC20 rewardToken;
        uint256 startBlock;
        uint256 lastRewardBlock;
        uint256 blockReward;
        uint256 accRewardPerLPToken;
        IERC721 liqRepNFT;
        IERC721 OG5555_25NFT;
        IERC721 OG5555_100NFT;
    }

    Mine public mineInfo;

    mapping(address => Miner) public minerInfo;

    event Deposit(address indexed minerAddress, uint256 lpTokenAmount);
    event Withdraw(address indexed minerAddress, uint256 lpTokenAmount);
    event WithdrawReward(
        address indexed minerAddress,
        uint256 rewardTokenAmount
    );

    modifier mineUpdater() {
        updateMine();
        _;
    }

    function updateMine() internal {
        if (block.number <= mineInfo.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = mineInfo.lpToken.balanceOf(address(this));

        if (lpSupply != 0) {
            mineInfo.accRewardPerLPToken = getAccRewardPerLPToken(lpSupply);
        }

        mineInfo.lastRewardBlock = block.number;
    }

    function getAccRewardPerLPToken(uint256 _lpSupply)
        internal
        view
        returns (uint256)
    {
        uint256 newBlocks = block.number.sub(mineInfo.lastRewardBlock);
        uint256 reward = newBlocks.mul(mineInfo.blockReward);

        return
            mineInfo.accRewardPerLPToken.add(reward.mul(1e12).div(_lpSupply));
    }

    function getAccReward(uint256 _lpDeposit) internal view returns (uint256) {
        return _lpDeposit.mul(mineInfo.accRewardPerLPToken).div(1e12);
    }

    function withdrawReward() external mineUpdater {
        Miner storage miner = minerInfo[msg.sender];

        uint256 accReward = getAccReward(miner.lpDeposit);

        uint256 reward = handleNFT(accReward.sub(miner.accReward));

        require(reward != 0, 'NOTHING_TO_WITHDRAW');

        safeRewardTransfer(reward);

        emit WithdrawReward(msg.sender, reward);

        miner.accReward = accReward;
    }

    function depositLPTokens(uint256 _amount) external mineUpdater {
        require(_amount != 0, 'ZERO_AMOUNT');

        Miner storage miner = minerInfo[msg.sender];

        uint256 reward = getReward(miner);

        if (reward != 0) {
            safeRewardTransfer(reward);
            emit WithdrawReward(msg.sender, reward);
        }

        mineInfo.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit Deposit(msg.sender, _amount);

        miner.lpDeposit = miner.lpDeposit.add(_amount);
        miner.accReward = getAccReward(miner.lpDeposit);
    }

    function withdrawLPTokens(uint256 _amount) external mineUpdater {
        Miner storage miner = minerInfo[msg.sender];

        require(miner.lpDeposit != 0, 'NOTHING_TO_WITHDRAW');
        require(miner.lpDeposit >= _amount, 'INVALID_AMOUNT');

        uint256 reward = getReward(miner);

        if (reward != 0) {
            safeRewardTransfer(reward);
            emit WithdrawReward(msg.sender, reward);
        }

        mineInfo.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);

        miner.lpDeposit = miner.lpDeposit.sub(_amount);
        miner.accReward = getAccReward(miner.lpDeposit);
    }

    function withdrawAll() external mineUpdater {
        Miner storage miner = minerInfo[msg.sender];

        require(miner.lpDeposit != 0, 'NOTHING_TO_WITHDRAW');

        uint256 reward = getReward(miner);

        if (reward != 0) {
            safeRewardTransfer(reward);
            emit WithdrawReward(msg.sender, reward);
        }

        mineInfo.lpToken.safeTransfer(address(msg.sender), miner.lpDeposit);
        emit Withdraw(msg.sender, miner.lpDeposit);

        miner.lpDeposit = 0;
        miner.accReward = 0;
    }

    function safeRewardTransfer(uint256 _amount) internal {
        uint256 rewardBalance = mineInfo.rewardToken.balanceOf(address(this));
        if (rewardBalance == 0) return;

        if (_amount > rewardBalance) {
            mineInfo.rewardToken.transfer(msg.sender, rewardBalance);
        } else {
            mineInfo.rewardToken.transfer(msg.sender, _amount);
        }
    }

    function getReward(Miner storage miner) internal view returns (uint256) {
        return handleNFT(getAccReward(miner.lpDeposit).sub(miner.accReward));
    }

    function handleNFT(uint256 _amount) internal view returns (uint256) {
        uint256 penalty = _amount.div(10);

        if (mineInfo.liqRepNFT.balanceOf(msg.sender) == 0) {
            _amount = _amount.sub(penalty);
        }

        if (mineInfo.OG5555_25NFT.balanceOf(msg.sender) == 0) {
            _amount = _amount.sub(penalty);
        }

        if (mineInfo.OG5555_100NFT.balanceOf(msg.sender) == 0) {
            _amount = _amount.sub(penalty);
        }

        return _amount;
    }

    function transferRewardTokens(address _to) external onlyManager {
        uint256 rewardBalance = mineInfo.rewardToken.balanceOf(address(this));
        mineInfo.rewardToken.transfer(_to, rewardBalance);
    }

    constructor(address _mineManager) public {
        _setupRole(MANAGER_ROLE, _mineManager);
    }

    function initialize(
        address _rewardTokenAddress,
        uint256 _rewardTokenAmount,
        address _lpTokenAddress,
        uint256 _startBlock,
        uint256 _blockReward,
        address _liqRepNFTAddress,
        address _OG5555_25NFTAddress,
        address _OG5555_100NFTAddress
    ) public initializer {
        TransferHelper.safeTransferFrom(
            address(_rewardTokenAddress),
            msg.sender,
            address(this),
            _rewardTokenAmount
        );

        uint256 lastRewardBlock =
            block.number > _startBlock ? block.number : _startBlock;

        mineInfo = Mine(
            IERC20(_lpTokenAddress),
            IERC20(_rewardTokenAddress),
            _startBlock,
            lastRewardBlock,
            _blockReward,
            0,
            IERC721(_liqRepNFTAddress),
            IERC721(_OG5555_25NFTAddress),
            IERC721(_OG5555_100NFTAddress)
        );
    }

    function getPendingReward() external view returns (uint256) {
        uint256 rewardBalance = mineInfo.rewardToken.balanceOf(address(this));
        if (rewardBalance == 0) return 0;

        Miner storage miner = minerInfo[msg.sender];

        uint256 accRewardPerLPToken = mineInfo.accRewardPerLPToken;
        uint256 lpSupply = mineInfo.lpToken.balanceOf(address(this));

        if (block.number > mineInfo.lastRewardBlock && lpSupply != 0) {
            accRewardPerLPToken = getAccRewardPerLPToken(lpSupply);
        }

        return
            handleNFT(
                miner.lpDeposit.mul(accRewardPerLPToken).div(1e12).sub(
                    miner.accReward
                )
            );
    }
}
