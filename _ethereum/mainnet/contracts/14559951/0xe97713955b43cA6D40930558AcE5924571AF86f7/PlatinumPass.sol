// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title PlatinumPass contract
 */
contract PlatinumPass is Pausable, Ownable {
    using SafeMath for uint256;

    // Minimum Billing cycle to subscribe
    uint256 public minBillingCycle;
    // Minimum cost to subscribe a Platinum pass
    uint256 public minBillingCost;
    // Maximum Billing cycle to subscribe
    uint256 public maxBillingCycle;
    // Maximum cost to subscribe a Platinum pass
    uint256 public maxBillingCost;

    // Address where withdraw fund
    address private wallet = 0xB91F6EE721032Ec1eCE953bf6383Af71a64569e8;

    // Mapping subscriber address to billing start date
    mapping(address => uint256) private _billStartDate;

    // Mapping subscriber address to billing end date
    mapping(address => uint256) private _billEndDate;

    event Subscribed(address _subscriber, uint256 _startDate, uint256 _endDate);

    constructor() {
        minBillingCost = 1 ether;
        minBillingCycle = 30 days;
        maxBillingCost = 7 ether;
        maxBillingCycle = 365 days;
    }

    function checkBillEndDate(address _subscriber) external view returns (uint256) {
        return _billEndDate[_subscriber];
    }

    function checkBillStartDate(address _subscriber) external view returns (uint256) {
        return _billStartDate[_subscriber];
    }

    function setMinBillingCycle(uint256 _cycle) external onlyOwner {
        minBillingCycle = _cycle;
    }

    function setMinBillingCost(uint256 _cost) external onlyOwner {
        minBillingCost = _cost;
    }

    function setMaxBillingCycle(uint256 _cycle) external onlyOwner {
        maxBillingCycle = _cycle;
    }

    function setMaxBillingCost(uint256 _cost) external onlyOwner {
        maxBillingCost = _cost;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function changeWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    /**
     * Reserve a Platinum pass by admin
     */
    function reserve(address _to, uint256 month) external onlyOwner {
        require(_to != address(0), "Invalid address to reserve.");

        _subscribe(_to, minBillingCost.mul(month));
    }

    /**
    * Subscribe or mint a Platinum pass NFT
    */
    function subscribe(address _subscriber) external payable whenNotPaused {
        require(minBillingCost <= msg.value, "Ether value sent is not correct");
        require(_subscriber != address(0), "Invalid address");

        // Subscribe
        _subscribe(_subscriber, msg.value);
    }

    function _subscribe(address _subscriber, uint256 _cost) internal {
        uint256 startDate;
        uint256 billingCycle = _cost >= maxBillingCost ? maxBillingCycle : _cost.div(minBillingCost).mul(minBillingCycle);

        if (_billEndDate[_subscriber] == 0 || block.timestamp >= _billEndDate[_subscriber]) {
            // for new subscriber or expired subscription
            startDate = block.timestamp;
            _billEndDate[_subscriber] = billingCycle.add(startDate);
        } else {
            // regualr subscription
            startDate = _billStartDate[_subscriber];
            _billEndDate[_subscriber] = billingCycle.add(_billEndDate[_subscriber]);
        }

        _billStartDate[_subscriber] = startDate;

        emit Subscribed(_subscriber, startDate, _billEndDate[_subscriber]);
    }

    function withdraw() external onlyOwner {
        payable(wallet).transfer(address(this).balance);
    }
}
