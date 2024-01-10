// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./TokenTimelock.sol";
import "./Pausable.sol";
import "./Ownable.sol";

interface IVLandDAO {
    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

contract LandStaking is Pausable, Ownable {
    IERC20 public immutable landToken;
    IVLandDAO public immutable vLandToken;

    uint256 public constant rewardRate = 30e18;
    uint256 public immutable startBlock;
    uint256 public immutable endBlock;
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public rewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => TokenTimelock[]) public timeLocks;

    constructor(address _landToken, address _vLandToken)
    Ownable()
    {
        landToken = IERC20(_landToken);
        vLandToken = IVLandDAO(_vLandToken);
        startBlock = block.number;
        endBlock = block.number + 1e6;
    }

    function totalSupply() external view returns (uint256) {
        return vLandToken.totalSupply();
    }

    function balanceOf(address account) external view returns (uint256) {
        return vLandToken.balanceOf(account);
    }

    function lastBlock() public view returns (uint256) {
        return block.number < endBlock ? block.number : endBlock;
    }

    function rewardPerToken() public view returns (uint256) {
        if (vLandToken.totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored +
        (((lastBlock() - lastUpdateBlock) * rewardRate * 1e18) / vLandToken.totalSupply());
    }

    function earned(address account) public view returns (uint256) {
        return
        ((vLandToken.balanceOf(account) *
        (rewardPerToken() - rewardPerTokenPaid[account])) / 1e18) +
        rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = lastBlock();
        rewards[account] = earned(account);
        rewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake(uint256 _amount) external whenNotPaused updateReward(msg.sender) {
        landToken.transferFrom(msg.sender, address(this), _amount);
        vLandToken.mint(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public whenNotPaused updateReward(msg.sender) {
        TokenTimelock timeLock = new TokenTimelock(landToken, msg.sender, block.timestamp + 30 days);
        landToken.transfer(address(timeLock), _amount);
        timeLocks[msg.sender].push(timeLock);
        vLandToken.burn(msg.sender, _amount);
    }

    function getReward() public whenNotPaused updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        landToken.transfer(msg.sender, reward);
    }

    function exit() external {
        withdraw(vLandToken.balanceOf(msg.sender));
        getReward();
    }

    function withdrawAndGetReward(uint _amount) external {
        withdraw(_amount);
        getReward();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}
