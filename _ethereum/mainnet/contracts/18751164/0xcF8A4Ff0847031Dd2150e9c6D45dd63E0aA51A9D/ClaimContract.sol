//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.18;

contract ClaimContract {
    address public owner;
    uint256 public totalAddedReward;
    uint256 public totalClaimedReward;
    uint256 public totalUsersClaimed;
    bool public enableClaim;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public claimedBalance;
    mapping(address => bool) public alreadyClaimed;

    modifier onlyOwner() {
        require(msg.sender == owner, " Not an owner");
        _;
    }

    receive() external payable {
        totalAddedReward += msg.value;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function addWalletsData(
        address[] memory wallet,
        uint256[] memory amount
    ) public onlyOwner {
        require(
            wallet.length == amount.length,
            "wallet and amount length mismatch"
        );
        for (uint256 i = 0; i < wallet.length; i++) {
            userBalance[wallet[i]] += amount[i];
        }
    }

    function claim() public {
        require(enableClaim, "wait for owner to start claim");
        uint256 availableBalance = userBalance[msg.sender] -
            claimedBalance[msg.sender];
        require(availableBalance > 0, "already claimed");
        claimedBalance[msg.sender] += availableBalance;
        totalClaimedReward += availableBalance;
        if (!alreadyClaimed[msg.sender]) {
            totalUsersClaimed++;
            alreadyClaimed[msg.sender] = true;
        }
        payable(msg.sender).transfer(availableBalance);
    }

    function enableClaimState(bool _state) external onlyOwner {
        enableClaim = _state;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // to draw out tokens
    function transferStuckFunds(
        address _receiver,
        uint256 _value
    ) external onlyOwner {
        payable(_receiver).transfer(_value);
    }
}