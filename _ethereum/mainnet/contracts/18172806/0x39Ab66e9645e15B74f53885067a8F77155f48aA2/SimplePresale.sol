// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract SimplePresale is Ownable, ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint;

    bool public isInit;
    bool public isRefund;
    bool public isFinish;
    address payable public dev;
    uint public ethRaised;

    struct Pool {
        uint startTime;
        uint endTime;
        uint hardCap;
        uint softCap;
        uint maxBuy;
        uint minBuy;
        uint tokenPrice;
        IERC20 token;
    }

    Pool public pool;
    mapping(address => uint) public ethContribution;
    mapping(address => bool) public hasClaimed;

    modifier onlyActive {
        require(block.timestamp >= pool.startTime, "Presale must be active.");
        require(block.timestamp <= pool.endTime, "Presale must be active.");
        _;
    }

    modifier onlyInactive {
        require(
            block.timestamp < pool.startTime || 
            block.timestamp > pool.endTime || 
            ethRaised >= pool.hardCap, "Presale must be inactive."
        );
        _;
    }

    modifier onlyRefund {
        require(
            isRefund == true || 
            (block.timestamp > pool.endTime && ethRaised < pool.softCap), "Refund unavailable."
        );
        _;
    }

    constructor() {
        isInit = false;
        isFinish = false;
        isRefund = false;
        ethRaised = 0;

        dev = payable(_msgSender());
    }

    function getTokenAmount(address beneficiary) public view returns (uint) {
        return ethContribution[beneficiary] * 1e18 / pool.tokenPrice;
    }

    receive() external payable {
        if (block.timestamp >= pool.startTime && block.timestamp <= pool.endTime) {
            purchase();
        } else {
            revert("Presale is closed");
        }
    }

    function purchase() public payable onlyActive {
        require(!isRefund, "Presale has been cancelled.");

        uint weiAmount = msg.value;
        _checkSaleRequirements(msg.sender, weiAmount);
        ethRaised += weiAmount;
        ethContribution[msg.sender] += weiAmount;
        emit Bought(_msgSender(), weiAmount);
    }

    function refund() external onlyRefund {
        uint refundAmount = ethContribution[msg.sender];

        if (address(this).balance >= refundAmount) {
            if (refundAmount > 0) {
                ethContribution[msg.sender] = 0;
                address payable refunder = payable(msg.sender);
                refunder.transfer(refundAmount);
                emit Refunded(refunder, refundAmount);
            }
        }
    }

    function claim() external nonReentrant {
        require(isFinish, "Can only claim if presale is finished");
        require(!isRefund, "Can not claim if refund is active");
        require(ethContribution[_msgSender()] > 0, "Nothing to claim");
        require(!hasClaimed[_msgSender()], "User has already claimed his tokens");

        hasClaimed[_msgSender()] = true;
        uint amount = getTokenAmount(_msgSender());
        pool.token.transfer(_msgSender(), amount);
        emit Claimed(_msgSender(), amount);
    }

    function _checkSaleRequirements(address _beneficiary, uint _amount) internal view { 
        require(_beneficiary != address(0), "Transfer to 0 address.");
        require(_amount != 0, "Wei Amount is 0");
        require(_amount >= pool.minBuy, "Min buy is not met.");
        require(_amount + ethContribution[_beneficiary] <= pool.maxBuy, "Max buy limit exceeded.");
        require(ethRaised + _amount <= pool.hardCap, "HC Reached.");
        this;
    }

    function initSale(
        uint _startTime,
        uint _endTime,
        uint _hardCap,
        uint _softCap,
        uint _maxBuy,
        uint _minBuy,
        uint _tokenPrice
    ) external onlyOwner onlyInactive {        
        require(isInit == false, "Presale is not initialized");
        require(_startTime >= block.timestamp, "Invalid start time.");
        require(_endTime > block.timestamp, "Invalid end time.");
        require(_minBuy < _maxBuy, "Min buy must be greater than max buy.");
        require(_minBuy > 0, "Min buy must exceed 0.");

        Pool memory newPool = Pool(
            _startTime,
            _endTime, 
            _hardCap,
            _softCap, 
            _maxBuy, 
            _minBuy,
            _tokenPrice,
            IERC20(address(0))
        );

        pool = newPool;
        isInit = true;
    }

    function setToken(
        address _token
    ) external onlyOwner {
        require(address(pool.token) == address(0), "Token must not be set");
        pool.token = IERC20(_token);
    }

    function finishSale() external onlyOwner onlyInactive {
        require(ethRaised >= pool.softCap, "Soft Cap is not met.");
        require(block.timestamp > pool.startTime, "Can not finish before start");
        require(!isFinish, "Presale is already closed.");
        require(!isRefund, "Presale is in refund process.");

        isFinish = true;
        pool.endTime = block.timestamp;
        Address.sendValue(dev, address(this).balance);
    }

    function cancelSale() external onlyOwner onlyActive {
        require(!isFinish, "Sale is finished.");
        pool.endTime = 0;
        isRefund = true;

        emit Cancelled(msg.sender, address(this));
    }

    event Cancelled(
        address indexed _inititator, 
        address indexed _presale
    );

    event Bought(
        address indexed _buyer, 
        uint _ethAmount
    );

    event Refunded(
        address indexed _refunder, 
        uint _ethAmount
    );
    
    event Claimed(
        address indexed _beneficiary,
        uint _tokenAmount
    );
}   