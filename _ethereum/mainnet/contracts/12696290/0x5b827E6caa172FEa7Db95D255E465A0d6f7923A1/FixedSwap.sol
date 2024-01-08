// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20Detailed.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Whitelist.sol";
import "./TransferHelper.sol";

contract FixedSwap is Pausable, Whitelist {
    using SafeMath for uint256;
    uint256 increment = 0;

    mapping(uint256 => Purchase) public purchases; /* Purchasers mapping */
    address[] public buyers; /* Current Buyers Addresses */
    uint256[] public purchaseIds; /* All purchaseIds */
    mapping(address => uint256[]) public myPurchases; /* Purchasers mapping */

    IERC20 public erc20;
    bool public isSaleFunded = false;
    uint public decimals = 0;
    bool public unsoldTokensRedeemed = false;
    uint256 public tradeValue; /* Price in Wei */
    uint256 public startDate; /* Start Date  */
    uint256 public endDate; /* End Date  */
    uint256 public individualMinimumAmount = 0; /* Minimum Amount Per Address */
    uint256 public individualMaximumAmount = 0; /* Maximum Amount Per Address */
    uint256 public minimumRaise = 0; /* Minimum Amount of Tokens that have to be sold */
    uint256 public tokensAllocated = 0; /* Tokens Available for Allocation - Dynamic */
    uint256 public tokensForSale = 0; /* Tokens Available for Sale */
    bool public isTokenSwapAtomic; /* Make token release atomic or not */
    address payable public feeAddress; /* Default Address for Fee Percentage */
    uint256 public feePercentage = 1; /* Default Fee 1% */
    bool private locked;

    struct Purchase {
        uint256 amount;
        address purchaser;
        uint256 ethAmount;
        uint256 timestamp;
        bool wasFinalized; /* Confirm the tokens were sent already */
        bool reverted; /* Confirm the tokens were sent already */
    }

    event PurchaseEvent(
        uint256 indexed purchaseId,
        uint256 amount,
        address indexed purchaser,
        uint256 ethAmount,
        uint256 timestamp,
        bool wasFinalized
    );
    event FundEvent(address indexed funder, uint256 amount, address indexed contractAddress, uint256 timestamp);
    event RedeemTokenEvent(
        uint256 indexed purchaseId,
        uint256 amount,
        address indexed purchaser,
        uint256 ethAmount,
        bool wasFinalized,
        bool reverted
    );

    constructor(
        address _tokenAddress,
        address payable _feeAddress,
        uint256 _tradeValue,
        uint256 _tokensForSale,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _individualMinimumAmount,
        uint256 _individualMaximumAmount,
        bool _isTokenSwapAtomic,
        uint256 _minimumRaise,
        uint256 _feeAmount,
        bool _hasWhitelisting
    ) Whitelist(_hasWhitelisting) {
        /* Confirmations */
        require(block.timestamp < _endDate, "End Date should be further than current date");
        require(block.timestamp < _startDate, "Start Date should be further than current date");
        require(_startDate < _endDate, "End Date higher than Start Date");
        require(_tokensForSale > 0, "Tokens for Sale should be > 0");
        require(_tokensForSale > _individualMinimumAmount, "Tokens for Sale should be > Individual Minimum Amount");
        require(_individualMaximumAmount >= _individualMinimumAmount, "Individual Maximum Amount should be > Individual Minimum Amount");
        require(_minimumRaise <= _tokensForSale, "Minimum Raise should be < Tokens For Sale");
        require(_feeAmount >= feePercentage, "Fee Percentage has to be >= 1");
        require(_feeAmount <= 99, "Fee Percentage has to be < 100");
        require(_feeAddress != address(0), "Fee Address has to be not ZERO");
        require(_tokenAddress != address(0), "Token Address has to be not ZERO");

        startDate = _startDate;
        endDate = _endDate;
        tokensForSale = _tokensForSale;
        tradeValue = _tradeValue;

        individualMinimumAmount = _individualMinimumAmount;
        individualMaximumAmount = _individualMaximumAmount;
        isTokenSwapAtomic = _isTokenSwapAtomic;

        if (!_isTokenSwapAtomic) {
            /* If raise is not atomic swap */
            minimumRaise = _minimumRaise;
        }

        erc20 = IERC20(_tokenAddress);
        decimals = IERC20Detailed(_tokenAddress).decimals();
        feePercentage = _feeAmount;
        feeAddress = _feeAddress;
    }

    /**
     * Modifier to make a function callable only when the contract has Atomic Swaps not available.
     */
    modifier isNotAtomicSwap() {
        require(!isTokenSwapAtomic, "Has to be non Atomic swap");
        _;
    }

    /**
     * Modifier to make a function callable only when the contract has Atomic Swaps not available.
     */
    modifier isSaleFinalized() {
        require(hasFinalized(), "Has to be finalized");
        _;
    }

    /**
     * Modifier to make a function callable only when the swap time is open.
     */
    modifier isSaleOpen() {
        require(isOpen(), "Has to be open");
        _;
    }

    /**
     * Modifier to make a function callable only when the contract has Atomic Swaps not available.
     */
    modifier isSalePreStarted() {
        require(isPreStart(), "Has to be pre-started");
        _;
    }

    /**
     * Modifier to make a function callable only when the contract has Atomic Swaps not available.
     */
    modifier isFunded() {
        require(isSaleFunded, "Has to be funded");
        _;
    }

    /**
     * Modifier for block reentrancy
     */
    modifier blockReentrancy {
        require(!locked, "Reentrancy is blocked");
        locked = true;
        _;
        locked = false;
    } 

    /* Get Functions */
    function isBuyer(uint256 purchase_id) public view returns (bool) {
        return (msg.sender == purchases[purchase_id].purchaser);
    }

    /* Get Functions */
    function totalRaiseCost() public view returns (uint256) {
        return (cost(tokensForSale));
    }

    function availableTokens() public view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    function tokensLeft() public view returns (uint256) {
        return tokensForSale - tokensAllocated;
    }

    function hasMinimumRaise() public view returns (bool) {
        return (minimumRaise != 0);
    }

    /* Verify if minimum raise was not achieved */
    function minimumRaiseNotAchieved() public view returns (bool) {
        require(cost(tokensAllocated) < cost(minimumRaise), "TotalRaise is bigger than minimum raise amount");
        return true;
    }

    /* Verify if minimum raise was achieved */
    function minimumRaiseAchieved() public view returns (bool) {
        if (hasMinimumRaise()) {
            require(cost(tokensAllocated) >= cost(minimumRaise), "TotalRaise is less than minimum raise amount");
        }
        return true;
    }

    function hasFinalized() public view returns (bool) {
        return block.timestamp > endDate;
    }

    function hasStarted() public view returns (bool) {
        return block.timestamp >= startDate;
    }

    function isPreStart() public view returns (bool) {
        return block.timestamp < startDate;
    }

    function isOpen() public view returns (bool) {
        return hasStarted() && !hasFinalized();
    }

    function hasMinimumAmount() public view returns (bool) {
        return (individualMinimumAmount != 0);
    }

    function cost(uint256 _amount) public view returns (uint256) {
        return _amount.mul(tradeValue).div(10**decimals);
    }

    function getPurchase(uint256 _purchase_id)
        external
        view
        returns (
            uint256,
            address,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        Purchase memory purchase = purchases[_purchase_id];
        return (purchase.amount, purchase.purchaser, purchase.ethAmount, purchase.timestamp, purchase.wasFinalized, purchase.reverted);
    }

    function getPurchaseIds() public view returns (uint256[] memory) {
        return purchaseIds;
    }

    function getBuyers() public view returns (address[] memory) {
        return buyers;
    }

    function getMyPurchases(address _address) public view returns (uint256[] memory) {
        return myPurchases[_address];
    }

    /* Fund - Pre Sale Start */
    function fund(uint256 _amount) public isSalePreStarted {
        /* Confirm transferred tokens is no more than needed */
        require(availableTokens().add(_amount) <= tokensForSale, "Transferred tokens have to be equal or less than proposed");

        /* Transfer Funds */
        TransferHelper.safeTransferFrom(address(erc20), msg.sender, address(this), _amount);
        /* If Amount is equal to needed - sale is ready */
        if (availableTokens() == tokensForSale) {
            isSaleFunded = true;
        }
        emit FundEvent(msg.sender, _amount, address(this), block.timestamp);
    }

    /* Action Functions */
    function swap(uint256 _amount) external payable whenNotPaused isFunded isSaleOpen onlyWhitelisted blockReentrancy {
        /* Confirm Amount is positive */
        require(_amount > 0, "Amount has to be positive");

        /* Confirm Amount is less than tokens available */
        require(_amount <= tokensLeft(), "Amount is less than tokens available");

        /* Confirm the user has funds for the transfer, confirm the value is equal */
        require(msg.value == cost(_amount), "User swap amount has to equal to cost of token in ETH");

        /* Confirm Amount is bigger than minimum Amount */
        require(_amount >= individualMinimumAmount, "Amount is bigger than minimum amount");

        /* Confirm Amount is smaller than maximum Amount */
        require(_amount <= individualMaximumAmount, "Amount is smaller than maximum amount");

        /* Verify all user purchases, loop thru them */
        uint256[] memory _purchases = getMyPurchases(msg.sender);
        uint256 purchaserTotalAmountPurchased = 0;
        for (uint i = 0; i < _purchases.length; i++) {
            Purchase memory _purchase = purchases[_purchases[i]];
            purchaserTotalAmountPurchased = purchaserTotalAmountPurchased.add(_purchase.amount);
        }
        require(purchaserTotalAmountPurchased.add(_amount) <= individualMaximumAmount, "Address has already passed the max amount of swap");

        if (isTokenSwapAtomic) {
            /* Confirm transfer */
            TransferHelper.safeTransfer(address(erc20), msg.sender, _amount);
        }

        uint256 purchase_id = increment;
        increment = increment.add(1);

        /* Create new purchase */
        Purchase memory purchase =
            Purchase(
                _amount,
                msg.sender,
                msg.value,
                block.timestamp,
                isTokenSwapAtomic, /* If Atomic Swap */
                false
            );
        purchases[purchase_id] = purchase;
        purchaseIds.push(purchase_id);
        myPurchases[msg.sender].push(purchase_id);
        buyers.push(msg.sender);
        tokensAllocated = tokensAllocated.add(_amount);
        emit PurchaseEvent(purchase_id, _amount, msg.sender, msg.value, block.timestamp, isTokenSwapAtomic);
    }

    /* Redeem tokens when the sale was finalized */
    function redeemTokens(uint256 purchase_id) external isNotAtomicSwap isSaleFinalized whenNotPaused blockReentrancy {
        /* Confirm it exists and was not finalized */
        require((purchases[purchase_id].amount != 0) && !purchases[purchase_id].wasFinalized, "Purchase is either 0 or finalized");
        require(isBuyer(purchase_id), "Address is not buyer");
        purchases[purchase_id].wasFinalized = true;
        TransferHelper.safeTransfer(address(erc20), msg.sender, purchases[purchase_id].amount);
        emit RedeemTokenEvent(purchase_id, purchases[purchase_id].amount, msg.sender, 0, purchases[purchase_id].wasFinalized, false);
    }

    /* Retrieve Minimum Amount */
    function redeemGivenMinimumGoalNotAchieved(uint256 purchase_id) external isSaleFinalized isNotAtomicSwap whenNotPaused blockReentrancy {
        require(hasMinimumRaise(), "Minimum raise has to exist");
        require(minimumRaiseNotAchieved(), "Minimum raise has to be reached");
        /* Confirm it exists and was not finalized */
        require((purchases[purchase_id].amount != 0) && !purchases[purchase_id].wasFinalized, "Purchase is either 0 or finalized");
        require(isBuyer(purchase_id), "Address is not buyer");
        purchases[purchase_id].wasFinalized = true;
        purchases[purchase_id].reverted = true;
        msg.sender.transfer(purchases[purchase_id].ethAmount);
        emit RedeemTokenEvent(
            purchase_id,
            0,
            msg.sender,
            purchases[purchase_id].ethAmount,
            purchases[purchase_id].wasFinalized,
            purchases[purchase_id].reverted
        );
    }

    /* Admin Functions */
    function withdrawFunds() external onlyOwner whenNotPaused isSaleFinalized {
        require(minimumRaiseAchieved(), "Minimum raise has to be reached");
        uint256 fee = address(this).balance.mul(feePercentage).div(100);
        feeAddress.transfer(fee); /* Fee Address */
        uint256 funds = address(this).balance;
        msg.sender.transfer(funds);
    }

    function withdrawUnsoldTokens() external onlyOwner isSaleFinalized {
        require(!unsoldTokensRedeemed);
        uint256 unsoldTokens;
        if (hasMinimumRaise() && (cost(tokensAllocated) < cost(minimumRaise))) {
            /* Minimum Raise not reached */
            unsoldTokens = tokensForSale;
        } else {
            /* If minimum Raise Achieved Redeem All Tokens minus the ones */
            unsoldTokens = tokensForSale.sub(tokensAllocated);
        }

        if (unsoldTokens > 0) {
            unsoldTokensRedeemed = true;
            TransferHelper.safeTransfer(address(erc20), msg.sender, unsoldTokens);
        }
    }

    function removeOtherERC20Tokens(address _tokenAddress, address _to) external onlyOwner isSaleFinalized {
        require(_tokenAddress != address(erc20), "Token Address has to be diff than the erc20 subject to sale"); // Confirm tokens addresses are different from main sale one
        IERC20Detailed erc20Token = IERC20Detailed(_tokenAddress);
        TransferHelper.safeTransfer(address(erc20Token), _to, erc20Token.balanceOf(address(this)));
    }

    function pause() external onlyOwner {
        _pause();
    }

    /* Safe Pull function */
    function safePull() external payable onlyOwner whenPaused {
        msg.sender.transfer(address(this).balance);
        TransferHelper.safeTransfer(address(erc20), msg.sender, erc20.balanceOf(address(this)));
    }
}
