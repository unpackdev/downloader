// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ISwapRouter.sol";

contract mtETH {

    // State variables
    address public owner;
    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Swapping

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ERC20 compliance
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Mint ETH";
    string public symbol = "mtETH";
    uint8 public decimals = 18;

    function transfer(address recipient, uint amount) external returns (bool) {
        _updateRewards(msg.sender);

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        _updateRewards(sender);

        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    // Variable rate staking
    address public stakingToken;
    address public rewardToken;

    uint private constant MULTIPLIER = 1e18;
    uint private rewardIndex;
    mapping(address => uint) private rewardIndexOf;
    mapping(address => uint) private earned;

    function updateRewardIndex(uint reward) public {
        IERC20(rewardToken).transferFrom(msg.sender, address(this), reward);
        rewardIndex += (reward * MULTIPLIER) / totalSupply;
    }

    function _calculateRewards(address account) private view returns (uint) {
        uint shares = balanceOf[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / MULTIPLIER;
    }

    function calculateRewardsEarned(address account) external view returns (uint) {
        return earned[account] + _calculateRewards(account);
    }

    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }

    function stake(uint amount) external {
        _updateRewards(msg.sender);

        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint amount) external {
        _updateRewards(msg.sender);

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        IERC20(stakingToken).transfer(msg.sender, amount);
    }

    function claim() external returns (uint) {
        _updateRewards(msg.sender);

        uint reward = earned[msg.sender];
        if (reward > 0) {
            earned[msg.sender] = 0;
            IERC20(rewardToken).transfer(msg.sender, reward);
        }

        return reward;
    }

    // Function swaps staked WETH for wstETH or similar assets and back when necessary
    // Once validator network is live, the tokenOut would be Mint Protocol native
    function swapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint amountIn,
        uint amountOutMinimum
    ) public onlyOwner returns (uint amountOut) {
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

    // onlyOwner
    function updateRewardIndexPrivate(uint reward) public onlyOwner {
        rewardIndex += (reward * MULTIPLIER) / totalSupply;
    }

    function setTokens(address _stakingToken, address _rewardToken) public onlyOwner {
      stakingToken = _stakingToken;
      rewardToken = _rewardToken;
    }

    // Emergency
    function emergency(address token) public onlyOwner {
      require(token != stakingToken && token != rewardToken);

      if (token == 0x0000000000000000000000000000000000000000) {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether!");
      } else {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
      }

    }

}
