// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Router02 {
    // add liquidityeth
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Presale is Ownable {
    IUniswapV2Router02 public uniswapV2Router;

    mapping(address => uint256) public tokenClaimed;
    mapping(address => uint256) public rewardsGiven;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public userEthDepositAmount;
    mapping(uint256 => uint256) public roundEthRaised;

    address[] public depositers;
    address public projectToken;

    uint256 public ethDepositLimit; // eth limit per person
    uint256 public ethDepositPrice; // token price per eth (decimals included)
    uint256 public minEthDeposit; // min eth deposit per person
    uint256 public totalReferralCount = 0;
    uint256 public referralPercentage = 10;
    uint256 public ethRaiseLimit = 0; // eth that can be raised per round

    uint256 public presaleRound = 0;
    uint256 public totalProjectTokenSold = 0;

    bool public isPresaleActive = false;
    bool public isPresalePublic = false;

    bool lock_ = false;

    modifier Lock() {
        require(!lock_, "Process is locked");
        lock_ = true;
        _;
        lock_ = false;
    }

    event SetEthDepositPrice(uint256 _price);
    event SetPresaleStartTime(uint256 _startTime);
    event SetPresaleEndTime(uint256 _endTime);
    event SetEthDepositLimit(uint256 _limit);

    constructor() {
        ethDepositLimit = 10 ether;
        minEthDeposit = 0.01 ether;
        projectToken = 0xB879E304a5709694bB1814403EDCdB1c88a446CF;
        transferOwnership(0x23c7D54411b1e30fAc755479A7A214dD0d084629);
        address currentRouter;

        if (block.chainid == 97) {
            currentRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // PCS Testnet
        } else if (block.chainid == 1 || block.chainid == 4) {
            currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Mainnet
        } else if (block.chainid == 56) {
            currentRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC
        } else {
            revert();
        }

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(currentRouter);
        uniswapV2Router = _uniswapV2Router;
    }

    // receive eth and auto deposit in presale
    receive() external payable {
        depositEth(0x0000000000000000000000000000000000000000);
    }

    // deposit eth using this function
    function depositEth(address _referral) public payable Lock {
        require(isPresaleActive, "Presale is not active");
        require(
            roundEthRaised[presaleRound] + msg.value <= ethRaiseLimit,
            "Hardcap reached"
        );
        require(
            isPresalePublic || isWhitelisted[msg.sender],
            "You are not whitelisted"
        );
        require(!isBlacklisted[msg.sender], "You are blacklisted");
        require(ethDepositPrice > 0, "Eth deposit price not set");

        require(msg.value >= minEthDeposit, "Invalid amount");
        require(
            userEthDepositAmount[msg.sender] + msg.value <= ethDepositLimit,
            "Deposit limit exceeded"
        );

        // implement refferal here
        address zero = 0x0000000000000000000000000000000000000000;
        uint256 _referralAmount;

        if (_referral != zero) {
            _referralAmount = (msg.value * referralPercentage) / 100;
            payable(_referral).transfer(_referralAmount);
            rewardsGiven[_referral] += _referralAmount;
            totalReferralCount += 1;
        }

        if (tokenClaimed[msg.sender] == 0) depositers.push(msg.sender);
        payable(owner()).transfer(msg.value - _referralAmount);
        IERC20(projectToken).transfer(
            msg.sender,
            (msg.value * ethDepositPrice) / (10 ** 18)
        );

        userEthDepositAmount[msg.sender] += msg.value;
        roundEthRaised[presaleRound] += msg.value;
        tokenClaimed[msg.sender] += (msg.value * ethDepositPrice) / (10 ** 18);
        totalProjectTokenSold += (msg.value * ethDepositPrice) / (10 ** 18);
    }

    // read only functions

    // get all depositers and their claimed amount
    function getDepositors()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory _depositers = new address[](depositers.length);
        uint256[] memory _claimed = new uint256[](depositers.length);

        for (uint256 i = 0; i < depositers.length; i++) {
            _depositers[i] = depositers[i];
            _claimed[i] = tokenClaimed[depositers[i]];
        }

        return (_depositers, _claimed);
    }

    // read only functions here--------------------------------------------

    // total claimed amount of all holders
    function totalClaimedAmount() public view returns (uint256) {
        uint256 _claimed = 0;
        for (uint256 i = 0; i < depositers.length; i++) {
            _claimed += tokenClaimed[depositers[i]];
        }
        return _claimed;
    }

    // Only owner functions here---------------------------------------------

    function nextRound() public onlyOwner {
        // presaleTokenReleased (1 = 0.01%)
        presaleRound += 1;
        uint mult = 1e5 * 10 ** IERC20(projectToken).decimals(); // multiplier * decimals

        if (presaleRound == 1) {
            isPresaleActive = true;
            isPresalePublic = true;
            ethRaiseLimit = 25 ether;
            ethDepositPrice = 100 * mult;
        } else if (presaleRound == 2) {
            ethRaiseLimit = 50 ether;
            ethDepositPrice = 75 * mult;
        } else if (presaleRound == 3) {
            ethRaiseLimit = 100 ether;
            ethDepositPrice = 50 * mult;
        } else if (presaleRound == 4) {
            ethRaiseLimit = 250 ether;
            ethDepositPrice = 25 * mult;
        } else if (presaleRound == 5) {
            ethRaiseLimit = 500 ether;
            ethDepositPrice = 15 * mult;
        } else {
            isPresaleActive = false;
        }
    }

    // override tokenClaimable
    function overrideTokenClaimable(
        address _user,
        uint256 _amount
    ) public onlyOwner {
        tokenClaimed[_user] = _amount;
    }

    // set presale status
    function setReferralPercentage(uint _percentage) public onlyOwner {
        referralPercentage = _percentage;
    }

    // set presale status
    function setPresaleStatus(bool _status) public onlyOwner {
        isPresaleActive = _status;
    }

    // set presale public
    function setPresalePublic(bool _status) public onlyOwner {
        isPresalePublic = _status;
    }

    // set presale token deposit limit
    function setMinEthDeposit(uint256 _price) public onlyOwner {
        minEthDeposit = _price;
    }

    // set presale round
    function setPresaleRound(uint256 _round) public onlyOwner {
        presaleRound = _round;
    }

    // set eth raise limit
    function setEthRaiseLimit(uint256 _newLimit) public onlyOwner {
        ethRaiseLimit = _newLimit;
    }

    // whitelist user
    function whitelistUser(address _user) public onlyOwner {
        isWhitelisted[_user] = true;
    }

    // blacklist user
    function blacklistUser(address _user, bool _flag) public onlyOwner {
        isBlacklisted[_user] = _flag;
    }

    // whitelist users
    function whitelistUsers(
        address[] memory _users,
        bool _flag
    ) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isWhitelisted[_users[i]] = _flag;
        }
    }

    // set presale token
    function setProjectToken(address _token) public onlyOwner {
        projectToken = _token;
    }

    // blacklist users
    function blacklistUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isBlacklisted[_users[i]] = true;
        }
    }

    // set eth deposit limit
    function setEthDepositLimit(uint256 _limit) public onlyOwner {
        ethDepositLimit = _limit;
        emit SetEthDepositLimit(_limit);
    }

    // set eth deposit price
    function setEthDepositPrice(uint256 _price) public onlyOwner {
        ethDepositPrice = _price;
        emit SetEthDepositPrice(_price);
    }

    // this function is to withdraw BNB
    function withdrawEth(uint256 _amount) external onlyOwner returns (bool) {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        return success;
    }

    // this function is to withdraw tokens
    function withdrawBEP20(
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        IERC20 token = IERC20(_tokenAddress);
        bool success = token.transfer(msg.sender, _amount);
        return success;
    }
}