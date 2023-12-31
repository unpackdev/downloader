//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.10;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

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

contract Presale {
    IERC20 public Token;
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    AggregatorV3Interface public priceFeeD;

    address payable public owner;

    uint256 public tokenPerUsd = 100 ether;
    uint256 public totalUsers;
    uint256 public soldToken;
    uint256 public totalSupply = 400_000_000 ether;
    uint256 public minimumBuyInUsdt = 1 * 1e6;
    uint256 public minimumBuyInEth = 0.00054 ether;
    uint256 public maximumBuy = 750000 ether;
    uint256 public amountRaised;
    uint256 public amountRaisedETHUSDT;
    uint256 public amountRaisedUSDT;
    address payable public fundReceiver;
    uint256 public presalePhase;

    uint256 public constant divider = 100;

    bool public presaleStatus;
    bool public enableClaim;

    struct user {
        uint256 native_balance;
        uint256 eth_usdt_balance;
        uint256 usdt_balance;
        uint256 token_balance;
        uint256 token_bonus;
        uint256 claimed_token;
    }
    struct bonus {
        uint256 token_bonus;
        uint256 claimed_bonus;
        uint256 level;
    }
    mapping(address => bonus) public Bonus;
    mapping(address => user) public users;
    mapping(address => uint256) public wallets;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event ClaimToken(address indexed _user, uint256 indexed _amount);
    event ClaimBonus(address indexed _user, uint256 indexed _amount);
    event UpdatePrice(uint256 _oldPrice, uint256 _newPrice);
    event UpdateBonusValue(uint256 _oldValue, uint256 _newValue);
    event UpdateRefPercent(uint256 _oldPercent, uint256 _newPercent);
    event UpdateMinPurchase(
        uint256 _oldMinNative,
        uint256 _newMinNative,
        uint256 _oldMinUsdt,
        uint256 _newMinUsdt
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address _feeReceiver) {
        fundReceiver = payable(_feeReceiver);
        Token = IERC20(0xfD9DEE445030Af02669365b39Acb2136abF29B56);
        owner = payable(msg.sender);
        priceFeeD = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        presaleStatus = true;
    }

    receive() external payable {}

    // to get real time price of Eth
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeeD.latestRoundData();
        return uint256(price);
    }

    // to buy token during preSale time with Eth => for web3 use

    function buyToken() public payable {
        require(presaleStatus, "Presale : Presale is finished");
        require(
            msg.value >= minimumBuyInEth,
            "amount should be greater than minimum buy"
        );

        require(soldToken <= totalSupply, "All Sold");

        uint256 numberOfTokens;
        numberOfTokens = nativeToToken(msg.value);
        soldToken = soldToken + (numberOfTokens);
        amountRaised = amountRaised + (msg.value);
        uint256 equivalentUSDT = (msg.value * (getLatestPrice())) / (1 ether);
        amountRaisedETHUSDT += equivalentUSDT;

        users[msg.sender].eth_usdt_balance += equivalentUSDT;
        users[msg.sender].native_balance += msg.value;
        users[msg.sender].token_balance += numberOfTokens;
        require(
            users[msg.sender].token_balance <= maximumBuy,
            "max buy limit reached"
        );
        uint256 currentUsrTokens = users[msg.sender].token_balance +
            numberOfTokens;
        addUserBonus(currentUsrTokens, msg.sender);
    }

    // to buy token during preSale time with USDT => for web3 use
    function buyTokenUSDT(uint256 amount) public {
        require(presaleStatus == true, "Presale : Presale is finished");
        require(
            amount >= minimumBuyInUsdt,
            "amount should be greater than minimum buy"
        );
        require(soldToken <= totalSupply, "All Sold");

        USDT.transferFrom(msg.sender, fundReceiver, amount);

        uint256 numberOfTokens;
        numberOfTokens = usdtToToken(amount);

        soldToken = soldToken + (numberOfTokens);
        amountRaisedUSDT = amountRaisedUSDT + (amount);

        users[msg.sender].usdt_balance += amount;

        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens);
        require(
            users[msg.sender].token_balance <= maximumBuy,
            "max buy limit reached"
        );

        uint256 currentUsrTokens = users[msg.sender].token_balance +
            numberOfTokens;
        addUserBonus(currentUsrTokens, msg.sender);
    }

    function addUserBonus(uint256 currentUsrTokens, address _user) internal {
        if (
            currentUsrTokens >= 100_000 ether &&
            currentUsrTokens <= 300_000 ether
        ) {
            Bonus[_user].token_bonus = (currentUsrTokens * 3) / 100;
            Bonus[_user].level = 1;
        } else if (
            currentUsrTokens > 300_000 ether &&
            currentUsrTokens <= 750_000 ether
        ) {
            Bonus[_user].token_bonus = (currentUsrTokens * 5) / 100;
            Bonus[_user].level = 2;
        } else if (
            currentUsrTokens > 750_000 ether &&
            currentUsrTokens <= 2_500_000 ether
        ) {
            Bonus[_user].token_bonus = (currentUsrTokens * 8) / 100;
            Bonus[_user].level = 4;
        } else if (currentUsrTokens > 2_500_000 ether) {
            Bonus[_user].token_bonus = (currentUsrTokens * 12) / 100;
            Bonus[_user].level = 5;
        }
    }

    // Claim bought tokens
    function claimTokens() external {
        require(enableClaim == true, "Presale : Claim not active yet");
        require(users[msg.sender].token_balance != 0, "Presale: 0 to claim");

        user storage _usr = users[msg.sender];

        Token.transfer(msg.sender, _usr.token_balance);
        _usr.claimed_token += _usr.token_balance;
        _usr.token_balance -= _usr.token_balance;

        emit ClaimToken(msg.sender, _usr.token_balance);
    }

    // Claim bonus tokens
    function claimBonus() external {
        require(enableClaim == true, "Presale : Claim not active yet");
        require(Bonus[msg.sender].token_bonus != 0, "Presale: 0 to claim");

        bonus storage _usr = Bonus[msg.sender];

        Token.transfer(msg.sender, _usr.token_bonus);
        _usr.claimed_bonus += _usr.token_bonus;
        _usr.token_bonus -= _usr.token_bonus;

        emit ClaimBonus(msg.sender, _usr.token_bonus);
    }

    function EnableClaim(bool _state) external onlyOwner {
        enableClaim = _state;
    }

    function stopPresale(bool _off) external onlyOwner {
        presaleStatus = _off;
    }

    function whitelistUsers(
        address[] memory _usrs,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(
            _usrs.length == _amounts.length,
            "Presale: Invalid array length"
        );
        uint256 totalSoldTokens;
        for (uint256 i = 0; i < _usrs.length; i++) {
            users[_usrs[i]].token_balance += _amounts[i];
            addUserBonus(users[_usrs[i]].token_balance, _usrs[i]);
            totalSoldTokens += _amounts[i];
        }
        soldToken += totalSoldTokens;
    }

    function setMinimumBuyInUsdt(uint256 _minimumBuyInUsdt) external onlyOwner {
        minimumBuyInUsdt = _minimumBuyInUsdt;
    }

    function setMinimumBuyInEth(uint256 _minimumBuyInEth) external onlyOwner {
        minimumBuyInEth = _minimumBuyInEth;
    }

    function setMaxTokenBuy(uint256 _maxokens) external onlyOwner {
        maximumBuy = _maxokens;
    }

    // to check number of token for given Eth
    function nativeToToken(uint256 _amount) public view returns (uint256) {
        uint256 EthToUsd = (_amount * (getLatestPrice())) / (1 ether);
        uint256 numberOfTokens = (EthToUsd * (tokenPerUsd)) / (1e8);
        return numberOfTokens;
    }

    // to check number of token for given usdt
    function usdtToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * (tokenPerUsd)) / (1e6);
        return numberOfTokens;
    }

    // to change Price of the token
    function changePrice(
        uint256 _price,
        uint256 _presalePhase
    ) external onlyOwner {
        uint256 oldPrice = tokenPerUsd;
        tokenPerUsd = _price;
        presalePhase = _presalePhase;

        emit UpdatePrice(oldPrice, _price);
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        address _oldOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        Token = IERC20(_token);
    }

    //change USDT
    function changeUSDT(address _USDT) external onlyOwner {
        USDT = IERC20(_USDT);
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner {
        fundReceiver.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
        token.transfer(msg.sender, _value);
    }
}