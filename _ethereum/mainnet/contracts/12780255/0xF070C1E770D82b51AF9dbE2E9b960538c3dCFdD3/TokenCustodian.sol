// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

contract TokenCustodian is Pausable, Ownable {
    using SafeMath for uint256;

    address public futureToken;
    address public deliveryToken;
    address public deliveryTokenHolder;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public delivered;
    bool private locked;

    modifier blockReentrancy {
        require(!locked, "Reentrancy is blocked");
        locked = true;
        _;
        locked = false;
    }
    event SetStartDate(uint256 oldStartDate, uint256 newStartDate);
    event SetEndDate(uint256 oldEndDate, uint256 newEndDate);
    event SetDeliveryTokenHolder(address oldDeliveryTokenHolder, address newDeliveryTokenHolder);
    event SetFutureToken(address oldFutureToken, address newFutureToken);
    event SetDeliveryToken(address oldDeliveryToken, address newDeliveryToken);

    event Delivered(address indexed owner, uint256 amount, uint256 timestamp);

    modifier onlyActive() {
        require(
            block.timestamp >= startDate && block.timestamp < endDate,
            "TokenCustodian: Delivery not active"
        );
        _;
    }

    constructor(address _futureToken, address _deliveryToken, uint256 _startDate, uint256 _endDate){
        require(block.timestamp < _endDate, "TokenCustodian: End Date should be further than current date");
        require(block.timestamp < _startDate, "TokenCustodian: Start Date should be further than current date");
        require(_startDate < _endDate, "TokenCustodian: End Date higher than Start Date");
        require(_futureToken != address(0), "TokenCustodian: FutureToken Address has to be not ZERO");
        require(_deliveryToken != address(0), "TokenCustodian: DeliveryToken Address has to be not ZERO");

        futureToken = _futureToken;
        deliveryToken = _deliveryToken;
        startDate = _startDate;
        endDate = _endDate;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function setDeliveryTokenHolder(address _deliveryTokenHolder) external onlyOwner {
        require(_deliveryTokenHolder != address(0), "TokenCustodian: DeliveryToken Holder Address has to be not ZERO");
        address oldDeliveryTokenHolder = deliveryTokenHolder;
        deliveryTokenHolder = _deliveryTokenHolder;

        emit SetDeliveryTokenHolder(oldDeliveryTokenHolder, deliveryTokenHolder);
    }

    function setStartDate(uint256 _startDate) external onlyOwner {
        require(block.timestamp < _startDate, "TokenCustodian: Start Date should be further than current date");
        require(_startDate < endDate, "TokenCustodian: Start Date higher than End Date");
        uint256 oldStartDate = startDate;
        startDate = _startDate;

        emit SetStartDate(oldStartDate, startDate);
    }

    function setEndDate(uint256 _endDate) external onlyOwner {
        require(block.timestamp < _endDate, "TokenCustodian: End Date should be further than current date");
        require(startDate < _endDate, "TokenCustodian: Start Date higher than End Date");
        uint256 oldEndDate = endDate;
        endDate = _endDate;

        emit SetEndDate(oldEndDate, endDate);
    }

    function setFutureToken(address _futureToken) external onlyOwner {
        require(_futureToken != address(0), "TokenCustodian: FutureToken Address has to be not ZERO");
        address oldFutureToken = futureToken;
        futureToken = _futureToken;

        emit SetFutureToken(oldFutureToken, futureToken);
    }

    function setDeliveryToken(address _deliveryToken) external onlyOwner {
        require(_deliveryToken != address(0), "TokenCustodian: DeliveryToken Address has to be not ZERO");
        address oldDeliveryToken = deliveryToken;
        deliveryToken = _deliveryToken;

        emit SetDeliveryToken(oldDeliveryToken, deliveryToken);
    }

    function deliver(uint256 amount) external blockReentrancy whenNotPaused onlyActive {
        require(deliveryTokenHolder != address(0), "TokenCustodian: DeliveryToken Holder Address has to be set");

        require(amount > 0, "TokenCustodian: Future token amount has to not ZERO");
        require(amount <= IERC20(futureToken).balanceOf(msg.sender), "TokenCustodian: not enough future token");
        require(amount <= IERC20(deliveryToken).balanceOf(deliveryTokenHolder), "TokenCustodian: Delivery Token Holder not enough amount");

        delivered = delivered.add(amount);
        TransferHelper.safeTransferFrom(futureToken, msg.sender, deliveryTokenHolder, amount);
        TransferHelper.safeTransferFrom(deliveryToken, deliveryTokenHolder, msg.sender, amount);

        emit Delivered(msg.sender, amount, block.timestamp);
    }
}