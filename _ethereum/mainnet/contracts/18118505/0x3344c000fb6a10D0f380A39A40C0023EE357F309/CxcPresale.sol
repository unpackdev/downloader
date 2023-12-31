// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface Aggregator {
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
}

contract CEXMPresale is Initializable, OwnableUpgradeable, PausableUpgradeable {
    IERC20 public token;
    IERC20 public usdt;

    uint256 public maxTokensToBuy;
    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public quarterTime;

    uint256 public currentStep;
    uint256 public referralPercentage;
    uint256 public returnPercentage;
    uint256 public totalReferralAmount;
    uint256 public withdrawReferralAmount;

    Aggregator public aggregatorInterface;

    event MaxTokensUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
    event WithdrawReferralRewards(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    function initialize(
        address _token,
        address _usdt,
        address _aggregator
    ) public initializer {
        __Ownable_init();
        token = IERC20(_token);
        usdt = IERC20(_usdt);
        aggregatorInterface = Aggregator(_aggregator);
        maxTokensToBuy = 100000 ether;
        startTime = block.timestamp;
        endTime = 1696132740;
        referralPercentage = 1000;
        returnPercentage = 1000;
        quarterTime = 91.31 days;
        setRounds();
    }

    struct round {
        uint256 amount;
        uint256 rate;
        uint256 soldToken;
    }

    struct user {
        uint256 amount;
        uint256 remaining;
        uint256 buyTime;
        uint256 checkTime;
        uint256 quarter;
    }
    mapping(address => user[]) public deposits;
    mapping(address => uint256) private _referralRewards;
    mapping(address => bool) public checkReferral;

    round[] public rounds;

    function setRounds() private {
        rounds.push(round({amount: 25000000 ether, rate: 3030, soldToken: 0}));
        rounds.push(round({amount: 40000000 ether, rate: 2500, soldToken: 0}));
        rounds.push(round({amount: 10000000 ether, rate: 1739, soldToken: 0}));
    }

    function setcurrentStep(uint256 step) public onlyOwner {
        round storage setRound = rounds[step];
        require(step < rounds.length, "Invalid rounds Id");
        require(step != currentStep, "This round is already active");
        uint256 ourAllowance = token.allowance(_msgSender(), address(this));
        require(
            setRound.amount <= ourAllowance,
            "Make sure to add enough allowance"
        );
        token.transferFrom(_msgSender(), address(this), setRound.amount);
        currentStep = step;
    }

    function updateRounds(
        uint256 step,
        uint256 amount,
        uint256 rate
    ) external onlyOwner {
        require(step < rounds.length, "Invalid rounds Id");
        require(amount > 0 || rate > 0, "Invalid value");
        round storage setRound = rounds[step];
        if (amount > 0) setRound.amount = amount;
        if (rate > 0) setRound.rate = rate;
    }

    function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
        require(_maxTokensToBuy > 0, "Zero max tokens to buy value");
        maxTokensToBuy = _maxTokensToBuy;
        emit MaxTokensUpdated(maxTokensToBuy, _maxTokensToBuy, block.timestamp);
    }

    function changeSaleStartTime(uint256 _startTime) external onlyOwner {
        require(block.timestamp < _startTime, "Sale time in past");
        startTime = _startTime;
    }

    function changeSaleEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > startTime, "Invalid endTime");
        endTime = _endTime;
    }

    function changeToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Null address");
        require(isContract(_tokenAddress), "Invalid token contract address");
        token = IERC20(_tokenAddress);
    }

    function changeVestingTime(uint256 _newTime) external onlyOwner {
        require(_newTime > 0, "Invalid time");
        quarterTime = _newTime;
    }

    function updateReferralPercentage(
        uint256 _newPercentage
    ) external onlyOwner {
        referralPercentage = _newPercentage;
    }

    function pause() external onlyOwner returns (bool success) {
        _pause();
        return true;
    }

    function unpause() external onlyOwner returns (bool success) {
        _unpause();
        return true;
    }

    function withdrawETH() public onlyOwner {
        require(address(this).balance > 0, "contract balance is 0");
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(address _token, uint256 amount) external onlyOwner {
        require(isContract(_token), "Invalid contract address");
        require(
            IERC20(_token).balanceOf(address(this)) >= amount,
            "Insufficient tokens"
        );
        IERC20(_token).transfer(_msgSender(), amount);
    }

    function isContract(address _addr) private view returns (bool iscontract) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    modifier checkSaleState(uint256 amount) {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Invalid time for buying"
        );
        require(amount > 0, "Invalid amount");
        _;
    }

    modifier checkClaimTime(uint256 id) {
        user memory users = deposits[_msgSender()][id];
        require(users.remaining > 0, "You have no remaining tokens");
        require(
            block.timestamp > users.checkTime + quarterTime,
            "claim time not reached yet"
        );
        _;
    }

    function returnUsdtAmount(uint256 tokenAmount, uint256 usdtAmount) private {
        if (tokenAmount >= 400 ether) {
            uint256 amount = (usdtAmount * returnPercentage) / 10000;
            if (amount > 0) usdt.transfer(_msgSender(), amount);
        }
    }

    function returnEthAmount(uint256 tokenAmount) private {
        if (tokenAmount >= 400 ether) {
            uint256 amount = (msg.value * returnPercentage) / 10000;
            if (amount > 0) payable(_msgSender()).transfer(amount);
        }
    }

    function removeId(uint256 indexnum) internal {
        for (uint256 i = indexnum; i < deposits[_msgSender()].length - 1; i++) {
            deposits[_msgSender()][i] = deposits[_msgSender()][i + 1];
        }
        deposits[_msgSender()].pop();
    }

    function buyWithUSDT(
        uint256 amount,
        address _referral
    ) external checkSaleState(amount) whenNotPaused {
        uint256 numOfTokens = calculateToken(amount * 1e12);
        require(numOfTokens <= maxTokensToBuy, "max tokens buy");
        uint256 ourAllowance = usdt.allowance(_msgSender(), address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        uint256 instantTokens = (numOfTokens * 20) / 100;
        uint256 remaingTokens = numOfTokens - instantTokens;
        usdt.transferFrom(_msgSender(), address(this), amount);
        token.transfer(_msgSender(), instantTokens);
        deposits[_msgSender()].push(
            user(
                numOfTokens,
                remaingTokens,
                block.timestamp,
                block.timestamp,
                0
            )
        );
        returnUsdtAmount(numOfTokens, amount);
        referralAmount(numOfTokens, _referral);
        rounds[currentStep].soldToken += numOfTokens;
        totalTokensSold += numOfTokens;
    }

    function buyWithETH(
        address _referral
    ) external payable checkSaleState(msg.value) whenNotPaused {
        uint256 ethToUsdt = (getLatestPrice() * msg.value) / 1e8;
        uint256 numOfTokens = calculateToken(ethToUsdt);
        require(numOfTokens <= maxTokensToBuy, "max tokens buy");
        uint256 instantTokens = (numOfTokens * 20) / 100;
        token.transfer(_msgSender(), instantTokens);
        uint256 remaingTokens = numOfTokens - instantTokens;
        deposits[_msgSender()].push(
            user(
                numOfTokens,
                remaingTokens,
                block.timestamp,
                block.timestamp,
                0
            )
        );
        returnEthAmount(numOfTokens);
        referralAmount(numOfTokens, _referral);
        rounds[currentStep].soldToken += numOfTokens;
        totalTokensSold += numOfTokens;
    }

    function claim(uint256 id) external checkClaimTime(id) {
        require(id < deposits[_msgSender()].length, "Not enough records");
        user storage users = deposits[_msgSender()][id];
        uint256 quartersTokens = (users.amount * 10) / 100;
        token.transfer(_msgSender(), quartersTokens);
        users.remaining = users.remaining - quartersTokens;
        users.checkTime = block.timestamp;
        users.quarter += 1;
        if (users.quarter == 8) {
            removeId(id);
        }
    }

    function withdrawReferral() external whenNotPaused {
        uint256 rewards = _referralRewards[_msgSender()];
        require(rewards > 0, "You do not have referral rewards.");
        token.transfer(_msgSender(), rewards);
        withdrawReferralAmount += rewards;
        emit WithdrawReferralRewards(_msgSender(), rewards, block.timestamp);
        _referralRewards[_msgSender()] = 0;
    }

    function referralAmount(uint256 amount, address _referral) private {
        if (
            !checkReferral[_msgSender()] &&
            _referral != address(0) &&
            _referral != _msgSender()
        ) {
            uint256 refferTax = (amount * referralPercentage) / 10000;
            _referralRewards[_referral] += refferTax;
            totalReferralAmount += refferTax;
        }
        checkReferral[_msgSender()] = true;
    }

    function getContractBalacne() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function calculateToken(uint256 _usdtAmount) public view returns (uint256) {
        uint256 numOfTokens = _usdtAmount * rounds[currentStep].rate;
        return (numOfTokens / 100);
    }

    function ethBuyHelper(
        uint256 amount
    ) public view returns (uint256 numOfTokens) {
        uint256 ethToUsdt = (getLatestPrice() * amount) / 1e8;
        numOfTokens = calculateToken(ethToUsdt);
    }

    function usdtBuyHelper(
        uint256 amount
    ) public view returns (uint256 numOfTokens) {
        numOfTokens = calculateToken(amount * 1e12);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        return uint256(price);
    }

    function getCexmBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getUsdtBalance() public view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    function getEthBalance() public view returns (uint256 ETH) {
        ETH = address(this).balance;
    }

    function totalRounds() public view returns (uint256 _rounds) {
        _rounds = rounds.length;
    }

    function referralOf(address account) external view returns (uint256) {
        return _referralRewards[account];
    }

    function userDepositIndex(address _user) public view returns (uint256) {
        return deposits[_user].length;
    }

    receive() external payable {}
}
