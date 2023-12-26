// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./Ownable.sol";

contract DepositRouter is Ownable {
    event Deposit(address sender, uint256 amount, address token, string to);
    event FeeUpdated(uint256 amount);
    event FeeAddressUpdated(address);

    uint256 fee = 0.01 ether;
    address public feeTo;

    constructor(address _feeTo) {
        feeTo = _feeTo;
    }

    function deposit(
        uint256 _amount,
        address _token,
        string memory _to
    ) external payable {
        require(msg.value == fee, "invalid fee amount");
        IERC20(_token).transferFrom(msg.sender, address(0xDEAD), _amount);
        payable(feeTo).transfer(fee);
        emit Deposit(msg.sender, _amount, _token, _to);
    }

    function setFeeAddress(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
        emit FeeAddressUpdated(_feeTo);
    }

    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit FeeUpdated(_fee);
    }
}
