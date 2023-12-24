// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUniswapV2Router02.sol";

import "./SafeERC20.sol";

contract Disclosure {
	IERC20 public weth;
	IERC20 public lpToken;
	uint256 public endTime;
	uint256 public startTime;
	IERC20 public rewardToken;
	uint256 public totalRewards;
  uint256 public totalDeposited;
	uint256 public totalDisclosure;
	uint256 public lastUpdatedGlobal;
  IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	struct User {
		uint256 depositAmount;
		uint256 lastUpdated;
		uint256 disclosure;
    bool rewardWithdrawn;
	}

	mapping(address => User) public users;

	constructor(address _lpToken, address _rewardToken, uint256 _startTime, uint256 _endTime) {
		rewardToken = IERC20(_rewardToken);
		weth = IERC20(router.WETH());
		lpToken = IERC20(_lpToken);
		startTime = _startTime;
		endTime = _endTime;
	}

	function deposit(uint256 amount) external {
		require(block.timestamp >= startTime && block.timestamp <= endTime, "Not in staking period");
		require(lpToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

		updateDisclosure(msg.sender);

		users[msg.sender].depositAmount += amount;
    totalDeposited += amount;
	}

	function withdraw(uint256 amount) external {
		require(amount <= users[msg.sender].depositAmount, "Insufficient staked amount");

		updateDisclosure(msg.sender);

		users[msg.sender].depositAmount -= amount;
    totalDeposited -= amount;
		require(lpToken.transfer(msg.sender, amount), "Transfer failed");
	}

	function updateDisclosure(address userAddress) internal {
		User storage user = users[userAddress];

    uint256 updateTime = block.timestamp;
    if (endTime < updateTime) updateTime = endTime;

		if (user.lastUpdated > 0)
			user.disclosure += (updateTime - user.lastUpdated) * user.depositAmount;

    totalDisclosure += (updateTime - lastUpdatedGlobal) * totalDeposited;
    lastUpdatedGlobal = updateTime;
		user.lastUpdated = updateTime;
	}

  // THIS FUNCTION MAY OR MAY NOT BE USED.
  // IF THE TOKEN BALANCE OF THIS CONTRACT IS 0,
  // EXPECT AIRDROP THROUGH SEPARATE CONTRACT
  function withdrawReward() external {
    require(block.timestamp > endTime, "Reward withdrawal not allowed yet");
    User storage user = users[msg.sender];

    require(!user.rewardWithdrawn, "Already withdrawn");

    if (totalRewards == 0) totalRewards = rewardToken.balanceOf(address(this));

    updateDisclosure(msg.sender);

    uint256 rewardAmount = (totalRewards * user.disclosure) / totalDisclosure;
    user.rewardWithdrawn = true;

    require(rewardToken.transfer(msg.sender, rewardAmount), "Reward transfer failed");
  }

  function currentTime() external view returns (uint256) {
    return block.timestamp;
  }

	function intel(address userAddress) external view returns (uint256 depositAmount, uint256 disclosure, uint256 total, uint256 allowance, uint256 balance, uint256 totalDeposits, uint256 tokensPerEth, uint256 lpPerEth) {
		User memory user = users[userAddress];

    uint256 updateTime = block.timestamp;
    if (endTime < updateTime) updateTime = endTime;

		total = totalDisclosure + (updateTime - lastUpdatedGlobal) * totalDeposited;
    tokensPerEth = rewardTokenPerEth();
		totalDeposits = totalDeposited;
    lpPerEth = lpTokenPerEth();

    if (userAddress != address(0)) {
      depositAmount = user.depositAmount;
      disclosure = user.disclosure + (updateTime - user.lastUpdated) * user.depositAmount;
		  allowance = lpToken.allowance(userAddress, address(this));
      balance = lpToken.balanceOf(userAddress);
    }
	}

  function lpTokenPerEth() public view returns (uint256) {
    uint256 lpTokenBalance = rewardToken.balanceOf(address(lpToken));
    uint256 lpEthBalance = weth.balanceOf(address(lpToken));
    uint256 lpTotalSupply = lpToken.totalSupply();
    uint256 tokensPerEth = rewardTokenPerEth();

    if (tokensPerEth > 0) {
      uint256 tokenValue = 10**18 * lpTokenBalance / tokensPerEth;

      // Return with an extra 10**18
      return 10**18 * 10**18 * lpTotalSupply / (tokenValue + (10**18 * lpEthBalance));
    } else return 0;
  }

  function rewardTokenPerEth() public view returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = address(weth);
    path[1] = address(rewardToken);

    uint256[] memory amountsOut = router.getAmountsOut(10**18, path);
    return amountsOut[1]; // This will give the amount of tokenOut you would get for _amountIn of tokenIn
  }

}



