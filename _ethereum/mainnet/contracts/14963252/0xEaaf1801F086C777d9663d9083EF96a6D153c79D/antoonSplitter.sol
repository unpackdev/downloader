//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract AntoonSplitter is PaymentSplitter, Ownable {

    address[] private payees;  // payees of the payment
    
    constructor(
        address[] memory _payees, 
        uint256[] memory _splits
    )
    PaymentSplitter(
        _payees, 
        _splits
    )
    {
        payees = _payees;
    }

    function distribute() external onlyOwner {
        address _address;
        for (uint256 i = 0; i < payees.length; i++) {
            _address = payees[i]; 
            release(payable(_address));
        }
    }

    function distributeERC20(IERC20 _token) external onlyOwner {
        address _address;
        for (uint256 i = 0; i < payees.length; i++) {
            _address = payees[i]; 
            release(_token, payable(_address));
        }
    }

}