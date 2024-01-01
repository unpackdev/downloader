// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

contract TokenPreSale is Ownable, ReentrancyGuard {
    struct Presale {
        uint256 price;
        uint256 tokensToSell;
        uint256 inSale;
    }

    struct userTokens {
        uint256 totalQuantity;
        uint256 ethAmountSent;
        uint256 usdcAmountSent;
        uint256 usdtAmountSent;
        uint256 claimedQuantity;
    }

    struct PresaleStatus {
        bool completed;
        bool isSuccess;
    }

    struct funds {
        uint256 ethAmountReceived;
        uint256 usdcAmountReceived;
        uint256 usdtAmountReceived;
    }

    IERC20 public token;
    IERC20 public constant usdc =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant usdt =
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    AggregatorV3Interface public constant priceFeedUsdcUsd =
        AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
    AggregatorV3Interface public constant priceFeedUsdtUsd =
        AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
    AggregatorV3Interface public constant priceFeedEthUsd =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    bool public paused;
    Presale public presale;
    PresaleStatus public presaleStatus;
    uint256 public tokensReservedForUsers;
    mapping(address => userTokens) public user;
    funds private fundsReceived;

    event PresaleCreated(uint256 _startTime);

    event PresaleUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    event TokensBought(
        address indexed user,
        uint256 tokensBought,
        uint256 amountPaid,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event PresalePaused(uint256 timestamp);
    event PresaleUnpaused(uint256 timestamp);

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(bytes32 => mapping(address => bool)) public roles;

    constructor() Ownable() {
        grantAdminRole(msg.sender);
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function grantAdminRole(address _admin) public onlyOwner {
        require(!roles[ADMIN_ROLE][_admin], "Already owner");
        roles[ADMIN_ROLE][_admin] = true;
    }

    function revokeAdminRole(address _admin) external onlyOwner {
        require(roles[ADMIN_ROLE][_admin], "Not an owner");
        roles[ADMIN_ROLE][_admin] = false;
    }

    function hasAdminRole(address _admin) external view returns (bool) {
        return roles[ADMIN_ROLE][_admin];
    }

    modifier onlyAdmin() {
        require(
            roles[ADMIN_ROLE][msg.sender],
            "Access Denied, only admins allowed"
        );
        _;
    }

    function checkSaleState(uint256 amount) private view {
        require(amount > 0 && amount <= presale.inSale, "Invalid sale amount");
    }

    function pausePresale() external onlyAdmin {
        require(!paused, "Already paused");
        paused = true;
        emit PresalePaused(block.timestamp);
    }

    function unPausePresale() external onlyAdmin {
        require(paused, "Not paused");
        paused = false;
        emit PresaleUnpaused(block.timestamp);
    }

    function fundsReceive() external view onlyAdmin returns (funds memory) {
        return fundsReceived;
    }

    // input tokens in wei
    function createPresale(
        uint256 _price,
        uint256 _tokenAmountToSell
    ) external onlyAdmin {
        require(_price > 0, "Price should be greater than zero");
        require(
            _tokenAmountToSell > 0,
            "Tokens to sell should be greater than zero"
        );

        presale = Presale({
            price: _price,
            tokensToSell: _tokenAmountToSell,
            inSale: _tokenAmountToSell
        });

        emit PresaleCreated(block.timestamp);
    }

    function setGaryPrice(uint256 _newPrice) external onlyAdmin {
        require(_newPrice > 0, "Zero price");
        require(!paused, "Cann't change when paused");

        uint256 prevValue = presale.price;
        presale.price = _newPrice;

        emit PresaleUpdated(
            bytes32("PRICE"),
            prevValue,
            _newPrice,
            block.timestamp
        );
    }

    // input tokens in wei
    function addTokenAmountForSale(
        uint256 _tokenAmountToSale
    ) external onlyAdmin {
        require(!paused, "Cann't change when paused");

        uint256 prevValue = presale.tokensToSell;
        presale.tokensToSell += _tokenAmountToSale;
        presale.inSale += _tokenAmountToSale;
        emit PresaleUpdated(
            bytes32("TokenAmount"),
            prevValue,
            presale.tokensToSell,
            block.timestamp
        );
    }

    function getTokenAmountForEth(
        uint256 _ethAmount
    ) public view returns (uint256 tokenQuantity) {
        uint256 tokenQuantityIn1Eth = (((1e18 / presale.price) *
            1e18 *
            getLatestEthPrice()) / 1e8);
        return (tokenQuantityIn1Eth * _ethAmount) / 1e18;
    }

    function getLatestEthPrice() public view returns (uint256) {
        (
            uint256 roundID,
            int price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeedEthUsd.latestRoundData();

        return uint256(price);
    }

    function buyWithEth() external payable nonReentrant returns (bool) {
        require(!paused, "Presale paused");
        require(!presaleStatus.completed, "presale is no longer active");

        userTokens storage _user = user[msg.sender];
        uint256 tokenQuantityToPurchase = getTokenAmountForEth(msg.value);
        checkSaleState(tokenQuantityToPurchase);

        fundsReceived.ethAmountReceived += msg.value;
        presale.inSale -= tokenQuantityToPurchase;
        tokensReservedForUsers += tokenQuantityToPurchase;

        if (_user.totalQuantity > 0) {
            _user.totalQuantity += tokenQuantityToPurchase;
            _user.ethAmountSent += msg.value;
        } else {
            user[msg.sender] = userTokens({
                totalQuantity: tokenQuantityToPurchase,
                ethAmountSent: msg.value,
                usdcAmountSent: 0,
                usdtAmountSent: 0,
                claimedQuantity: 0
            });
        }

        emit TokensBought(
            msg.sender,
            tokenQuantityToPurchase,
            msg.value,
            block.timestamp
        );
        return true;
    }

    function getTokenAmountForUsdc(
        uint256 usdcToSpent
    ) public view returns (uint256 tokenQuantity) {
        uint256 tokenQuantityIn1Usdc = (((1e18 / presale.price) *
            1e18 *
            getLatestUsdcPrice()) / 1e8);
        return (usdcToSpent * tokenQuantityIn1Usdc) / 1e6;
    }

    function getLatestUsdcPrice() public view returns (uint256) {
        (
            uint256 roundID,
            int price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeedUsdcUsd.latestRoundData();

        return uint256(price);
    }

    // input tokens with wei
    function buyWithUsdc(
        uint256 usdcToSpent
    ) external nonReentrant returns (bool) {
        require(!paused, "Presale paused");
        require(!presaleStatus.completed, "presale is no longer active");

        userTokens storage _user = user[msg.sender];
        uint256 tokenQuantityToPurchase = getTokenAmountForUsdc(usdcToSpent);
        checkSaleState(tokenQuantityToPurchase);
        usdc.transferFrom(msg.sender, address(this), usdcToSpent);

        fundsReceived.usdcAmountReceived += usdcToSpent;
        presale.inSale -= tokenQuantityToPurchase;
        tokensReservedForUsers += tokenQuantityToPurchase;

        if (_user.totalQuantity > 0) {
            _user.totalQuantity += tokenQuantityToPurchase;
            _user.usdcAmountSent += usdcToSpent;
        } else {
            user[msg.sender] = userTokens({
                totalQuantity: tokenQuantityToPurchase,
                ethAmountSent: 0,
                usdcAmountSent: usdcToSpent,
                usdtAmountSent: 0,
                claimedQuantity: 0
            });
        }

        emit TokensBought(
            msg.sender,
            tokenQuantityToPurchase * 1e18,
            usdcToSpent,
            block.timestamp
        );
        return true;
    }

    function getTokenAmountForUsdt(
        uint256 usdtToSpent
    ) public view returns (uint256 tokenQuantity) {
        uint256 tokenQuantityIn1USDT = (((1e18 / presale.price) *
            1e18 *
            getLatestUsdtPrice()) / 1e8);
        return (usdtToSpent * tokenQuantityIn1USDT) / 1e6;
    }

    function getLatestUsdtPrice() public view returns (uint256) {
        (
            uint256 roundID,
            int price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeedUsdtUsd.latestRoundData();

        return uint256(price);
    }

    // input tokens with wei
    function buyWithUsdt(
        uint256 usdtToSpent
    ) external nonReentrant returns (bool) {
        require(!paused, "Presale paused");
        require(!presaleStatus.completed, "presale is no longer active");

        userTokens storage _user = user[msg.sender];
        uint256 tokenQuantityToPurchase = getTokenAmountForUsdt(usdtToSpent);
        checkSaleState(tokenQuantityToPurchase);
        usdt.transferFrom(msg.sender, address(this), usdtToSpent);

        fundsReceived.usdtAmountReceived += usdtToSpent;
        presale.inSale -= tokenQuantityToPurchase;
        tokensReservedForUsers += tokenQuantityToPurchase;

        if (_user.totalQuantity > 0) {
            _user.totalQuantity += tokenQuantityToPurchase;
            _user.usdtAmountSent += usdtToSpent;
        } else {
            user[msg.sender] = userTokens({
                totalQuantity: tokenQuantityToPurchase,
                ethAmountSent: 0,
                usdcAmountSent: 0,
                usdtAmountSent: usdtToSpent,
                claimedQuantity: 0
            });
        }

        emit TokensBought(
            msg.sender,
            tokenQuantityToPurchase * 1e18,
            usdtToSpent,
            block.timestamp
        );
        return true;
    }

    function withdrawFunds() external onlyAdmin nonReentrant {
        if (presaleStatus.completed && !presaleStatus.isSuccess) {
            uint256 ethAmountReceived = fundsReceived.ethAmountReceived;
            uint256 usdcAmountReceived = fundsReceived.usdcAmountReceived;
            uint256 usdtAmountReceived = fundsReceived.usdtAmountReceived;

            uint256 ethBalance = address(this).balance;
            uint256 usdcBalance = usdc.balanceOf(address(this));
            uint256 usdtBalance = usdt.balanceOf(address(this));

            if (ethBalance > ethAmountReceived) {
                payable(msg.sender).transfer(ethBalance - ethAmountReceived);
            }

            if (usdcBalance > usdcAmountReceived) {
                usdc.transfer(msg.sender, usdcBalance - usdcAmountReceived);
            }

            if (usdtBalance > usdtAmountReceived) {
                usdt.transfer(msg.sender, usdtBalance - usdtAmountReceived);
            }
        } else {
            uint256 ethAmount = address(this).balance;
            if (ethAmount > 0) {
                payable(msg.sender).transfer(ethAmount);
            }

            uint256 usdcBalance = usdc.balanceOf(address(this));
            if (usdcBalance > 0) {
                usdc.transfer(msg.sender, usdcBalance);
            }

            uint256 usdtBalance = usdt.balanceOf(address(this));
            if (usdtBalance > 0) {
                usdt.transfer(msg.sender, usdtBalance);
            }
        }
    }

    function withdrawRemainingTokens() external onlyAdmin {
        require(
            presaleStatus.completed,
            "Cann't withdraw untill presale status is not updated"
        );

        uint256 remainingTokens = token.balanceOf(address(this)) -
            tokensReservedForUsers;

        if (remainingTokens > 0) {
            token.transfer(msg.sender, remainingTokens);
        }
    }

    function updatePresaleStatus(
        bool _success
    ) external nonReentrant onlyAdmin {
        require(!presaleStatus.completed, "Can only be called once");
        presaleStatus.completed = true;
        presaleStatus.isSuccess = _success;

        if (_success) {
            require(
                token.balanceOf(address(this)) >= tokensReservedForUsers,
                "Cann't change status unless sufficient tokens are sent"
            );
        } else {
            uint256 ethAmountReceived = fundsReceived.ethAmountReceived;
            uint256 usdcAmountReceived = fundsReceived.usdcAmountReceived;
            uint256 usdtAmountReceived = fundsReceived.usdtAmountReceived;

            uint256 ethBalance = address(this).balance;
            uint256 usdcBalance = usdc.balanceOf(address(this));
            uint256 usdtBalance = usdt.balanceOf(address(this));

            bool areFundsSufficient = ethBalance >= ethAmountReceived &&
                usdcBalance >= usdcAmountReceived &&
                usdtBalance >= usdtAmountReceived;

            require(
                areFundsSufficient,
                "Cann't change status unless funds are sufficient for refund"
            );

            tokensReservedForUsers = 0;
            uint256 remainingTokens = token.balanceOf(address(this));
            token.transfer(msg.sender, remainingTokens);
        }
    }

    function claimableAmount(
        address _userAddress
    ) public view returns (uint256) {
        userTokens memory _userTokens = user[_userAddress];

        uint claimAmount = _userTokens.totalQuantity -
            _userTokens.claimedQuantity;
        require(_userTokens.totalQuantity > 0, "Nothing to claim");
        require(claimAmount > 0, "Already claimed");

        return claimAmount;
    }

    function claimTokens() public nonReentrant returns (bool) {
        require(!paused, "Cann't claim tokens, presale is paused");
        require(presaleStatus.completed, "Presale is not marked completed yet");
        require(
            presaleStatus.isSuccess,
            "Cann't claim tokens, presale is failed"
        );

        userTokens storage _user = user[msg.sender];
        uint claimAmount = _user.totalQuantity - _user.claimedQuantity;
        tokensReservedForUsers -= claimAmount;
        _user.claimedQuantity = claimAmount;

        require(claimAmount > 0, "Already Claimed");

        token.transfer(msg.sender, claimAmount);
        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
        return true;
    }

    function claimRefund() external nonReentrant {
        require(!paused, "Cann't claim Refund, presale is paused");
        require(presaleStatus.completed, "Presale is not marked completed yet");
        require(
            !presaleStatus.isSuccess,
            "Cann't claim Refund, presale is successful"
        );

        userTokens storage _user = user[msg.sender];

        if (_user.ethAmountSent > 0) {
            uint256 ethAmount = _user.ethAmountSent;
            _user.ethAmountSent = 0;
            payable(msg.sender).transfer(ethAmount);
        }

        if (_user.usdcAmountSent > 0) {
            uint256 usdcAmount = _user.usdcAmountSent;
            _user.usdcAmountSent = 0;
            usdc.transfer(msg.sender, usdcAmount);
        }

        if (_user.usdtAmountSent > 0) {
            uint256 usdtAmount = _user.usdtAmountSent;
            _user.usdtAmountSent = 0;
            usdt.transfer(msg.sender, usdtAmount);
        }
    }
}
