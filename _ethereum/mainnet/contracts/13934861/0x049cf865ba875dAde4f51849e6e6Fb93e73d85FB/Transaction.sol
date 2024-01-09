// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";
import "./VRFConsumerBase.sol";
import "./SafeERC20.sol";

contract BetVault is VRFConsumerBase {
    using SafeERC20 for IERC20;

    struct Deposit {
        uint256 id;
        uint256 amount;
        uint8 paymentType; // 1: eth, 2: btc, 3: usdt
        uint256 timestamp;
    }

    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal btcPriceFeed;
    
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 internal totalETH;
    uint256 internal totalUSDT;
    uint256 internal totalBTC;
    uint256 internal totalUSDAmount;

    uint256 public winnerId;
    address public gov;

    mapping(address => Deposit) public users;
    mapping(uint256 => address) public userAddresses;

    uint256 public cntUsers;

    bool public countDownStart = false;
    uint256 public countDownStartTimestamp;

    /**
     * Network: Mainnet
     * BTC Address: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
     * USDT Address: 0xdAC17F958D2ee523a2206206994597C13D831ec7
     */
    /**
     * Network: Kovan
     * BTC Address: 0xA0A5aD2296b38Bd3e3Eb59AAEAF1589E8d9a29A9
     * USDT Address: 0xf3e0d7bF58c5d455D31ef1c2d5375904dF525105
     */
    IERC20 public BTCToken = IERC20(0xA0A5aD2296b38Bd3e3Eb59AAEAF1589E8d9a29A9);
    IERC20 public USDTToken = IERC20(0xf3e0d7bF58c5d455D31ef1c2d5375904dF525105);

    /** https://docs.chain.link/docs/vrf-contracts */
    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     * Aggregator: BTC/USD
     * Address: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
     * LINK Token Address: 0x514910771AF9Ca656af840dff83E8264EcF986CA
     * VRF Coordinator: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * KeyHash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     * Fee: 2 LINK
     */
    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     * Aggregator: BTC/USD
     * Address: 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e
     * LINK Token Address: 0xa36085F69e2889c224210F603D836748e7dC0088
     * VRF Coordinator: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * KeyHash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     * Fee: 0.1 LINK
     */
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        gov = 0xfFd303d36b7C1beE28a8AD74ee8B21b675519111;
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)

        ethPriceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        btcPriceFeed = AggregatorV3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e);
    }

    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    function setGovernance(address _gov) public onlyGov {
        gov = _gov;
    }

    /**
     * Returns the latest ETH price
     */
    function getETHLatestPrice() public view returns (int) {
        (
            , 
            int price,,
            uint timeStamp,
        ) = ethPriceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    /**
     * Returns the latest BTC price
     */
    function getBTCLatestPrice() public view returns (int) {
        (
            , 
            int price,,
            uint timeStamp,
        ) = btcPriceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber() public onlyGov returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(cntUsers > 0);
        require(countDownStart, "countDown!");
        require(block.timestamp > countDownStartTimestamp + 604800, "countdown isn't finished yet");

        return requestRandomness(keyHash, fee);
    }

    function getWinnerAddress() public view returns (address) {
        return userAddresses[winnerId];
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {  
        winnerId = (randomness % cntUsers) + 1;
    }

    function getTotalUSDAmount() internal {
        int _ethPrice = getETHLatestPrice();
        int _btcPrice = getBTCLatestPrice();
        
        totalUSDAmount = uint256(_ethPrice) * totalETH / 10**26 + uint256(_btcPrice) * totalBTC / 10**16 + totalUSDT / 10**6;
    }

    function depositETH() external payable {
        require(users[msg.sender].amount == 0, "!already bet");
        int _price = getETHLatestPrice();
        uint256 _minETHAmount = uint256(10**27 / _price);
        require(msg.value > _minETHAmount, "min amount is $10");

        Deposit memory _userInfo;
        cntUsers = cntUsers + 1;
        _userInfo = Deposit(cntUsers, msg.value, 1, block.timestamp);
        totalETH = totalETH + msg.value;
        users[msg.sender] = _userInfo;
        userAddresses[cntUsers] = msg.sender;

        if (!countDownStart) {
            getTotalUSDAmount();

            if (totalUSDAmount >= 10**6) {
                countDownStart = true;
                countDownStartTimestamp = block.timestamp;
            }
        }
    }

    function depositBTC(uint256 amount) external {
        require(users[msg.sender].amount == 0, "!already bet");
        int _price = getBTCLatestPrice();
        uint256 _minBTCAmount = uint256(10**17 / _price);
        require(amount > _minBTCAmount, "min amount is $10");

        BTCToken.safeTransferFrom(msg.sender, address(this), amount);

        Deposit memory _userInfo;
        cntUsers = cntUsers + 1;
        _userInfo = Deposit(cntUsers, amount, 2, block.timestamp);
        totalBTC = totalBTC + amount;
        users[msg.sender] = _userInfo;
        userAddresses[cntUsers] = msg.sender;

        if (!countDownStart) {
            getTotalUSDAmount();

            if (totalUSDAmount >= 10**6) {
                countDownStart = true;
                countDownStartTimestamp = block.timestamp;
            }
        }
    }

    function depositUSDT(uint256 amount) external {
        require(users[msg.sender].amount == 0, "!already bet");
        require(amount > 10 * 10**6, "min amount is $10");

        USDTToken.safeTransferFrom(msg.sender, address(this), amount);

        Deposit memory _userInfo;
        cntUsers = cntUsers + 1;
        _userInfo = Deposit(cntUsers, amount, 3, block.timestamp);
        totalUSDT = totalUSDT + amount;
        users[msg.sender] = _userInfo;
        userAddresses[cntUsers] = msg.sender;

        if (!countDownStart) {
            getTotalUSDAmount();

            if (totalUSDAmount >= 10**6) {
                countDownStart = true;
                countDownStartTimestamp = block.timestamp;
            }
        }
    }
    
    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
    function withdraw() external onlyGov {
        require(countDownStart, "countDown!");
        require(block.timestamp > countDownStartTimestamp + 604800, "countdown isn't finished yet");
        require(winnerId > 0, "!winner doesn't selected");

        uint256 _btcBalance = BTCToken.balanceOf(address(this));
        uint256 _usdtBalance = USDTToken.balanceOf(address(this));
        uint256 _linkBalance = LINK.balanceOf(address(this));
        uint256 _ethBalance = address(this).balance;
        
        if (_btcBalance > 0) {
            BTCToken.safeTransfer(msg.sender, _btcBalance);
            totalBTC = 0;
        }

        if (_usdtBalance > 0) {
            USDTToken.safeTransfer(msg.sender, _usdtBalance);
            totalUSDT = 0;
        }

        if (_ethBalance > 0) {
            payable(msg.sender).transfer(_ethBalance);
            totalETH = 0;
        }

        if (_linkBalance > 0) {
            LINK.transfer(msg.sender, _linkBalance);
        }
    }
}