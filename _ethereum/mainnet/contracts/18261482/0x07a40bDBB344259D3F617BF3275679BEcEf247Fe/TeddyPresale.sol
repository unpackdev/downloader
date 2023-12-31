// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";

contract TeddyPresale is Ownable {
    IERC20 public token;

    uint256 public supply;

    uint256 public constant MIN_AMOUNT = 0.05 ether;

    uint256 public constant MAX_AMOUNT = 1.5 ether;

    uint256 public totalSales;

    struct Buyer {
        address addr;
        uint256 amount;
        bool claimed;
    }

    mapping(uint256 => Buyer) public buyer;

    mapping(address => uint256) public buyerIndex;

    uint256 public totalBuyers;

    bool public claimOpen;

    uint256 public capacity = 5 ether;

    constructor() Ownable(msg.sender) {}

    function buy() public payable {
        _presaleBuy();
    }

    receive() external payable {
        _presaleBuy();
    }

    function _presaleBuy() private whileNotClaiming {
        require(msg.value >= MIN_AMOUNT, "Below ETH Minimum");
        totalSales += msg.value;
        require(totalSales <= capacity, "Above Cap");
        uint256 index = buyerIndex[msg.sender];
        if (index == 0) {
            index = ++totalBuyers;
        }
        uint256 total = buyer[index].amount;
        require(msg.value + total <= MAX_AMOUNT, "Above ETH Maximum");
        buyerIndex[msg.sender] = index;
        buyer[index].addr = msg.sender;
        buyer[index].amount += msg.value;
    }

    function claim() public payable {
        require(claimOpen, "Claim not open");
        uint256 index = buyerIndex[msg.sender];
        if (index != 0 && address(token) != address(0) && supply != 0) {
            uint256 tokenPrice = (totalSales * 10e18) / supply;
            uint256 amount = buyer[index].amount * 10e18;
            uint256 numTokens = amount / tokenPrice;
            require(!buyer[index].claimed, "Already claimed");
            buyer[index].claimed = true;
            token.transfer(buyer[index].addr, numTokens);
        }
    }

    function _refund(uint256 a, uint256 b) private {
        require(a > 0);
        for (uint256 i = a; i <= b; i++) {
            address payable refunding = payable(buyer[i].addr);
            refunding.transfer(buyer[i].amount);
        }
    }

    function refund() external onlyOwner {
        _refund(1, totalBuyers);
    }

    function refund(uint256 from, uint256 to) external onlyOwner {
        require(from > 0);
        _refund(from, to);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw Failed");
    }

    function withdrawERC20() public onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function updateToken(IERC20 token_, uint256 supply_) public onlyOwner {
        token = token_;
        supply = supply_;
    }

    function toggleClaim() public onlyOwner {
        claimOpen = !claimOpen;
    }

    function setCap(uint256 cap) public onlyOwner {
        require(cap <= 20 ether);
        capacity = cap;
    }

    modifier whileNotClaiming() {
        if (claimOpen) {
            return;
        }
        _;
    }
}
