//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IFlashLoanReceiver.sol";

contract LendingPool {
    using SafeMath for uint256;

    receive() payable external {}

    function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes memory _params) external {
        uint256 availableLiquidityBefore = address(this).balance;

        require(
            availableLiquidityBefore >= _amount,
            "There is not enough liquidity available to borrow"
        );

        // calculate amount fee
        uint256 amountFee = _amount.mul(30).div(10000); // 0.3% fee

        // get the FlashLoanReceiver instance
        IFlashLoanReceiver receiver = IFlashLoanReceiver(_receiver);
        (bool success,) = _receiver.call{value: _amount}("");
        require(success, "LendingPool: transfer to reciever failed");

        // execute action of the receiver
        receiver.executeOperation(_reserve, _amount, amountFee, _params);

        //check that the actual balance of the core contract includes the returned amount
        uint256 availableLiquidityAfter = address(this).balance;

        require(
            availableLiquidityAfter == availableLiquidityBefore.add(amountFee),
            "The actual balance of the protocol is inconsistent"
        );
    }
}
