// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./Ownable.sol";

interface ISale {
    function purchaseFor(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external payable;
}

contract TernCrypto is Ownable {

    ISale public saleContract;
    IERC20 public paymentContract;
    uint public mintPrice = 25000000000000000000;

    uint private constant INFINITY_APPROVE = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    constructor(address _saleContract, address _paymentContract) {
        saleContract = ISale(_saleContract);
        paymentContract = IERC20(_paymentContract);
        approvePaymentToken();
    }

    function terncryptoMint(uint _numberOfTokens, uint _txCount, bytes32 _sku, bytes calldata _userData) public payable {
        uint256 amountToPay = mintPrice * _numberOfTokens * _txCount;
        require(paymentContract.allowance(msg.sender, address(this)) >= amountToPay, "Approve contract for spending your funds");
        require(paymentContract.transferFrom(msg.sender, address(this), amountToPay), "Insufficient funds");

        for (uint i; i < _txCount; i++) {
            saleContract.purchaseFor(payable(msg.sender), address(paymentContract), _sku, _numberOfTokens, _userData);
        }
    }

    function approvePaymentToken() public {
        paymentContract.approve(address(saleContract), INFINITY_APPROVE);
    }

    function setMintPrice(uint _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setPaymentContract(address _paymentContract) public onlyOwner {
        paymentContract = IERC20(_paymentContract);
    }

    function setSaleContract(address _saleContract) public onlyOwner {
        saleContract = ISale(_saleContract);
    }
}