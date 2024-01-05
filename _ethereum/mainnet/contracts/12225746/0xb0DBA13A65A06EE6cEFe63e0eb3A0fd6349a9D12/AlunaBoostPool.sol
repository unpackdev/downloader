//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.6.2;

import "./Ownable.sol";
import "./IERC20Burnable.sol";
import "./ITreasury.sol";
import "./ISwapRouter.sol";
import "./LPTokenWrapper.sol";
import "./AdditionalMath.sol";
import "./Math.sol";

contract AlunaBoostPool is LPTokenWrapper, Ownable {
    
    using AdditionalMath for uint256;
    
    IERC20 public rewardToken;
    IERC20 public boostToken;
    ITreasury public treasury;
    SwapRouter public swapRouter;
    IERC20 public stablecoin;
    
    
    uint256 public tokenCapAmount;
    uint256 public starttime;
    uint256 public duration;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    // booster variables
    // variables to keep track of totalSupply and balances (after accounting for multiplier)
    uint256 public boostedTotalSupply;
    uint256 public lastBoostPurchase; // timestamp of lastBoostPurchase
    mapping(address => uint256) public boostedBalances;
    mapping(address => uint256) public numBoostersBought; // each booster = 5% increase in stake amt
    mapping(address => uint256) public nextBoostPurchaseTime; // timestamp for which user is eligible to purchase another booster
    uint256 public globalBoosterPrice = 2000e18;
    uint256 public boostThreshold = 10;
    uint256 public boostScaleFactor = 20;
    uint256 public scaleFactor = 100;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);

    modifier checkStart() {
        require(block.timestamp >= starttime,"not start");
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

    constructor(
        uint256 _tokenCapAmount,
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        IERC20 _boostToken,
        address _treasury,
        SwapRouter _swapRouter,
        uint256 _starttime,
        uint256 _duration
    ) public LPTokenWrapper(_stakeToken) {
        tokenCapAmount = _tokenCapAmount;
        boostToken = _boostToken;
        rewardToken = _rewardToken;
        treasury = ITreasury(_treasury);
        stablecoin = treasury.defaultToken();
        swapRouter = _swapRouter;
        starttime = _starttime;
        lastBoostPurchase = _starttime;
        duration = _duration;
        boostToken.safeApprove(address(_swapRouter), uint256(-1));
        stablecoin.safeApprove(address(treasury), uint256(-1));
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (boostedTotalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(boostedTotalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            boostedBalances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getBoosterPrice(address user)
        public view returns (uint256 boosterPrice, uint256 newBoostBalance)
    {
        if (boostedTotalSupply == 0) return (0,0);

        // each previously user-purchased booster will increase price in 5%,
        // that is, 1 booster means 5% increase, 2 boosters mean 10% and so on
        uint256 boostersBought = numBoostersBought[user];
        boosterPrice = globalBoosterPrice.mul(boostersBought.mul(5).add(100)).div(100);

        // increment boostersBought by 1
        boostersBought = boostersBought.add(1);

        // if no. of boosters exceed threshold, increase booster price by boostScaleFactor
        // for each exceeded booster
        if (boostersBought >= boostThreshold) {
            boosterPrice = boosterPrice
                .mul((boostersBought.sub(boostThreshold)).mul(boostScaleFactor).add(100))
                .div(100);
        }

        // 2.5% decrease for every 2 hour interval since last global boost purchase
        boosterPrice = calculateBoostDevaluation(boosterPrice, 975, 1000, (block.timestamp.sub(lastBoostPurchase)).div(2 hours));

        // adjust price based on expected increase in boost supply
        // each booster will increase balance in an order of 10%
        // boostersBought has been incremented by 1 already
        newBoostBalance = balanceOf(user)
            .mul(boostersBought.mul(10).add(100))
            .div(100);
        // uint256 boostBalanceIncrease = newBoostBalance.sub(boostedBalances[user]);
        boosterPrice = boosterPrice
            .mul(balanceOf(user))
            .div(boostedTotalSupply);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) override checkStart  {
        require(amount != 0, "Cannot stake 0");
        super.stake(amount);

        // check user cap
        require(
            balanceOf(msg.sender) <= tokenCapAmount || block.timestamp >= starttime.add(SECONDS_IN_A_DAY),
            "token cap exceeded"
        );

        // boosters do not affect new amounts
        boostedBalances[msg.sender] = boostedBalances[msg.sender].add(amount);
        boostedTotalSupply = boostedTotalSupply.add(amount);

        _getReward(msg.sender);

        // transfer token last, to follow CEI pattern
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) override checkStart {
        require(amount != 0, "Cannot withdraw 0");
        super.withdraw(amount);
        
        // reset boosts :(
        numBoostersBought[msg.sender] = 0;

        // update boosted balance and supply
        updateBoostBalanceAndSupply(msg.sender, 0);

        // in case _getReward function fails, continue
        //(bool success, ) = address(this).call(
        //    abi.encodeWithSignature(
        //       "_getReward(address)",
        //       msg.sender
        //   )
        //);
        
        // to remove compiler warning
        //success;

        // transfer token last, to follow CEI pattern
        stakeToken.safeTransfer(msg.sender, amount);
    }

    function getReward() external updateReward(msg.sender) checkStart {
        _getReward(msg.sender);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function setScaleFactorsAndThreshold(
        uint256 _boostThreshold,
        uint256 _boostScaleFactor,
        uint256 _scaleFactor
    ) external onlyOwner
    {
        boostThreshold = _boostThreshold;
        boostScaleFactor = _boostScaleFactor;
        scaleFactor = _scaleFactor;
    }
    
    function boost() external updateReward(msg.sender) checkStart {
        require(
            block.timestamp > nextBoostPurchaseTime[msg.sender],
            "early boost purchase"
        );

        // save current booster price, since transfer is done last
        // since getBoosterPrice() returns new boost balance, avoid re-calculation
        (uint256 boosterAmount, uint256 newBoostBalance) = getBoosterPrice(msg.sender);
        // user's balance and boostedSupply will be changed in this function
        applyBoost(msg.sender, newBoostBalance);
        
        _getReward(msg.sender);

        boostToken.safeTransferFrom(msg.sender, address(this), boosterAmount);
        
        IERC20Burnable burnableBoostToken = IERC20Burnable(address(boostToken));

        // burn 25%
        uint256 burnAmount = boosterAmount.div(4);
        burnableBoostToken.burn(burnAmount);
        boosterAmount = boosterAmount.sub(burnAmount);
        
        // swap to stablecoin
        address[] memory routeDetails = new address[](3);
        routeDetails[0] = address(boostToken);
        routeDetails[1] = swapRouter.WETH();
        routeDetails[2] = address(stablecoin);
        uint[] memory amounts = swapRouter.swapExactTokensForTokens(
            boosterAmount,
            0,
            routeDetails,
            address(this),
            block.timestamp + 100
        );

        // transfer to treasury
        // index 2 = final output amt
        treasury.deposit(stablecoin, amounts[2]);
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        rewardRate = reward.div(duration);
        lastUpdateTime = starttime;
        periodFinish = starttime.add(duration);
        emit RewardAdded(reward);
    }
    
    function updateBoostBalanceAndSupply(address user, uint256 newBoostBalance) internal {
        // subtract existing balance from boostedSupply
        boostedTotalSupply = boostedTotalSupply.sub(boostedBalances[user]);
    
        // when applying boosts,
        // newBoostBalance has already been calculated in getBoosterPrice()
        if (newBoostBalance == 0) {
            // each booster adds 10% to current stake amount, that is 1 booster means 10%,
            // two boosters mean 20% and so on
            newBoostBalance = balanceOf(user).mul(numBoostersBought[user].mul(10).add(100)).div(100);
        }

        // update user's boosted balance
        boostedBalances[user] = newBoostBalance;
    
        // update boostedSupply
        boostedTotalSupply = boostedTotalSupply.add(newBoostBalance);
    }

    function applyBoost(address user, uint256 newBoostBalance) internal {
        // increase no. of boosters bought
        numBoostersBought[user] = numBoostersBought[user].add(1);

        updateBoostBalanceAndSupply(user, newBoostBalance);
        
        // increase next purchase eligibility by an hour
        nextBoostPurchaseTime[user] = block.timestamp.add(3600);

        // increase global booster price by 1%
        globalBoosterPrice = globalBoosterPrice.mul(101).div(100);

        lastBoostPurchase = block.timestamp;
    }

    function _getReward(address user) internal {
        uint256 reward = earned(user);
        if (reward != 0) {
            rewards[user] = 0;
            emit RewardPaid(user, reward);
            rewardToken.safeTransfer(user, reward);
        }
    }

    /// Imported from: https://forum.openzeppelin.com/t/does-safemath-library-need-a-safe-power-function/871/7
   /// Modified so that it takes in 3 arguments for base
   /// @return the eventually newly calculated boost price
   function calculateBoostDevaluation(uint256 a, uint256 b, uint256 c, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return a;
        }
        else if (exponent == 1) {
            return a.mul(b).div(c);
        }
        else if (a == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = a.mul(b).div(c);
            for (uint256 i = 1; i < exponent; i++)
                z = z.mul(b).div(c);
            return z;
        }
    }
}