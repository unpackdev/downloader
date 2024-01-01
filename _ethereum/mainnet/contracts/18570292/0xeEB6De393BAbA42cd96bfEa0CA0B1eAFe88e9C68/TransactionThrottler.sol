// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Ownable.sol";

contract TransactionThrottler is Ownable {
    bool private _initialized;
    bool private _restrictionActive;
    uint256 private _tradingStart;
    uint256 private _maxTransferAmount;
    uint256 private constant _delayBetweenTx = 120;
    mapping(address => uint256) private _previousTx;

    event RestrictionActiveChanged(bool active);
    event MaxTransferAmountChanged(uint256 maxTransferAmount);
    
    function initAntibot() external onlyOwner {
        require(!_initialized, "Protection: Already initialized");
        _initialized = true;
        _restrictionActive = true;
        _maxTransferAmount = 25_000 * 10**18;

        emit RestrictionActiveChanged(_restrictionActive);
        emit MaxTransferAmountChanged(_maxTransferAmount);
    }

    function setMaxTransferAmount(uint256 amount) external onlyOwner {
        _maxTransferAmount = amount;
        emit MaxTransferAmountChanged(_maxTransferAmount);
    }

    function setRestrictionActive(bool active) external onlyOwner {
        require(active == false, "Protection: operation is prohibited!");
        _restrictionActive = active;
        emit RestrictionActiveChanged(_restrictionActive);
    }

    modifier transactionThrottler(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (_restrictionActive) {         
            if (_maxTransferAmount > 0) {
                require(amount <= _maxTransferAmount, "Protection: Limit exceeded");
            }                 
            require(_previousTx[recipient] + _delayBetweenTx <= block.timestamp, "Protection: 120 sec/tx allowed");
            _previousTx[recipient] = block.timestamp;                
            require(_previousTx[sender] + _delayBetweenTx <= block.timestamp, "Protection: 120 sec/tx allowed");
            _previousTx[sender] = block.timestamp;        
        }
        _;
    }
}