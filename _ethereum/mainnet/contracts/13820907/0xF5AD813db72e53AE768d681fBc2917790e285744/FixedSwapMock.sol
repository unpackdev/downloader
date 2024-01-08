// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20Detailed.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./WhitelistMock.sol";

contract FixedSwapMock is Pausable, WhitelistMock {
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
    ) WhitelistMock(_hasWhitelisting) {
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
}
