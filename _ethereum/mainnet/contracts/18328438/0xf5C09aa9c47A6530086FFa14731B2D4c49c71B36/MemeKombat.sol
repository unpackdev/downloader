// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract MemeKombat is Ownable, Pausable {
    IERC20 public token;
    IERC20 public usdt;

    uint256 public USDTRaised;
    uint256 public MaxUSDTRaised;
    uint256 public maxTokensToBuy;
    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;

    uint256 public PresaleRate;

    Aggregator public aggregatorInterface;

    enum TokenType {
        ETH,
        USDT
    }

    mapping(address => uint256) public userDeposits;

    event MaxTokensUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        address indexed purchaseToken,
        uint256 amountPaid,
        uint256 timestamp
    );
    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    constructor() {
        token = IERC20(0x95E1C5a40D5A1B722AdE86832F268993eb43c66d);
        usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        aggregatorInterface = Aggregator(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        maxTokensToBuy = 500000 ether;
        startTime = block.timestamp;
        endTime = block.timestamp + 5 days;
        PresaleRate = 1176;
        MaxUSDTRaised = 1000000 * 1e6;
    }

    function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
        require(_maxTokensToBuy > 0, "Zero max tokens to buy value");
        maxTokensToBuy = _maxTokensToBuy;
        emit MaxTokensUpdated(maxTokensToBuy, _maxTokensToBuy, block.timestamp);
    }

    function changeSaleStartTime(uint256 _startTime) external onlyOwner {
        require(block.timestamp <= _startTime, "Sale time in past");
        startTime = _startTime;
    }

    function changeSaleEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > startTime, "Invalid endTime");
        require(_endTime >= block.timestamp, "End time past");
        endTime = _endTime;
    }

    function updatePresaleRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Inalid presale rate");
        PresaleRate = _newRate;
    }

    function pause() external onlyOwner returns (bool success) {
        _pause();
        return true;
    }

    function unpause() external onlyOwner returns (bool success) {
        _unpause();
        return true;
    }

    function setMaxUSDTRaised(uint256 _newUsdtRaised) external onlyOwner {
        require(_newUsdtRaised > 0, "Wrong value");
        require(
            _newUsdtRaised > USDTRaised,
            "Maximum USDT must be greater than the USDT Raised"
        );
        MaxUSDTRaised = _newUsdtRaised;
    }

    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "cicca Payment failed");
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        require(amount > 0, "Invalid enter amount");
        sendValue(owner(), amount);
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
        require(startTime <= block.timestamp, "ICO not start");
        require(endTime >= block.timestamp, "ICO end");
        require(amount > 0, "Invalid amount");
        _;
    }

    function buyWithUSDT(
        uint256 amount
    ) external checkSaleState(amount) whenNotPaused {
        uint256 numOfTokens = calculateToken(amount, TokenType.USDT);
        require(numOfTokens <= maxTokensToBuy, "max tokens buy");
        uint256 ourAllowance = usdt.allowance(_msgSender(), address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        usdt.transferFrom(_msgSender(), address(this), amount);
        userDeposits[_msgSender()] = numOfTokens;
        USDTRaised += amount;
        totalTokensSold += numOfTokens;
        emit TokensBought(
            _msgSender(),
            numOfTokens,
            address(usdt),
            amount,
            block.timestamp
        );
    }

    function buyWithETH()
        external
        payable
        checkSaleState(msg.value)
        whenNotPaused
    {
        uint256 ethToUsdt = (getLatestPrice() * msg.value) / 1e8;
        uint256 numOfTokens = calculateToken(ethToUsdt, TokenType.ETH);
        require(numOfTokens <= maxTokensToBuy, "max tokens buy");
        userDeposits[_msgSender()] = numOfTokens;
        totalTokensSold += numOfTokens;
        emit TokensBought(
            _msgSender(),
            numOfTokens,
            address(0),
            ethToUsdt,
            block.timestamp
        );
    }

    function calculateToken(
        uint256 _usdtAmount,
        TokenType _type
    ) private view returns (uint256) {
        uint256 numOfTokens;
        if (_type == TokenType.USDT) {
            numOfTokens = _usdtAmount * PresaleRate * 1e12;
        } else {
            numOfTokens = _usdtAmount * PresaleRate;
        }
        return (numOfTokens / 1000);
    }

    function ethBuyHelper(
        uint256 amount
    ) external view returns (uint256 numOfTokens) {
        uint256 ethToUsdt = (getLatestPrice() * amount) / 1e8;
        numOfTokens = calculateToken(ethToUsdt, TokenType.ETH);
    }

    function usdtBuyHelper(
        uint256 amount
    ) external view returns (uint256 numOfTokens) {
        numOfTokens = calculateToken(amount, TokenType.USDT);
    }

    function claim() external whenNotPaused returns (bool) {
        require(endTime < block.timestamp, "Claim time has not started");
        require(userDeposits[_msgSender()] > 0, "No deposit");
        uint256 amount = userDeposits[_msgSender()];
        bool success = token.transfer(_msgSender(), amount);
        require(success, "Failed to send tokens");
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        userDeposits[_msgSender()] = 0;
        delete userDeposits[_msgSender()];
        return success;
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        return uint256(price);
    }

    function getTokenBalance() public view returns (uint256 tokenBalance) {
        tokenBalance = token.balanceOf(address(this));
    }

    function getUsdtBalance() public view returns (uint256 usdtBalance) {
        usdtBalance = usdt.balanceOf(address(this));
    }

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}