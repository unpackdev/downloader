// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./OwnerWithdrawable_v1.2.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";


contract SaleContract is OwnerWithdrawable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    uint256 public rate;
    address public saleToken;
    uint public saleTokenDec;
    uint256 public totalTokensforSale;
    uint256 public maxBuyLimit;
    uint256 public minBuyLimit;

    // Whitelist of tokens to buy from
    mapping(address => bool) public tokenWL;

    // 1 Token price in terms of WL tokens
    mapping(address => uint256) public tokenPrices;

    address[] public buyers;

    bool public isUnlockingStarted;
    bool public isPresaleStarted;
    uint public presalePhase;
    
    mapping(address => BuyerTokenDetails) public buyersAmount;
    mapping(address => uint256) public presaleData;

    uint256 public totalTokensSold;

    struct BuyerTokenDetails {
        uint amount;
        uint claimedAmount;
    }

    constructor() { }

    modifier saleStarted(){
        require (!isPresaleStarted, "PreSale: Sale has already started");
        _;
    }

    //function to set information of Token sold in Pre-Sale and its rate in Native currency
    function setSaleTokenParams(
        address _saleToken,
        uint256 _totalTokensforSale
    ) external onlyOwner saleStarted{
        saleToken = _saleToken;
        saleTokenDec = IERC20Metadata(saleToken).decimals();
        totalTokensforSale = _totalTokensforSale;
        IERC20(saleToken).safeTransferFrom(msg.sender, address(this), totalTokensforSale);
    }

    // Add a token to buy presale token from, with price
    function addWhiteListedToken(
        address _token,
        uint256 _price
    ) external onlyOwner {
        require(_price != 0, "Presale: Cannot set price to 0");
        tokenWL[_token] = true;
        tokenPrices[_token] = _price;
    }

    function updateEthRate(uint256 _rate) external  onlyOwner {
        rate = _rate;
    }

    function updateTokenRate(
        address _token,
        uint256 _price
    )external onlyOwner{
        require(tokenWL[_token], "Presale: Token not whitelisted");
        require(_price != 0, "Presale: Cannot set price to 0");
        tokenPrices[_token] = _price;
    }

    function startPresale() external onlyOwner {
        require(!isPresaleStarted, "PreSale: Sale has already started");
        isPresaleStarted = true;
    }

    function stopPresale() external onlyOwner {
        require(isPresaleStarted, "PreSale: Sale hasn't started yet!");
        isPresaleStarted = false;
    }

    function startUnlocking() external onlyOwner {
        require(!isUnlockingStarted, "PreSale: Unlocking has already started");
        isUnlockingStarted = true;
    }

    function stopUnlocking() external onlyOwner {
        require(isUnlockingStarted, "PreSale: Unlocking hasn't started yet!");
        isUnlockingStarted = false;
    }

    // Public view function to calculate amount of sale tokens returned if you buy using "amount" of "token"
    function getTokenAmount(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        if(!isPresaleStarted) {
            return 0;
        }
        uint256 amtOut;
        if(token != address(0)){
            require(tokenWL[token] == true, "Presale: Token not whitelisted");
            uint256 price = tokenPrices[token];
            amtOut = amount.mul(10**saleTokenDec).div(price);
        }
        else{
            amtOut = amount.mul(10**saleTokenDec).div(rate);
        }
        return amtOut;
    }

    // Public Function to buy tokens. APPROVAL needs to be done first
    function buyToken(address _token, uint256 _amount) external payable {
        require(isPresaleStarted, "PreSale: Sale stopped!");

        uint256 saleTokenAmt;
        if(_token != address(0)){
            require(_amount > 0, "Presale: Cannot buy with zero amount");
            require(tokenWL[_token] == true, "Presale: Token not whitelisted");

            saleTokenAmt = getTokenAmount(_token, _amount);

            // check if saleTokenAmt is greater than minBuyLimit
            require(saleTokenAmt >= minBuyLimit, "Presale: Min buy limit not reached");
            require(presaleData[msg.sender] + saleTokenAmt <= maxBuyLimit, "Presale: Max buy limit reached for this phase");
            require((totalTokensSold + saleTokenAmt) <= totalTokensforSale, "PreSale: Total Token Sale Reached!");

            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
        else{
            saleTokenAmt = getTokenAmount(address(0), msg.value);

            // check if saleTokenAmt is greater than minBuyLimit
            require(saleTokenAmt >= minBuyLimit, "Presale: Min buy limit not reached");
            require(presaleData[msg.sender] + saleTokenAmt <= maxBuyLimit, "Presale: Max buy limit reached for this phase");
            require((totalTokensSold + saleTokenAmt) <= totalTokensforSale, "PreSale: Total Token Sale Reached!");

        }
 
        totalTokensSold += saleTokenAmt;
        BuyerTokenDetails storage buyerDetails = buyersAmount[msg.sender];
        buyerDetails.amount += saleTokenAmt;
        presaleData[msg.sender] += saleTokenAmt; 
    }

    function withdrawTokenBuyed() external {
        uint256 tokensforWithdraw;
        require(isUnlockingStarted, "Presale: Locking period not over yet");
        BuyerTokenDetails storage buyerDetails = buyersAmount[msg.sender];
        tokensforWithdraw = buyerDetails.amount - buyerDetails.claimedAmount;
        require(tokensforWithdraw > 0, "Presale: No tokens available for withdrawal");
        buyerDetails.claimedAmount += tokensforWithdraw;
        IERC20(saleToken).safeTransfer(msg.sender, tokensforWithdraw);
    }

    function setMinBuyLimit(uint _minBuyLimit) external onlyOwner {
        minBuyLimit = _minBuyLimit;
    }

    function setMaxBuyLimit(uint _maxBuyLimit) external onlyOwner {
        maxBuyLimit = _maxBuyLimit;
    }
}