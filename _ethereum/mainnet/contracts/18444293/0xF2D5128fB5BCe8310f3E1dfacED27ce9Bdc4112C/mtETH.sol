// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ISwapRouter.sol";

/*

  Mint Protocol:    Levered Ethereum 2.0 staking yields.
  Telegram:         https://t.me/MintProtocol
  Website:          https://www.mintprotocol.app/
  Twitter:          https://twitter.com/MintProtocolApp
  Medium:           https://medium.com/@mintprotocol
  Dapp:             https://tech.mintprotocol.app/

   _____  .__        __    __________                __                      .__   
  /     \ |__| _____/  |_  \______   \_______  _____/  |_  ____   ____  ____ |  |  
 /  \ /  \|  |/    \   __\  |     ___/\_  __ \/  _ \   __\/  _ \_/ ___\/  _ \|  |  
/    Y    \  |   |  \  |    |    |     |  | \(  <_> )  | (  <_> )  \__(  <_> )  |__
\____|__  /__|___|  /__|    |____|     |__|   \____/|__|  \____/ \___  >____/|____/
        \/        \/                                                 \/            

  **Unofficial contract**
*/


contract mtETH {
    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    // Comptroller
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    // Comptroller

    // Token swapping
    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

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
    // Token swapping


    // Variable rate staking
    address public stakingToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    address public rewardToken = 0xda98A950CcE17b97DB7886DC5486dfb697c4053F; // MINT

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
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        _updateRewards(msg.sender);

        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    // ERC20 compliance

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
    // Variable rate staking


    // Fixed rate staking - COMING SOON

}
