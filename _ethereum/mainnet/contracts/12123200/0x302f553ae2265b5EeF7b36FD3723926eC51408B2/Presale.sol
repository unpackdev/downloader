pragma solidity ^0.6.12;

import "./Context.sol";
import "./Ownable.sol";

contract Presale is Context, Ownable {
    uint256 public minContribution = 0.5 ether;
    uint256 public maxContribution = 1 ether;
    uint256 public totalContributed = 0;
    uint256 public totalCap = 50 ether;

    address payable wallet = 0x2963B4311e07da3D9c50F2e1eb14659e42e3f4A9;

    mapping(address => uint256) public contributions;

    receive() external payable {
        require(totalContributed + msg.value <= totalCap, "Cap reached");
        require(msg.value >= minContribution && msg.value <= maxContribution, "Min contribution 0.5 max 1 ETH");
        require(contributions[msg.sender] + msg.value <= maxContribution, "Max contribution per wallet 1 ETH");

        totalContributed += msg.value;
        contributions[msg.sender] += msg.value;
    }

    function setWallet(address payable newWallet) external onlyOwner() {
        wallet = newWallet;
    }

    function collectFunds() external onlyOwner() {
        wallet.transfer(address(this).balance);
    }
}
