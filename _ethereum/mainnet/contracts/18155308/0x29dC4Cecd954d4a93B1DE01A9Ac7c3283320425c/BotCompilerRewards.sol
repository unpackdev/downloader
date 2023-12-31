// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.7;

contract BotCompilerRewards {
    address private _owner;

    mapping(address => uint256) public amountsClaimable;
    mapping(address => uint256) public totalRewards;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner.");
        _;
    }

    function claim() public {
        uint256 amount = amountsClaimable[msg.sender];
        require(amount > 0, "nothing to claim.");
        amountsClaimable[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function myTotalRewards() public view returns (uint256) {
        return totalRewards[msg.sender];
    }

    function myClaimableRewards() public view returns (uint256) {
        return amountsClaimable[msg.sender];
    }

    function addRewards(address[] memory recipients, uint256[] memory amounts) public payable onlyOwner {
        require(recipients.length == amounts.length, "invalid input.");
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            amountsClaimable[recipients[i]] += amounts[i];
            totalRewards[recipients[i]] += amounts[i];
            total += amounts[i];
        }
        require(msg.value >= total, "not enough funds.");
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function recoverFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}