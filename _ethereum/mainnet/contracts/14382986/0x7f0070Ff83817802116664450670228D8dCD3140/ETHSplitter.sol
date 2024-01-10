//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ETHSplitter is Ownable {
    event Received(address from, uint256 amount);

    address private immutable _addr1;
    address private immutable _addr2;

    uint256 private immutable _addr1Percentage;

    constructor(
        address addr1_,
        address addr2_,
        uint256 addr1Percentage_
    ) {
        _addr1 = addr1_;
        _addr2 = addr2_;
        _addr1Percentage = addr1Percentage_;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdraw() public {
        uint256 _balance = address(this).balance;

        require(_balance > 0, "No balance to withdraw");
        require(
            msg.sender == _addr1 ||
                msg.sender == _addr2 ||
                msg.sender == owner(),
            "Caller is not authorized"
        );

        uint256 _amount1 = ((_balance * _addr1Percentage) / 100);

        payable(_addr1).transfer(_amount1);
        payable(_addr2).transfer(_balance - _amount1);
    }
}
