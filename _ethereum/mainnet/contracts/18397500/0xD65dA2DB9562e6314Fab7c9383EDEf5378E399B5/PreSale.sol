// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";

contract PreSale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    uint public constant version = 1;
    uint public constant finalizeServiceFee = 5;
    uint public constant emergencyWithdrawalServiceFee = 10;

    address serviceReceiver;

    uint256 public rate;

    address public saleToken;
    uint public saleTokenDec;

    uint256 public minBuyLimit;
    uint256 public maxBuyLimit;

    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;

    uint256 public totalTokensforSale;
    uint256 public totalTokensSold;

    address[] public tokenWL;
    mapping(address => bool) public tokenWLEnabled;
    mapping(address => uint256) public tokenPrices;

    address[] public contributors;
    mapping(address => ContributorDetails) public contributorDetails;

    bool public isCancelled;
    bool public isFinalized;

    struct ContributorDetails {
        uint256 amount;
        bool isClaimed;
        bool isRefunded;
        bool isExists;
        mapping(address => uint256) paidAmount;
    }

    modifier onlyContributor() {
        require(
            contributorDetails[msg.sender].amount > 0,
            "PinkyFi: You have not bought any tokens"
        );
        _;
    }

    modifier cancelled() {
        require(isCancelled, "PinkyFi: Sale is not cancelled");
        _;
    }

    modifier beforeSaleStart() {
        if (preSaleStartTime != 0) {
            require(
                block.timestamp < preSaleStartTime,
                "PinkyFi: Sale has already started"
            );
        }
        _;
    }

    modifier beforeSaleEnd() {
        require(
            block.timestamp < preSaleEndTime,
            "PinkyFi: Sale has already ended"
        );
        _;
    }

    modifier afterSaleEnd() {
        require(
            block.timestamp > preSaleEndTime,
            "PinkyFi: Sale has not ended yet"
        );
        _;
    }

    modifier saleIsLive() {
        require(
            block.timestamp > preSaleStartTime,
            "PinkyFi: Sale has not started"
        );
        require(
            block.timestamp < preSaleEndTime,
            "PinkyFi: Sale has already ended"
        );
        require(!isCancelled, "PinkyFi: Sale is cancelled");
        _;
    }

    modifier saleValid(uint256 _preSaleStartTime, uint256 _preSaleEndTime) {
        require(
            block.timestamp < _preSaleStartTime,
            "PinkyFi: Starting time is less than current TimeStamp"
        );
        require(
            _preSaleStartTime < _preSaleEndTime,
            "PinkyFi: Invalid PreSale Dates"
        );
        _;
    }

    constructor(
        uint256 _rate,
        address _saleToken,
        uint256 _totalTokensforSale,
        uint256 _minBuyLimit,
        uint256 _maxBuyLimit,
        uint256 _preSaleStartTime,
        uint256 _preSaleEndTime,
        address[] memory _tokenWL,
        uint256[] memory _tokenPrices,
        address _serviceReceiver
    ) {
        serviceReceiver = _serviceReceiver;
        rate = _rate;
        saleToken = _saleToken;
        saleTokenDec = IERC20Metadata(saleToken).decimals();
        totalTokensforSale = _totalTokensforSale;

        minBuyLimit = _minBuyLimit;
        maxBuyLimit = _maxBuyLimit;

        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime = _preSaleEndTime;

        for (uint i = 0; i < _tokenWL.length; i++) {
            tokenWL.push(_tokenWL[i]);
            tokenWLEnabled[_tokenWL[i]] = true;
            tokenPrices[_tokenWL[i]] = _tokenPrices[i];
        }
    }

    function getTotalContributors() external view returns (uint256) {
        return contributors.length;
    }

    function setSalePeriodParams(
        uint256 _preSaleStartTime,
        uint256 _preSaleEndTime
    )
        external
        onlyOwner
        beforeSaleStart
        saleValid(_preSaleStartTime, _preSaleEndTime)
    {
        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime = _preSaleEndTime;
    }

    function cancel() external onlyOwner beforeSaleEnd {
        require(!isFinalized, "PinkyFi: Already finalized");
        require(!isCancelled, "PinkyFi: Sale is already cancelled");
        
        isCancelled = true;
    }

    function setMinMaxBuyLimit(
        uint256 _minBuyLimit,
        uint256 _maxBuyLimit
    ) external onlyOwner {
        minBuyLimit = _minBuyLimit;
        maxBuyLimit = _maxBuyLimit;
    }

    function getTokenAmount(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 amtOut;
        if (token != address(0)) {
            require(
                tokenWLEnabled[token] == true,
                "PinkyFi: Token not whitelisted"
            );
            uint256 price = tokenPrices[token];
            amtOut = amount.mul(10 ** saleTokenDec).div(price);
        } else {
            amtOut = amount.mul(10 ** saleTokenDec).div(rate);
        }
        return amtOut;
    }

    function buyToken(
        address _token,
        uint256 _amount
    ) external payable saleIsLive {
        uint256 saleTokenAmt;
        uint256 paidAmount;

        if (_token != address(0)) {
            saleTokenAmt = getTokenAmount(_token, _amount);
            paidAmount = _amount;
        } else {
            saleTokenAmt = getTokenAmount(address(0), msg.value);
            paidAmount = msg.value;
        }

        ContributorDetails storage contributor = contributorDetails[msg.sender];

        require(
            minBuyLimit == 0 || saleTokenAmt >= minBuyLimit,
            "PinkyFi: Min buy limit not reached"
        );
        require(
            maxBuyLimit == 0 || contributor.amount + saleTokenAmt <= maxBuyLimit,
            "PinkyFi: Max buy limit reached"
        );
        require(
            (totalTokensSold + saleTokenAmt) <= totalTokensforSale,
            "PinkyFi: Total Token Sale Reached"
        );

        if (_token != address(0)) {
            require(_amount > 0, "PinkyFi: Cannot buy with zero amount");

            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            contributor.paidAmount[_token] += paidAmount;
        } else {
            require(msg.value > 0, "PinkyFi: Cannot buy with zero amount");
            contributor.paidAmount[address(0)] += paidAmount;
        }

        totalTokensSold += saleTokenAmt;
        contributor.amount += saleTokenAmt;

        if(!contributor.isExists) {
            contributor.isExists = true;
            contributors.push(msg.sender);
        }
    }

    function claim() external afterSaleEnd onlyContributor {
        require(!isCancelled, "PinkyFi: Sale is cancelled");

        ContributorDetails storage contributor = contributorDetails[msg.sender];

        require(contributor.isClaimed == false, "PinkyFi: Already claimed");

        uint256 tokensforWithdraw = contributor.amount;
        IERC20(saleToken).safeTransfer(msg.sender, tokensforWithdraw);
        contributor.isClaimed = true;
    }

    function withdrawCurrency(
        uint256 _amount,
        address _to,
        uint _feePercent
    ) private {
        if (_amount > 0) {
            uint256 fee = _amount.mul(_feePercent).div(100);

            payable(serviceReceiver).transfer(fee);
            payable(_to).transfer(_amount.sub(fee));
        }
    }

    function withdrawToken(
        address _token,
        uint256 _amount,
        address _to,
        uint _feePercent
    ) private {
        if (_amount > 0) {
            uint256 fee = _amount.mul(_feePercent).div(100);

            IERC20(_token).safeTransfer(serviceReceiver, fee);
            IERC20(_token).safeTransfer(_to, _amount.sub(fee));
        }
    }

    function contributorEmergencyWithdrawal()
        external
        saleIsLive
        onlyContributor
    {
        ContributorDetails storage contributor = contributorDetails[msg.sender];
        uint256 totalPaidAmountEth = contributor.paidAmount[address(0)];

        withdrawCurrency(
            totalPaidAmountEth,
            msg.sender,
            emergencyWithdrawalServiceFee
        );

        contributor.paidAmount[address(0)] = 0;

        for (uint i = 0; i < tokenWL.length; i++) {
            withdrawToken(
                tokenWL[i],
                contributor.paidAmount[tokenWL[i]],
                msg.sender,
                emergencyWithdrawalServiceFee
            );
            contributor.paidAmount[tokenWL[i]] = 0;
        }

        totalTokensSold -= contributor.amount;
        contributor.amount = 0;
    }

    function withdrawCancelledTokens() external onlyOwner cancelled {
        IERC20(saleToken).safeTransfer(
            msg.sender,
            IERC20(saleToken).balanceOf(address(this))
        );
    }

    function withdrawContribution() external cancelled {
        ContributorDetails storage contributor = contributorDetails[msg.sender];

        require(!contributor.isRefunded, "PreSale: Already refunded");

        uint256 paidAmountEth = contributor.paidAmount[address(0)];

        if (paidAmountEth > 0) {
            payable(msg.sender).transfer(paidAmountEth);
        }

        for (uint i = 0; i < tokenWL.length; i++) {
            uint256 paidAmountToken = contributor.paidAmount[tokenWL[i]];
            if (paidAmountToken > 0) {
                IERC20(tokenWL[i]).safeTransfer(msg.sender, paidAmountToken);
            }
        }

        contributor.isRefunded = true;
    }

    function finalize() external onlyOwner afterSaleEnd {
        require(!isCancelled, "PinkyFi: Sale is cancelled");
        require(!isFinalized, "PinkyFi: Already finalized");

        withdrawCurrency(address(this).balance, owner(), finalizeServiceFee);

        for (uint i = 0; i < tokenWL.length; i++) {
            withdrawToken(
                tokenWL[i],
                IERC20(tokenWL[i]).balanceOf(address(this)),
                owner(),
                finalizeServiceFee
            );
        }

        IERC20(saleToken).safeTransfer(
            owner(),
            IERC20(saleToken).balanceOf(address(this)).sub(totalTokensSold)
        );

        isFinalized = true;
    }
}