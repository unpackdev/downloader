// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";

contract RoyaltiesSignArt is Ownable{
    event newDeposit(address _sender, uint256 _amount);

    function withdrawToken(address _tokenContract, uint256 _amount, address _recipient) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.approve(address(this), _amount);
        tokenContract.transferFrom(address(this), _recipient, _amount);
    }

    function withdrawEth(address payable destination) public onlyOwner {
        destination.transfer(address(this).balance);
    }

    receive() external payable {
        emit newDeposit(msg.sender, msg.value);
    }
}