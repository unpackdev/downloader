// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";

contract GibPresale is Ownable {
    uint256 public constant MIN_AMOUNT = 0.01 ether;
    uint256 public constant MAX_AMOUNT = 1.5 ether;
    struct Buyer {
        address addr;
        uint256 amount;
    }
    IERC20 public token;
    uint256 public supply;
    uint256 public totalSales;
    mapping(uint256 => Buyer) public buyer;
    mapping(address => uint256) public buyerIdx;
    uint256 public numBuyers;
    uint256 public cap = 25 ether;

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Buy into the sale. MIN 0.01 ETH, MAX 1.5 ETH. You can buy more than once (all buys stack).
     */
    function buy() public payable {
        _buy();
    }

    receive() external payable {
        _buy();
    }

    function _buy() private {
        require(msg.value >= MIN_AMOUNT, "Below ETH Min");
        totalSales += msg.value;
        require(totalSales <= cap, "Over Cap");
        uint256 index = buyerIdx[msg.sender];
        if (index == 0) {
            index = ++numBuyers;
        }
        uint256 total = buyer[index].amount;
        require(msg.value + total <= MAX_AMOUNT, "Above ETH Max");
        buyerIdx[msg.sender] = index;
        buyer[index].addr = msg.sender;
        buyer[index].amount += msg.value;
    }

    function _refund(uint256 a, uint256 b) private {
        require(a > 0);
        for (uint256 i = a; i <= b; i++) {
            address payable refunding = payable(buyer[i].addr);
            refunding.transfer(buyer[i].amount);
        }
    }

    function refundAll() external onlyOwner {
        _refund(1, numBuyers);
    }

    function refundRange(uint256 from, uint256 to) external onlyOwner {
        if (from > 0) {
            _refund(from, to);
        }
    }

    function _airdrop(uint256 from, uint256 to) private {
        require(address(token) != address(0) && supply != 0, "Not Ready");
        uint256 tokenPrice = (totalSales * 10e18) / supply;
        for (uint256 i = from; i <= to; i++) {
            uint256 amount = buyer[i].amount * 10e18;
            uint256 numTokens = amount / tokenPrice;
            token.transfer(buyer[i].addr, numTokens);
        }
    }

    function airdropRange(uint256 a, uint256 b) external onlyOwner {
        if (a > 0) {
            _airdrop(a, b);
        }
    }

    function airdropAll() external onlyOwner {
        _airdrop(1, numBuyers);
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

    function setCap(uint256 cap_) public onlyOwner {
        require(cap <= 100 ether);
        cap = cap_;
    }
}
