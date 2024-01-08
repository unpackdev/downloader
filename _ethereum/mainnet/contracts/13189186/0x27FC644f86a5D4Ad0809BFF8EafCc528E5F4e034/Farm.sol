// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./INFT.sol";

contract Farm is Ownable {
    // this contract lets users stake/unstake ERC20 tokens and mints/burns ERC1155 tokens that represent their stake/membership
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;
    IERC20 public rewardToken;
    struct connectedNFT {
        INFT nft;
        uint256 id;
        uint256 cost;
    }
    mapping(uint256 => connectedNFT) public connectedNFTs;
    uint256 public NFTCount;

    uint256 public constant DURATION = 14 days;
    uint256 private _totalSupply;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    address public rewardDistribution;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Transfered(
        address indexed user1,
        address indexed user2,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 reward);
    event RecoverToken(address indexed token, uint256 indexed amount);

    modifier onlyRewardDistribution() {
        require(
            msg.sender == rewardDistribution,
            "Caller is not reward distribution"
        );
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(IERC20 _stakeToken, IERC20 _rewardToken) {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
    }

    function setNFTDetails(
        INFT[] memory NFTContracts,
        uint256[] memory ids,
        uint256[] memory costs
    ) public onlyOwner {
        require(
            NFTContracts.length == ids.length && ids.length == costs.length,
            "Farm: setNFTDetails input arrays need to have same length"
        );
        for (uint256 i = 0; i < NFTContracts.length; i++) {
            connectedNFTs[i].nft = NFTContracts[i];
            connectedNFTs[i].cost = costs[i];
            connectedNFTs[i].id = ids[i];
        }
        NFTCount = NFTContracts.length;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function mintNFTs(uint256 oldAmount, uint256 newAmount) internal {
        for (uint256 i = 0; i < NFTCount; i++) {
            INFT nft = connectedNFTs[i].nft;
            uint256 cost = connectedNFTs[i].cost;
            uint256 id = connectedNFTs[i].id;
            if (address(nft) == address(0) || cost <= 0) {
                // NFT or cost not defined, skip id
                continue;
            }
            if (oldAmount < cost && newAmount >= cost) {
                // New amount went below threshold, mint 1
                bytes memory data;
                nft.mint(msg.sender, id, 1, data);
            }
        }
    }

    function burnNFTs(uint256 oldAmount, uint256 newAmount) internal {
        for (uint256 i = 0; i < NFTCount; i++) {
            INFT nft = connectedNFTs[i].nft;
            uint256 cost = connectedNFTs[i].cost;
            uint256 id = connectedNFTs[i].id;
            uint256 currentNFTBalance = nft.balanceOf(msg.sender, id);
            if (
                address(nft) == address(0) ||
                cost <= 0 ||
                currentNFTBalance <= 0
            ) {
                // NFT, cost, or current balance not valid, skip ID
                continue;
            }
            if (oldAmount >= cost && newAmount < cost) {
                // New amount went below threshold, burn 1
                nft.burn(msg.sender, id, 1);
            }
        }
    }

    function stake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        uint256 oldAmount = _balances[msg.sender];
        uint256 newAmount = _balances[msg.sender].add(amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
        mintNFTs(oldAmount, newAmount);
    }

    function unstake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        uint256 oldAmount = _balances[msg.sender];
        uint256 newAmount = _balances[msg.sender].sub(amount);

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakeToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
        burnNFTs(oldAmount, newAmount);
    }

    function exit() external {
        unstake(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        require(
            reward < uint256(-1) / 10**22,
            "Farm: rewards too large, would lock"
        );
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function recoverExcessToken(address token, uint256 amount)
        external
        onlyOwner
    {
        IERC20(token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(token, amount);
    }
}
