// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";

import "./IWETH.sol";

interface IERC721 {
    function mint(address to, uint amount) external;
    function totalSupply() external view returns (uint256);
}



contract LEGENDS_AUCTION_MANAGER is Ownable
{
    event Deposit(address indexed _from, uint _value);
    event Withdrawal(address indexed src, uint wad);

    address public mintingContract;
    address public payoutAddress;
    mapping(address => uint) public balanceOf;
    
    uint public auctionStart = 1655503200; // 1655503200 June 17 2022, 6pm EST 
    uint public auctionEnd = auctionStart + 7 days; // 1656064800
    uint public openRefundStart = auctionEnd + 4 hours; // 1656151200

    constructor() {
        payoutAddress = 0xf0d2090cE8b41614421e1AA243a1D008A7128b3a;
    }

    function setMintingContract(address mintingContract_) public onlyOwner{
        mintingContract = mintingContract_;
    }

    function setPayoutAddress(address payout_) public onlyOwner {
        payoutAddress = payout_;
    }

    // essentially have weth
    function deposit() public payable {
      require(msg.value > 0, "Must fund more than zero");

      balanceOf[msg.sender] += msg.value;
      emit Deposit(msg.sender, msg.value);
    }

    function withdraw() public {
      uint wad = balanceOf[msg.sender];
      require(block.timestamp >= openRefundStart, "Open refund period has not begun");
      require(wad > 0, "There must be funds to refund");

      balanceOf[msg.sender] = 0;
      payable(msg.sender).transfer(wad);
      emit Withdrawal(msg.sender, wad);
    }

    // need methods to mint
    function mintAuctionItem(address buyer, uint price) public onlyOwner {
        require(payoutAddress != 0x0000000000000000000000000000000000000000, "Need to set payout address");
        require(mintingContract != 0x0000000000000000000000000000000000000000, "Need to set minting contract");
        require(balanceOf[buyer] >= price, "Not enough funds in buyer account");

        balanceOf[buyer] -= price;
        balanceOf[payoutAddress] += price;

        IERC721(mintingContract).mint(buyer, 1);
    }

    function mintMany(address[] memory buyers, uint[] memory prices) public onlyOwner {
        require(buyers.length == prices.length, "Buyers and prices arrays must match length");
        // derp;
        for (uint i = 0; i < buyers.length; i++) {
            mintAuctionItem(buyers[i], prices[i]);
        }
    }

    function resetAuction(uint _start, uint _end, uint _refundTime) public onlyOwner {
        // if conditions are met, reset Auction
        require(block.timestamp >= openRefundStart + 1 days, "Cannot reset auction until refund has been open for a day");

        auctionStart = _start;
        auctionEnd = _end; // update later
        openRefundStart = _refundTime;
    }
}
