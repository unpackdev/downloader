// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Context.sol";
import "./Ownable.sol";

contract PublicSale is Context, Ownable {

    uint256 public minDeposit = 0.01 * 10 ** 18;

    address public feeAddress;

    bool public isSaleActive = true;

    mapping(address => uint256) public depositedAmount;

    uint256 public totalDepositedAmount;

    struct DepositInfo {
        address depositor;
        uint256 amount;
    }

    event DepositEvent(address depositor, uint256 amount);

    DepositInfo[] public depositList;

    constructor() {
        feeAddress = address(0x7f388E617DcB6388CccF8750b3c8c8f8C7eb09F4);
    }

    function deposit() external payable {
        // make sure that sale is active
        require(isSaleActive);

        // make sure that user pays enough
        require(msg.value >= minDeposit);

        // send fees to fee address
        payable(feeAddress).transfer(msg.value);

        // increase deposited amount
        depositedAmount[_msgSender()] += msg.value;

        // increase total deposited amount
        totalDepositedAmount += msg.value;

        // add entry to deposit list
        depositList.push(DepositInfo(_msgSender(), msg.value));

        // emit deposit event
        emit DepositEvent(_msgSender(), msg.value);
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        minDeposit = _minDeposit;
    }

    function getDepositList() external view returns (DepositInfo[] memory) {
        return depositList;
    }

    function getDepositListLength() external view returns (uint256) {
        return depositList.length;
    }
}
