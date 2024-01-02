//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestAnswer() external view returns (int256);
}

contract ICO is ReentrancyGuard {
    IERC20 public grl = IERC20(0xA067237f8016d5e3770CF08b20E343Ab9ee813d5);       
    IERC20 public dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    AggregatorV3Interface private ethToUsdPriceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    AggregatorV3Interface private daiToEthPriceFeed = AggregatorV3Interface(
            0x773616E4d11A78F511299002da57A0a94577F1f4
        );

    uint256 public immutable totalTokens = 8 * 10 ** 7 * 10 ** 9;
    address public immutable admin;
    uint256 public tokensSold;
    bool public isGCOStarted;
    address immutable fundReceiver;
    uint256 public immutable tokensPerPhase = 2 * 10 ** 7 * 10 ** 9;
     uint256[] public daiPricePerPhase;
    uint256[] public usdtPricePerPhase;
    uint256 public vestDuration = 15778458 seconds; // 6 Months
    uint256 public cliffPeriod = 2629743 seconds; // 30 Days
    uint256 public slicePeriod = 2629743 seconds; // 30 Days
    uint256 public immediatePercentageReleased = 25; // 25%

    uint256 private startTime;
    uint256 public phaseDuration;

    struct VestingSchedule {
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 slicePeriodSeconds;
        uint256 amountTotal;
        uint256 released;
    }
    mapping(address => mapping(uint256 => VestingSchedule)) public vestedUserDetail;
    mapping(address => uint256) private holdersVestingCount;

    event PurchasedWithEth(address indexed from, address indexed to, uint256 ethValue, uint256 tokensPurchased);
    event PurchasedWithToken(address indexed from, address indexed to, uint256 tokenValue, uint256 tokensPurchased);
    event TokensClaimed(address indexed claimer, uint256 releasableTokens, uint256 purchaseIndex);
    event TokenReleased(uint256 releaseable, uint256 claimed);

    constructor() {
        daiPricePerPhase = new uint256[](4);   
        daiPricePerPhase[0] = 12545280000000000; //0.01254528
        daiPricePerPhase[1] = 13799808000000000; //0.013799808
        daiPricePerPhase[2] = 15179789000000000; //0.015179789
        daiPricePerPhase[3] = 16697768000000000; //0.016697768

        usdtPricePerPhase = new uint256[](4);
        usdtPricePerPhase[0] = 12540; //0.01254
        usdtPricePerPhase[1] = 13790; //0.01379
        usdtPricePerPhase[2] = 15170; //0.01517
        usdtPricePerPhase[3] = 16690; //0.01669

        admin = msg.sender;
        phaseDuration = 345600;
        fundReceiver = address(0x48FD2F7CaC483A923F3F164997B2b6435AF50205);
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "You're not authorized!");
        _;
    }

     function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _amount
    ) internal {
        require(_duration >= _cliff, "TokenVesting: duration must be >= cliff");
        uint256 cliff = _start+_cliff;
       
        uint256 currentVestingIndex = holdersVestingCount[_beneficiary]++;
        vestedUserDetail[_beneficiary][currentVestingIndex] = VestingSchedule(
            _beneficiary,
            cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _amount,
            0
        );
    }

    function getVestingUserCount(address _beneficiary) external view returns (uint256) {
        return holdersVestingCount[_beneficiary];
    }


    function getReleaseableAmount(address beneficiary) public view returns (uint256 totalReleasable, uint256 totalRemaining) {
        uint256 vestingCount = holdersVestingCount[beneficiary];
        for (uint256 i = 0; i < vestingCount; i++) {
            VestingSchedule storage vestingSchedule = vestedUserDetail[beneficiary][i];
            (uint256 releasable, uint256 remaining) = _computeReleasableAmount(vestingSchedule);

            totalReleasable += releasable;
            totalRemaining += remaining;
        }
        return (totalReleasable, totalRemaining);
    }

    function claimReleasableTokens() public {
        uint256 totalReleasable;
        uint256 totalRemaining;
        uint256 vestingCount = holdersVestingCount[msg.sender];
        require(vestingCount > 0, "No tokens purchased");
        for (uint256 i = 0; i < vestingCount; i++) {
            VestingSchedule storage vestingSchedule = vestedUserDetail[msg.sender][i];
            (uint256 releasable, uint256 remaining) = _computeReleasableAmount(vestingSchedule);
            totalReleasable += releasable;
            totalRemaining += remaining;

            vestingSchedule.released += releasable;
        }
        require(totalReleasable>0,"NO tokens to claim!");
        grl.transfer(msg.sender,totalReleasable);
    }

  function _computeReleasableAmount(VestingSchedule memory vestingSchedule) 
        internal view returns (uint256 releasable, uint256 remaining) {

        uint256 currentTime = block.timestamp;
        uint256 totalVested = 0;
        if (currentTime < vestingSchedule.cliff) {
            return (0, vestingSchedule.amountTotal - vestingSchedule.released);
        } else if (currentTime >= vestingSchedule.start + vestingSchedule.duration) {
            releasable = vestingSchedule.amountTotal - vestingSchedule.released;
            return (releasable, 0);
        } else {
            
            uint256 timeFromCliffEnd = currentTime - vestingSchedule.cliff;
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromCliffEnd / secondsPerSlice;
            uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;

            totalVested = (vestingSchedule.amountTotal * vestedSeconds) / vestingSchedule.duration;
        }

        releasable = totalVested - vestingSchedule.released;
        remaining = vestingSchedule.amountTotal - totalVested;
        return (releasable, remaining);
    }

     function buyWithEth() public noReentrant  payable {
        require(isGCOStarted == true, "GCO not started yet!");
        require(msg.value > 0, "Inavlid eth amount");
        uint256 tokensToBuy = grlOfEth(msg.value);
        require(
            tokensSold + tokensToBuy <= totalTokens,
            "Not enough tokens left"
        );
        require(
            block.timestamp <= startTime + phaseDuration * 4,
            "No more coin offering!"
        );
        uint256 immediateTokens = (tokensToBuy*immediatePercentageReleased)/100;
        uint256 tokenToVest = tokensToBuy - immediateTokens;
        tokensSold += tokensToBuy;
        createVestingSchedule(msg.sender, block.timestamp, cliffPeriod, vestDuration, slicePeriod, tokenToVest);
        grl.transfer(msg.sender, immediateTokens);
       
       emit PurchasedWithEth(address(this), msg.sender, msg.value,tokensToBuy);
    }


   function buyWithToken(address tokenAddress, uint256 _amount) noReentrant public {
        require(isGCOStarted == true, "GCO not started yet!");
        require(_amount > 0);
        IERC20 token = IERC20(tokenAddress);
        uint256 tokensToBuy;
        token == dai? tokensToBuy = grlOfDai(_amount) : tokensToBuy = grlOfUsdt(_amount);
        
        require(tokensSold + tokensToBuy <= totalTokens, "Not enough tokens left");
        require(block.timestamp <= startTime + phaseDuration * 4, "No more coin offering!");

        require(token.balanceOf(msg.sender) >= _amount, "You must have enough Tokens to buy GRL!");
        require(token.transferFrom(msg.sender, fundReceiver, _amount), "You must Deposit some tokens");
        uint256 immediateTokens = (tokensToBuy*immediatePercentageReleased)/100;
        uint256 tokenToVest = tokensToBuy - immediateTokens;
        createVestingSchedule(msg.sender, block.timestamp, cliffPeriod, vestDuration, slicePeriod, tokenToVest);
        tokensSold += tokensToBuy;
        grl.transfer(msg.sender, immediateTokens);
        emit PurchasedWithToken(address(this), msg.sender, _amount, tokensToBuy);
    }

    function setVestingDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0,"Duration will be > 0!");
        vestDuration = _newDuration*86400;
    }

    function setCliffeDuration(uint256 _newCliffeDuration) external onlyOwner {
        require(_newCliffeDuration > 0,"Invalid cliff period!");
        cliffPeriod = _newCliffeDuration*86400;
    }

    function setPrice(uint256 _index,uint256 _price) external onlyOwner{
        require(_price>0,"Price will be > 0!");
        daiPricePerPhase[_index] = _price;
    }

    function setUsdtPrice(uint256 _index,uint256 _price) external onlyOwner{
        require(_price>0,"Price will be > 0!");
        usdtPricePerPhase[_index] = _price;
    }
    function setPhaseDuration(uint256 _durationPerPhase) external onlyOwner{
        require(_durationPerPhase > 0,"Phase Duration will be > 0!");
        phaseDuration = _durationPerPhase*86400;
    }

    function setPercentageReleased(uint256 _newPercentage) external onlyOwner{
        require(_newPercentage > 0,"Percenatge will be > 0!");
        immediatePercentageReleased = _newPercentage;
    }

    function ethPriceInUSD() public view returns (uint256) {
        int256 answer = ethToUsdPriceFeed.latestAnswer();
        return uint256(answer * 10000000000);
    }

    function daiPriceInEth() public view returns (uint256) {
        (, int256 answer, , , ) = daiToEthPriceFeed.latestRoundData();
        return uint256(answer);
    }

    function convertDaiToEth(uint256 daiAmount) public view returns (uint256) {
        uint256 daiPrice = daiPriceInEth();
        uint256 daiAmountInEth = (daiPrice * daiAmount) / 1000000000000000000;
        return daiAmountInEth;
    }

    function convertEthToUsd(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = ethPriceInUSD();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function startGCO() external onlyOwner {
        isGCOStarted = true;
        startTime = block.timestamp;
    }

    function grlOfDai(uint256 _amountOfDAI) public view returns (uint256) {
        (uint256 price, ,) = getGrlPrice();
        uint256 tokensCalculated = (_amountOfDAI * 10 ** 9) / price;
        return tokensCalculated;
    }

    function grlOfUsdt (uint256 _amountOfUSDT) internal view returns(uint256) {
        (, ,uint256 price) = getGrlPrice();
         uint256 tokensCalculated = (_amountOfUSDT * 10 ** 9) / price;
        return tokensCalculated;
    }

    function grlOfEth(uint256 _amountOfEth) public view returns (uint256) {
        (, uint256 price,) = getGrlPrice();
        uint256 tokensCalculated = (_amountOfEth * 10 ** 9) / price;
        return tokensCalculated;
    }
    
    function getGrlPrice() public view returns (uint256 grlDaiPrice, uint256 grlEthPrice, uint256 grlUsdtPrice) {
        require(isGCOStarted, "GCO has not started yet");

        uint256 currentTime = block.timestamp;
        uint256 currentPhase = (currentTime - startTime) / phaseDuration;

        if (currentPhase >= daiPricePerPhase.length) {
            currentPhase = daiPricePerPhase.length - 1;
        }

        uint256 currentDaiPrice = daiPricePerPhase[currentPhase];
        uint256 currentUsdtPrice = usdtPricePerPhase[currentPhase];

        grlDaiPrice = currentDaiPrice;
        grlEthPrice = convertDaiToEth(currentDaiPrice);
        grlUsdtPrice = currentUsdtPrice;

        if (currentTime < startTime + phaseDuration * (currentPhase + 1) || tokensSold <= tokensPerPhase * (currentPhase + 1)) {
            return (grlDaiPrice, grlEthPrice, grlUsdtPrice);
        } else {

            if (currentPhase + 1 < daiPricePerPhase.length) {
                currentPhase += 1;

                grlDaiPrice = daiPricePerPhase[currentPhase];
                grlEthPrice = convertDaiToEth(grlDaiPrice);
                grlUsdtPrice = usdtPricePerPhase[currentPhase];
            }
            return (grlDaiPrice, grlEthPrice, grlUsdtPrice);
        }
    }


    function withdrawGrl() external onlyOwner {
        uint256 grlBalance = grl.balanceOf(address(this));
        uint256 tokensToWithdraw = grlBalance - tokensSold;
        require(tokensToWithdraw > 0, "no grl in contract!");
        grl.transfer(admin, tokensToWithdraw);
    }

    function withdrawEth()external onlyOwner{
        require(address(this).balance > 0, "No eth to withdraw!");
        (bool success, ) = fundReceiver.call{value: address(this).balance}("");
        require(success);
    }

}