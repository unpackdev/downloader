// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";
import "./IERC20.sol";

contract XifraICO2 {

    address immutable private xifraWallet;                      // Xifra wallet
    address immutable private xifraToken;                       // Xifra token address
    address immutable private usdtToken;                        // USDT token address
    address immutable private usdcToken;                        // USDC token address
    uint256 immutable private minTokensBuyAllowed;              // Minimum tokens allowed
    uint256 immutable private maxICOTokens;                     // Max ICO tokens to sell
    uint256 immutable private icoStartDate;                     // ICO start date
    uint256 immutable private icoEndDate;                       // ICO end date
    AggregatorV3Interface immutable internal priceFeed;         // Chainlink price feeder ETH/USD

    uint256 public icoTokensBought;                             // Tokens sold
    uint256 public tokenListingDate;                            // Token listing date
    mapping(address => uint256) private userBoughtTokens;       // Mapping to store all the buys
    mapping(address => uint256) private userWithdrawTokens;     // Mapping to store the user tokens withdraw

    bool private icoFinished;
    uint256 internal constant _MIN_COINS_FOR_VESTING = 23530 * 10 ** 18;    // Min for vesting: 10000$

    event onTokensBought(address _buyer, uint256 _tokens, uint256 _paymentAmount, address _tokenPayment);
    event onWithdrawICOFunds(uint256 _usdtBalance, uint256 _usdcBalance, uint256 _ethbalance);
    event onWithdrawBoughtTokens(address _user, uint256 _maxTokensAllowed);
    event onICOFinished(uint256 _date);

    /**
     * @notice Constructor
     * @param _wallet               --> Xifra master wallet
     * @param _token                --> Xifra token address
     * @param _icoStartDate         --> ICO start date
     * @param _icoEndDate           --> ICO end date
     * @param _usdtToken            --> USDT token address
     * @param _usdcToken            --> USDC token address
     * @param _minTokensBuyAllowed  --> Minimal amount of tokens allowed to buy
     * @param _maxICOTokens         --> Number of tokens selling in this ICO
     * @param _tokenListingDate     --> Token listing date for the ICO vesting
     */
    constructor(address _wallet, address _token, uint256 _icoStartDate, uint256 _icoEndDate, address _usdtToken, address _usdcToken, uint256 _minTokensBuyAllowed, uint256 _maxICOTokens, uint256 _tokenListingDate) {
        xifraWallet = _wallet;
        xifraToken = _token;
        icoStartDate = _icoStartDate;
        icoEndDate = _icoEndDate;
        usdtToken = _usdtToken;
        usdcToken = _usdcToken;
        minTokensBuyAllowed = _minTokensBuyAllowed;
        maxICOTokens = _maxICOTokens;
        tokenListingDate = _tokenListingDate;
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /**
     * @notice Buy function. Used to buy tokens using ETH, USDT or USDC
     * @param _paymentAmount    --> Result of multiply number of tokens to buy per price per token. Must be always multiplied per 1000 to avoid decimals 
     * @param _tokenPayment     --> Address of the payment token (or 0x0 if payment is ETH)
     */
    function buy(uint256 _paymentAmount, address _tokenPayment) external payable {
        require(_isICOActive() == true, "ICONotActive");
               
        uint256 paidTokens = 0;

        if (msg.value == 0) {
            // Stable coin payment
            require(_paymentAmount > 0, "BadPayment");
            require(_tokenPayment == usdtToken || _tokenPayment == usdcToken, "TokenNotSupported");
            require(IERC20(_tokenPayment).transferFrom(msg.sender, address(this), _paymentAmount));
            paidTokens = _paymentAmount * 1000 / 425;   // 0.425$ per token in the ICO
        } else {
            // ETH Payment
            uint256 usdETH = _getUSDETHPrice();
            uint256 paidUSD = msg.value * usdETH / 10**18;
            paidTokens = paidUSD * 1000 / 425;   // 0.425$ per token in the ICO
        }

        require((paidTokens + 1*10**18) >= minTokensBuyAllowed, "BadTokensQuantity");    // One extra token as threshold rounding decimals
        require(maxICOTokens - icoTokensBought >= paidTokens, "NoEnoughTokensInICO");
        userBoughtTokens[msg.sender] += paidTokens;
        icoTokensBought += paidTokens;
        if (maxICOTokens - icoTokensBought < minTokensBuyAllowed) {
            // We finish the ICO
            icoFinished = true;
            emit onICOFinished(block.timestamp);
        }

        emit onTokensBought(msg.sender, paidTokens, _paymentAmount, _tokenPayment);
    }

    /**
     * @notice Withdraw user tokens when the vesting rules allow it
     */
    function withdrawBoughtTokens() external {
        require(_isICOActive() == false, "ICONotActive");
        require(userBoughtTokens[msg.sender] > 0, "NoBalance");
        require(block.timestamp >= tokenListingDate, "TokenNoListedYet");

        uint256 boughtBalance = userBoughtTokens[msg.sender];
        uint256 maxTokensAllowed = 0;
        if ((block.timestamp >= tokenListingDate) && (block.timestamp < tokenListingDate + 90 days)) {
            if (boughtBalance <= _MIN_COINS_FOR_VESTING) {
                maxTokensAllowed = boughtBalance - userWithdrawTokens[msg.sender];
            } else {
                uint maxTokens = boughtBalance * 25 / 100;
                if (userWithdrawTokens[msg.sender] < maxTokens) {
                    maxTokensAllowed = maxTokens;
                }
            }
        } else if ((block.timestamp >= tokenListingDate + 90 days) && (block.timestamp < tokenListingDate + 180 days)) {
            uint256 maxTokens = boughtBalance * 50 / 100;
            if (userWithdrawTokens[msg.sender] < maxTokens) {
                maxTokensAllowed = maxTokens - userWithdrawTokens[msg.sender];
            }
        } else if ((block.timestamp >= tokenListingDate + 180 days) && (block.timestamp < tokenListingDate + 270 days)) {
            uint256 maxTokens = boughtBalance * 75 / 100;
            if (userWithdrawTokens[msg.sender] < maxTokens) {
                maxTokensAllowed = maxTokens - userWithdrawTokens[msg.sender];
            }
        } else {
            uint256 maxTokens = boughtBalance;
            if (userWithdrawTokens[msg.sender] < maxTokens) {
                maxTokensAllowed = maxTokens - userWithdrawTokens[msg.sender];
            }
        }

        require(maxTokensAllowed > 0, "NoTokensToWithdraw");

        userWithdrawTokens[msg.sender] += maxTokensAllowed;
        require(IERC20(xifraToken).transfer(msg.sender, maxTokensAllowed));

        emit onWithdrawBoughtTokens(msg.sender, maxTokensAllowed);
    }

    /**
     * @notice Returns the crypto numbers and balance in the ICO contract
     */
    function withdrawICOFunds() external {
        require(_isICOActive() == false, "ICOStillActive");
        
        uint256 usdtBalance = IERC20(usdtToken).balanceOf(address(this));
        require(IERC20(usdtToken).transfer(xifraWallet, usdtBalance));

        uint256 usdcBalance = IERC20(usdcToken).balanceOf(address(this));
        require(IERC20(usdcToken).transfer(xifraWallet, usdcBalance));

        uint256 ethbalance = address(this).balance;
        payable(xifraWallet).transfer(ethbalance);

        emit onWithdrawICOFunds(usdtBalance, usdcBalance, ethbalance);
    }

    /**
     * @notice Withdraw the unsold Xifra tokens to the Xifra wallet when the ICO is finished
     */
    function withdrawICOTokens() external {
        require(_isICOActive() == false, "ICONotActive");
        require(msg.sender == xifraWallet, "OnlyXifra");

        uint256 balance = maxICOTokens - icoTokensBought;
        require(IERC20(xifraToken).transfer(xifraWallet, balance));
    }

    /**
     * @notice OnlyOwner function. Change the listing date to start the vesting
     * @param _tokenListDate --> New listing date in UnixDateTime UTC format
     */
    function setTokenListDate(uint256 _tokenListDate) external {
        require(msg.sender == xifraWallet, "BadOwner");
        require(block.timestamp <= tokenListingDate, "TokenListedYet");

        tokenListingDate = _tokenListDate;
    }

    /**
     * @notice Returns the number of tokens and user has bought
     * @param _user --> User account
     * @return Returns the user token balance in wei units
     */
    function getUserBoughtTokens(address _user) external view returns(uint256) {
        return userBoughtTokens[_user];
    }

    /**
     * @notice Returns the number of tokens and user has withdrawn
     * @param _user --> User account
     * @return Returns the user token withdrawns in wei units
     */
    function getUserWithdrawnTokens(address _user) external view returns(uint256) {
        return userWithdrawTokens[_user];
    }

    /**
     * @notice Returns the crypto numbers in the ICO
     * @return xifra Returns the Xifra tokens balance in the contract
     * @return eth Returns the ETHs balance in the contract
     * @return usdt Returns the USDTs balance in the contract
     * @return usdc Returns the USDCs balance in the contract
     */
    function getICOData() external view returns(uint256 xifra, uint256 eth, uint256 usdt, uint256 usdc) {
        xifra = IERC20(xifraToken).balanceOf(address(this));
        usdt = IERC20(usdtToken).balanceOf(address(this));
        usdc = IERC20(usdcToken).balanceOf(address(this));
        eth = address(this).balance;
    }

    /**
     * @notice Traslate a payment in USD to ETHs
     * @param _paymentAmount --> Payment amount in USD
     * @return Returns the ETH amount in weis
     */
    function calculateETHPayment(uint256 _paymentAmount) external view returns(uint256) {
        uint256 usdETH = _getUSDETHPrice();
        return (_paymentAmount * 10 ** 18) / usdETH;
    }

    /**
     * @notice Get the vesting unlock dates
     * @param _period --> There are 4 periods (0,1,2,3)
     * @return _date Returns the date in UnixDateTime UTC format
     */
    function getVestingDate(uint256 _period) external view returns(uint256 _date) {
        if (_period == 0) {
            _date = tokenListingDate;
        } else if (_period == 1) {
            _date = tokenListingDate + 90 days;
        } else if (_period == 2) {
            _date = tokenListingDate + 180 days;
        } else if (_period == 3) {
            _date = tokenListingDate + 270 days;
        }
    }

    /**
     * @notice Public function that returns ETHUSD par
     * @return Returns the how much USDs are in 1 ETH in weis
     */
    function getUSDETHPrice() external view returns(uint256) {
        return _getUSDETHPrice();
    }

    /**
     * @notice Uses Chainlink to query the USDETH price
     * @return Returns the ETH amount in weis (Fixed value of 3932.4 USDs in localhost development environments)
     */
    function _getUSDETHPrice() internal view returns(uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 10**10);
    }

    /**
     * @notice Internal - Is ICO active?
     * @return Returns true or false
     */
    function _isICOActive() internal view returns(bool) {
        if ((block.timestamp < icoStartDate) || (block.timestamp > icoEndDate) || (icoFinished == true)) return false;
        else return true;
    }

    /**
     * @notice External - Is ICO active?
     * @return Returns true or false
     */
    function isICOActive() external view returns(bool) {
        return _isICOActive();
    }
}