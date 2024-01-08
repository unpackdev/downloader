// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./STARToken.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./IUniswap.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";

contract EthStarterFarming is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, uint256 amountETH, uint256 amountLP);
    event Withdrawn(address indexed to, uint256 amountETH, uint256 amountLP);
    event Claimed(address indexed to, uint256 amount);
    event Halving(uint256 amount);
    event Received(address indexed from, uint256 amount);

    STARToken public startToken;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public weth;
    address payable public devAddress;
    address public pairAddress;

    struct AccountInfo {
        // Staked LP token balance
        uint256 balance;
        uint256 peakBalance;
        uint256 withdrawTimestamp;
        uint256 reward;
        uint256 rewardPerTokenPaid;
    }
    mapping(address => AccountInfo) public accountInfos;

    mapping(address => bool) public bscsDevs;

    // Staked LP token total supply
    uint256 private _totalSupply = 0;

    uint256 public rewardDuration = 7 days;
    uint256 public rewardAllocation = 500 * 1e18;
    uint256 public lastUpdateTimestamp = 0;

    uint256 public rewardRate = 0;
    uint256 public rewardPerTokenStored = 0;

    // Farming will be open on this timestamp
    uint256 public farmingStartTimestamp = 1628985600; // Thursday, July 1, 2021 12:00:00 AM
    bool public farmingStarted = false;

    // Max 25% / day LP withdraw
    uint256 public withdrawLimit = 25;
    uint256 public withdrawCycle = 24 hours;

    // Burn address
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnFeeX100 = 300;

    modifier onlyBscsDev() {
        require(
            owner == msg.sender || bscsDevs[msg.sender],
            "You are not dev."
        );
        _;
    }

    constructor(address _startToken) public {
        startToken = STARToken(address(_startToken));

        router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        factory = IUniswapV2Factory(router.factory());
        weth = router.WETH();
        devAddress = msg.sender;
        pairAddress = factory.getPair(address(startToken), weth);

        // Calc reward rate
        rewardRate = rewardAllocation.div(rewardDuration);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function stake() external payable nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);

        require(msg.value > 0, "Cannot stake 0");
        require(
            !address(msg.sender).isContract(),
            "Please use your individual account"
        );

        // 50% used to buy START
        address[] memory swapPath = new address[](2);
        swapPath[0] = address(weth);
        swapPath[1] = address(startToken);
        IERC20(startToken).safeApprove(address(router), 0);
        IERC20(startToken).safeApprove(address(router), msg.value.div(2));
        uint256[] memory amounts = router.swapExactETHForTokens{
            value: msg.value.div(2)
        }(uint256(0), swapPath, address(this), block.timestamp + 1 days);
        uint256 boughtStart = amounts[amounts.length - 1];

        // Add liquidity
        uint256 amountETHDesired = msg.value.sub(msg.value.div(2));
        IERC20(startToken).approve(address(router), boughtStart);
        (, , uint256 liquidity) = router.addLiquidityETH{
            value: amountETHDesired
        }(
            address(startToken),
            boughtStart,
            1,
            1,
            address(this),
            block.timestamp + 1 days
        );

        // Add LP token to total supply
        _totalSupply = _totalSupply.add(liquidity);

        // Add to balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.add(
            liquidity
        );
        // Set peak balance
        if (
            accountInfos[msg.sender].balance >
            accountInfos[msg.sender].peakBalance
        ) {
            accountInfos[msg.sender].peakBalance = accountInfos[msg.sender]
                .balance;
        }

        // Set stake timestamp as withdraw timestamp
        // to prevent withdraw immediately after first staking
        if (accountInfos[msg.sender].withdrawTimestamp == 0) {
            accountInfos[msg.sender].withdrawTimestamp = block.timestamp;
        }

        emit Staked(msg.sender, msg.value, liquidity);
    }

    function withdraw() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);

        require(
            accountInfos[msg.sender].withdrawTimestamp + withdrawCycle <=
                block.timestamp,
            "You must wait more time since your last withdraw or stake"
        );
        require(accountInfos[msg.sender].balance > 0, "Cannot withdraw 0");

        // Limit withdraw LP token
        uint256 amount = accountInfos[msg.sender]
            .peakBalance
            .mul(withdrawLimit)
            .div(100);
        if (accountInfos[msg.sender].balance < amount) {
            amount = accountInfos[msg.sender].balance;
        }

        // Reduce total supply
        _totalSupply = _totalSupply.sub(amount);
        // Reduce balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.sub(
            amount
        );
        if (accountInfos[msg.sender].balance == 0) {
            accountInfos[msg.sender].peakBalance = 0;
        }
        // Set timestamp
        accountInfos[msg.sender].withdrawTimestamp = block.timestamp;

        // Remove liquidity in uniswap
        IERC20(pairAddress).approve(address(router), amount);
        (uint256 tokenAmount, uint256 bnbAmount) = router.removeLiquidity(
            address(startToken),
            weth,
            amount,
            0,
            0,
            address(this),
            block.timestamp + 1 days
        );

        // Burn 3% START, send balance to sender
        uint256 burnAmount = tokenAmount.mul(burnFeeX100).div(10000);
        if (burnAmount > 0) {
            tokenAmount = tokenAmount.sub(burnAmount);
            startToken.transfer(address(BURN_ADDRESS), burnAmount);
        }
        startToken.transfer(msg.sender, tokenAmount);

        // Withdraw BNB and send to sender
        IWETH(weth).withdraw(bnbAmount);
        msg.sender.transfer(bnbAmount);

        emit Withdrawn(msg.sender, bnbAmount, amount);
    }

    function claim() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);

        uint256 reward = accountInfos[msg.sender].reward;
        require(reward > 0, "There is no reward to claim");

        if (reward > 0) {
            // Reduce first
            accountInfos[msg.sender].reward = 0;
            // Apply tax
            uint256 taxDenominator = claimTaxDenominator();
            uint256 tax = taxDenominator > 0 ? reward.div(taxDenominator) : 0;
            uint256 net = reward.sub(tax);

            // Send reward
            startToken.transfer(msg.sender, net);
            if (tax > 0) {
                // Burn taxed token
                startToken.transfer(BURN_ADDRESS, tax);
            }

            emit Claimed(msg.sender, reward);
        }
    }

    function withdrawStart() external onlyOwner {
        startToken.transfer(devAddress, startToken.balanceOf(address(this)));
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return accountInfos[account].balance;
    }

    function burnedTokenAmount() public view returns (uint256) {
        return startToken.balanceOf(BURN_ADDRESS);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored.add(
                lastRewardTimestamp()
                    .sub(lastUpdateTimestamp)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function lastRewardTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function rewardEarned(address account) public view returns (uint256) {
        return
            accountInfos[account]
                .balance
                .mul(
                    rewardPerToken().sub(
                        accountInfos[account].rewardPerTokenPaid
                    )
                )
                .div(1e18)
                .add(accountInfos[account].reward);
    }

    // Token price in eth
    function tokenPrice() public view returns (uint256) {
        uint256 bnbAmount = IERC20(weth).balanceOf(pairAddress);
        uint256 tokenAmount = IERC20(startToken).balanceOf(pairAddress);
        return bnbAmount.mul(1e18).div(tokenAmount);
    }

    function claimTaxDenominator() public view returns (uint256) {
        if (block.timestamp < farmingStartTimestamp + 7 days) {
            return 4;
        } else if (block.timestamp < farmingStartTimestamp + 14 days) {
            return 5;
        } else if (block.timestamp < farmingStartTimestamp + 30 days) {
            return 10;
        } else if (block.timestamp < farmingStartTimestamp + 45 days) {
            return 20;
        } else {
            return 0;
        }
    }

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTimestamp = lastRewardTimestamp();
        if (account != address(0)) {
            accountInfos[account].reward = rewardEarned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    // Check if farming is started
    function _checkFarming() internal {
        require(
            farmingStartTimestamp <= block.timestamp,
            "Please wait until farming started"
        );
        if (!farmingStarted) {
            farmingStarted = true;
            lastUpdateTimestamp = block.timestamp;
        }
    }

    function addDevAddress(address _devAddr) external onlyOwner {
        bscsDevs[_devAddr] = true;
    }

    function deleteDevAddress(address _devAddr) external onlyOwner {
        bscsDevs[_devAddr] = false;
    }

    function setFarmingStartTimestamp(
        uint256 _farmingTimestamp,
        bool _farmingStarted
    ) external onlyBscsDev {
        farmingStartTimestamp = _farmingTimestamp;
        farmingStarted = _farmingStarted;
    }

    function setBurnFee(uint256 _burnFee) external onlyBscsDev {
        burnFeeX100 = _burnFee;
    }

    function setWithdrawInfo(uint256 _withdrawLimit, uint256 _withdrawCycle)
        external
        onlyBscsDev
    {
        withdrawLimit = _withdrawLimit;
        withdrawCycle = _withdrawCycle;
    }
}
