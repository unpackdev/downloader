// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Admin.sol";

import "./console.sol";

/**
 * @title Raffle
 * @author JieLi
 *
 * @notice Functions for request drop and raffle operations
 */
abstract contract Raffle is Admin {

    // ============ Variables for Control ============

    uint256 private _WHITELIST_LENGTH_;
    mapping(address => bool) public whiteList;

    // ============ Events ============

    event UpdateRegister(address indexed reqAddress);

    event UpdateRaffle(address indexed ownerAddress, address[] indexed newAddresses);

    // ============ Functions ============
    // Constructor inherits VRFConsumerBase
    constructor() {

        // initialize _WHITELIST_LENGTH_ to zero.
        _WHITELIST_LENGTH_ = 0;

        /** Environment Traits
         * Smart Contract   - 4.00%
         * Near Future      - 8.00%
         * Reneqade Node    - 16.00%
         * Depths of Defi   - 32.00%
         * Gas Belt         - 40.00%
         */
        _ENVIRONMENT_PROBABILITY_.push(400);
        _ENVIRONMENT_PROBABILITY_.push(800);
        _ENVIRONMENT_PROBABILITY_.push(1600);
        _ENVIRONMENT_PROBABILITY_.push(3200);
        _ENVIRONMENT_PROBABILITY_.push(4000);

        /** Shine Traits
         * Marble           - 10.00%
         * Steel            - 15.00%
         * Patina           - 20.00%
         * Timber           - 25.00%
         * Acrylic          - 30.00%
         */
        _SHINE_PROBABILITY_.push(1000);
        _SHINE_PROBABILITY_.push(1500);
        _SHINE_PROBABILITY_.push(2000);
        _SHINE_PROBABILITY_.push(2500);
        _SHINE_PROBABILITY_.push(3000);

        /** Efficiency Traits
         * Pristine         - 15.00%
         * Brilliant        - 20.00%
         * Polished         - 30.00%
         * Raw              - 20.00%
         * Flawed           - 15.00%
         */
        _EFFICIENCY_PROBABILITY_.push(1500);
        _EFFICIENCY_PROBABILITY_.push(2000);
        _EFFICIENCY_PROBABILITY_.push(3000);
        _EFFICIENCY_PROBABILITY_.push(2000);
        _EFFICIENCY_PROBABILITY_.push(1500);

    }

    /**
     * @notice Whether you able to do additional mint function - this should be called for the additional drop
     */
    function isAdditionalDrop() external view returns (bool) {
        if (whiteList[msg.sender] || _RAFFLE_ALLOWED_) {
            return false;
        }

        if (_PRESALE_ALLOWED_ && (_PRESALE_COUNT_ <= _WHITELIST_LENGTH_)) {
            return false;
        }

        if (!_PRESALE_ALLOWED_ && ((_WHITE_LIST_COUNT_ + _PRESALE_COUNT_) <= _WHITELIST_LENGTH_)) {
            return false;
        }
        return true;
    }

    /**
     * @notice Register directly to the whitelist function - this should be called for the unregistered wallet
     * required - _PRESALE_ALLOWED_ == true && _RAFFLE_ALLOWED_ == false
     */
    function register() public {
        require(!whiteList[msg.sender], "ALREADY REGISTERED IN WHITELIST");
        require(!_RAFFLE_ALLOWED_, "RAFFLE NOT PROCESSED");

        if (_PRESALE_ALLOWED_) {
            require(_PRESALE_COUNT_ > _WHITELIST_LENGTH_, "PRESALE COUNT LIMIT");
        } else {
            require((_WHITE_LIST_COUNT_ + _PRESALE_COUNT_) > _WHITELIST_LENGTH_, "WHITELIST COUNT LIMIT");
        }

        _WHITELIST_LENGTH_ ++;
        whiteList[msg.sender] = true;
        emit UpdateRegister(msg.sender);
    }

    /**
     * @notice Register WhiteList function
     */
    function raffle(address[] memory _addressList) onlyOwner onlyRaffle external returns (uint256) {
        for (uint256 i = 0; i < _addressList.length; i ++) {
            address selected = _addressList[i];
            whiteList[selected] = true;
            _WHITELIST_LENGTH_ ++;
        }
        emit UpdateRaffle(msg.sender, _addressList);
        return _addressList.length;
    }

    // ============ Helper Functions ============

}
