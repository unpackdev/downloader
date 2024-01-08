// SPDX-License-Identifier: MIT;

pragma solidity >=0.8.0;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

contract ICO is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    struct ICOStateSchema {
        uint256 currentIteration;
        uint256 currentPrice;
        uint256 ICOAllocatedTokensAmount;
        uint256 tokensLeft;
    }

    uint256 public oneIterationTokenAmount = 10 * 10 ** 6 * 10 ** 10;

    bool public icoCompleted;
    uint256 public icoStartTime;
    uint256 public icoEndTime;
    address public tokenAddress;
    uint256 public currentIterationOfICO;
    uint256 public current_allocatedTokens;
    uint256 public minLimit = 1 * 10 ** 10;
    uint256 public maxLimit = 1 * 10 ** 8 * 10 ** 10;
    uint256 private referralBonus = 20;
    uint256 private commission = 8 * 10 ** 15;
    uint256 private maxRoundICO = 200;

    AggregatorV3Interface private priceFeed;
    uint256 public usdPrice;
    uint256 private startPriceInUSD = 5; // since this value is 0.0005 . Multiplying it by 10000
    uint256 private stepPriceInUSD;

    mapping(address => bool) allowedInvestors;

    event Allocated(uint256 amount);
    event WithdrawedETH(address user, uint256 amount);
    event MinLimitUpdated(uint256 newLimit);
    event MaxLimitUpdated(uint256 newLimit);
    event Bought(address buyer, uint256 amount, uint256 usdPrice);

    modifier allowedInvestor {
        require(allowedInvestors[msg.sender], "Your address not allowed. Please contact with owner.");
        _;
    }

    modifier whenIcoStart {
        require(!icoCompleted, 'ICO completed');
        require(icoStartTime != 0, 'ICO has not started yet');
        _;
    }

    constructor(address _tokenAddress, address owner){
        require(_tokenAddress != address(0) && owner != address(0), "Incorrect addresses");
        tokenAddress = _tokenAddress;
        transferOwnership(owner);
        allowedInvestors[owner] = true;
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /// can be accessed only by owner
    function startICO() public onlyOwner {
        require(icoStartTime == 0, "ICO was started before");
        _allocate();
        icoStartTime = block.timestamp;
    }

    /// can be accessed only by owner
    function setMinLimit(uint256 newLimit) public onlyOwner {
        minLimit = newLimit;
        emit MinLimitUpdated(maxLimit);
    }

    /// can be accessed only by owner
    function setMaxLimit(uint256 newLimit) public onlyOwner {
        maxLimit = newLimit;
        emit MaxLimitUpdated(maxLimit);
    }

    /// can be accessed only by owner
    function setReferralBonus(uint256 _bonus) external onlyOwner {
        require(_bonus <= 100, 'Referral bonus should not be more than 100%');
        referralBonus = _bonus;
    }

    /// can be accessed only by owner
    function getReferralBonus() external view returns (uint256) {
        return referralBonus;
    }

    /// can be accessed only by owner
    function setCommission(uint256 _commission) external onlyOwner {
        commission = _commission;
    }

    /// read only
    /// returns uint256
    function getCommission() external view returns (uint256) {
        return commission;
    }

    /// can be accessed only by owner
    function addAddressToAllowed(address client) public onlyOwner {
        allowedInvestors[client] = true;
    }

    /// can be accessed only by owner
    function removeAddressFromAllowed(address client) public onlyOwner {
        allowedInvestors[client] = false;
    }

    function _allocate() private {
        require(currentIterationOfICO <= maxRoundICO, 'Funding cycle ended');
        if (icoStartTime == 0) {
            usdPrice = startPriceInUSD;
        } else if (currentIterationOfICO == 0) {
            oneIterationTokenAmount = 19 * 10 ** 5 * 10 ** 10;
            usdPrice = 10;
            // to have correct order over startPriceInUSD -> Multiplying 0.001 by 10000
            stepPriceInUSD = 1;
            currentIterationOfICO++;
        } else if (currentIterationOfICO > 0 && currentIterationOfICO < 100) {
            usdPrice = usdPrice.add(stepPriceInUSD);
            currentIterationOfICO++;
        } else if (currentIterationOfICO == 100) {
            oneIterationTokenAmount = 8 * 10 ** 6 * 10 ** 10;
            usdPrice = 110;
            // to have correct order over startPriceInUSD -> Multiplying 0.011 by 10000
            stepPriceInUSD = 10;
            currentIterationOfICO++;
        } else if (currentIterationOfICO > 100 && currentIterationOfICO <= maxRoundICO) {
            usdPrice = usdPrice.add(stepPriceInUSD);
            currentIterationOfICO++;
        }
        current_allocatedTokens = current_allocatedTokens.add(oneIterationTokenAmount);
        emit Allocated(current_allocatedTokens);
    }

    receive() external payable {
        buy();
    }

    function _getAmountForETH(uint amountETH) private view returns (uint256){
        (
        ,
        // rate is giving with precision to actual price * 10 ** 8
        int rate,
        ,
        ,
        ) = priceFeed.latestRoundData();
        // So here we have to divide final amount
        uint256 usdAmount = amountETH.mul(uint256(rate)).div(10 ** 8);
        // Since token price is less then 1 - we have to multiply the smallest value to 10 ** 4
        // So on every calculation of price it should be divided into 10 ** 4
        uint256 amountTokens = usdAmount.div(usdPrice).div(10 ** 14).mul(10 ** 10);
        if (amountTokens > current_allocatedTokens) {
            uint256 tokenPrice = usdPrice;
            uint256 current_allocated = current_allocatedTokens;
            uint256 icoRound = currentIterationOfICO;
            amountTokens = 0;
            while (usdAmount > 0) {
                uint256 amount = usdAmount.div(tokenPrice).div(10 ** 4);
                if (amount > current_allocated) {
                    amountTokens = amountTokens.add(current_allocated);
                    uint256 ethForAllocated = getCost(current_allocated);
                    uint256 usdForAllocated = ethForAllocated.mul(uint256(rate)).div(10 ** 8);
                    usdAmount = usdAmount.sub(usdForAllocated);
                    if (currentIterationOfICO < maxRoundICO) {
                        icoRound++;
                    }
                    (uint256 roundPrice, uint256 stepPrice) = getTokenPrice(icoRound);
                    tokenPrice = roundPrice.add(stepPrice);
                    amount = usdAmount.div(tokenPrice).div(10 ** 4);
                    current_allocated = getTokensPerIteration(icoRound);
                } else if (amount <= current_allocated) {
                    amountTokens = amountTokens.add(amount);
                    usdAmount = 0;
                }
            }
        }
        return amountTokens;
    }

    /// get cost is calculating price including switch to different price range
    /// read only
    /// returns uint256
    function getCost(uint amount) public view returns (uint256){
        uint256 usdCost;
        uint256 ethCost;
        int exchangeRate = getLatestPrice();
        if (amount <= current_allocatedTokens) {
            usdCost = amount.mul(usdPrice).div(10 ** 4);
            ethCost = getPriceInETH(usdCost, exchangeRate);
        } else {
            uint256 price = usdPrice;
            uint256 stepPrice;
            uint256 current_allocated = current_allocatedTokens;
            uint256 icoRound = currentIterationOfICO;
            uint256 iterationAmount;
            while (amount > 0) {
                if (current_allocated > 0) {
                    amount = amount.sub(current_allocated);
                    usdCost = current_allocated.div(10 ** 4).mul(price).add(usdCost);
                    current_allocated = 0;
                    icoRound++;
                    (price, stepPrice) = getTokenPrice(icoRound);
                    price = price.add(stepPrice);
                }
                // get amounts for the next round since it could be different
                iterationAmount = getTokensPerIteration(icoRound);
                if (amount > iterationAmount) {
                    amount = amount.sub(iterationAmount);
                    usdCost = iterationAmount.div(10 ** 4).mul(price).add(usdCost);
                    icoRound++;
                    (price, stepPrice) = getTokenPrice(icoRound);
                    price = price.add(stepPrice);
                }
                iterationAmount = getTokensPerIteration(icoRound);
                if (amount <= getTokensPerIteration(icoRound)) {
                    usdCost = amount.div(10 ** 4).mul(price).add(usdCost);
                    amount = 0;
                }
            }
            ethCost = getPriceInETH(usdCost, exchangeRate);
        }
        return ethCost;
    }

    function _changeCurrentAllocatedTokens(uint256 amount, uint256 ethForTokens) private {
        if (amount <= current_allocatedTokens) {
            current_allocatedTokens = current_allocatedTokens.sub(amount);
        } else {
            uint256 amountForLoop = amount;
            while (amountForLoop > 0) {
                if (amountForLoop > current_allocatedTokens) {
                    amountForLoop = amountForLoop.sub(current_allocatedTokens);
                    uint256 ethForStep = getCost(current_allocatedTokens);
                    ethForTokens = ethForTokens.sub(ethForStep);
                    current_allocatedTokens = 0;
                    _allocate();
                    amountForLoop = _getAmountForETH(ethForTokens);
                } else if (amountForLoop <= current_allocatedTokens) {
                    current_allocatedTokens = current_allocatedTokens.sub(amountForLoop);
                    amountForLoop = 0;
                }
            }
        }
    }

    function _completeICO() private {
        if (current_allocatedTokens < minLimit && currentIterationOfICO >= maxRoundICO) {
            icoEndTime = block.timestamp;
            icoCompleted = true;
        } else if (current_allocatedTokens == 0) {
            _allocate();
        }
    }

    function _sendTokens(address client, uint256 amountToken) private nonReentrant {
        IERC20(tokenAddress).transfer(client, amountToken);
        emit Bought(client, amountToken, usdPrice);
    }

    function withdrawReward() public nonReentrant onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, 'Not enough reward for withdraw');
        (bool success,) = address(msg.sender).call{value : amount}("");
        require(success, 'Transfer failed');
        emit WithdrawedETH(msg.sender, amount);
    }

    /// read only
    /// returns ICOStateSchema
    function getCurrentICOState() public view returns (ICOStateSchema memory currentState) {
        require(icoStartTime != 0, 'ICO was not started can not _allocate new tokens');
        currentState.currentIteration = currentIterationOfICO;
        currentState.currentPrice = usdPrice;
        currentState.ICOAllocatedTokensAmount = oneIterationTokenAmount;
        currentState.tokensLeft = current_allocatedTokens;
    }

    /// available only after start of ICO
    /// accessible only by allowed investors
    /// payable
    /// returns uint256
    function buy() public payable whenIcoStart allowedInvestor {
        require(msg.value > commission, 'Amount of ETH smaller than commission');
        uint256 ethForTokens = msg.value.sub(commission);
        uint256 amount = _getAmountForETH(ethForTokens);
        require(amount >= minLimit, 'Amount for one purchase is too low');
        require(amount <= maxLimit, 'Limit for one purchase is reached');
        _changeCurrentAllocatedTokens(amount, ethForTokens);
        _sendTokens(msg.sender, amount);
        _completeICO();
    }

    /// payable
    /// accessible only by allowed investors
    function buyWithReferral(address payable referral) external payable
    allowedInvestor whenIcoStart {
        require(referral != address(0), 'Referral address should not be empty');
        require(referral != msg.sender, 'Referral address should not be equal buyer address');
        require(msg.value > commission, 'Amount of ETH smaller than commission');
        uint256 bonusAmount = (msg.value.sub(commission)).mul(referralBonus).div(100);
        buy();
        (bool success,) = referral.call{value : bonusAmount}("");
        require(success);
    }

    /// available only after start of ICO
    /// payable
    /// can be accessed only by owner
    function buyFor(address buyer) public payable onlyOwner whenIcoStart {
        uint256 amount = _getAmountForETH(msg.value);
        require(amount >= minLimit, 'Amount for one purchase is too low');
        require(amount <= maxLimit, 'Limit for one purchase is reached');
        require(buyer != address(0), 'Buyer address should not be empty');
        _changeCurrentAllocatedTokens(amount, msg.value);
        IERC20(tokenAddress).transfer(buyer, amount);
        emit Bought(buyer, amount, usdPrice);
        _completeICO();
    }

    /// available only after start of ICO
    /// payable
    /// can be accessed only by owner
    function buyForWithReferral(address buyer, address payable referral) external payable
    onlyOwner whenIcoStart {
        require(referral != address(0), 'Referral address should not be empty');
        require(referral != msg.sender, 'Referral address should not be equal buyer address');
        require(referral != buyer, 'Referral address should not be equal buyer address');
        uint256 bonusAmount = (msg.value).mul(referralBonus).div(100);
        buyFor(buyer);
        (bool success,) = referral.call{value : bonusAmount}("");
        require(success);
    }

    /// read only
    /// returns int
    function getLatestPrice() public view returns (int) {
        (
        ,
        int price,
        ,
        ,
        ) = priceFeed.latestRoundData();
        return 1 ether / (price / (10 ** 8));
    }

    /// returns uint256
    function getPriceInETH(uint256 amount, int exchangeRate) public pure returns (uint256) {
        return amount.mul(uint256(exchangeRate)).div(10 ** 10);
    }

    /// read only
    /// returns uint256
    function getTokenPrice(uint256 icoIteration) public view returns (uint256, uint256) {
        require(icoIteration <= maxRoundICO, 'Incorrect ICO round');
        uint256 price;
        uint256 stepPrice;
        if (icoIteration == 0) {
            price = startPriceInUSD;
        } else if (icoIteration == 1) {
            price = 10;
            stepPrice = 0;
        } else if (icoIteration > 1 && icoIteration <= 100) {
            price = 10;
            stepPrice = icoIteration.sub(1);
        } else if (icoIteration == 101) {
            price = 110;
            stepPrice = 0;
        } else {
            price = 110;
            stepPrice = icoIteration.sub(101).mul(10);
        }
        return (price, stepPrice);
    }

    /// read only
    /// returns uint256
    function getTokensPerIteration(uint256 icoIteration) public view returns (uint256) {
        require(icoIteration <= maxRoundICO, 'Incorrect ICO round');
        uint256 amount;
        if (icoIteration == 0) {
            amount = 10 * 10 ** 6 * 10 ** 10;
        } else if (icoIteration > 0 && icoIteration <= 100) {
            amount = 19 * 10 ** 5 * 10 ** 10;
        } else {
            amount = 8 * 10 ** 6 * 10 ** 10;
        }
        return amount;
    }
}
