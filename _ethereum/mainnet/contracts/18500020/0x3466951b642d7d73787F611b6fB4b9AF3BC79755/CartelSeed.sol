// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./PaymentSplitter.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./FixedPointMathLib.sol";
import "./ICARTEL.sol";


/*

      @@          @@@@@        @@@@@@     @@@@    @@@     @@@               
   @@@@@@@@@      @@@@@+     @@@@@@@@@@   @@@@    @@@     @@@    @@@@@@@@@   
  @@@    @@@     @@@ @@@     @@@    @@@   @@@@    @@@@    @@@   +@@@    @@@  
 @@@@    @@@     @@@ @@@     @@@    @@@@  @@@@    @@@@@   @@@   @@@@    @@@@ 
 @@@@            @@@ @@@     @@@@         @@@@    @@@@@@  @@@   @@@@    @@@@ 
 @@@@           @@@   @@@      @@@@@      @@@@   @@@@ @@@ @@@   @@@@    @@@@ 
 @@@@          @@@@   @@@@      @@@@@     @@@@   @@@@ @@@@@@@   @@@@    @@@@ 
 @@@@           @@@   @@@          @@@@   @@@@    @@@  @@@@@@   #@@@    @@@@.
 @@@@     =@@  @@@@@@@@@@@   @@@    @@@   @@@@    @@@   @@@@@   @@@@    @@@@ 
 @@@@    @@@   @@@@@@@*@@@   @@@    @@@   @@@@    @@@    @@@@   @@@@    @@@@ 
 @@@@    @@@   @@@     @@@   @@@@@@@@@@   @@@@    @@@     @@@    @@@    @@@@ 
  @@@@@@@@@    @@@     @@@%    @@@@@..    @@@@   @@@@     @@@     @@@@@@@@@  
   @@@@@@                                                           @@@@@    
                                 @#  @@@  *@                                 
                          @@@@@@*           .@@@@@@#          
                                                                             
                    @@@@@    @@@   @@@@@ @@@@@@ @@@@@@  @@                     
                   @@  @@   @@@@   @  @@   @@   @@      @@                     
                   @@      @@  @@  @  @@   @@   @@      @@                     
                   @@      @@  @@  @=-@@   @@   @@@@@@  @@                     
                   @@  @@  @@@@@@  @ @@    @@   @@      @@                     
                   @@  @@  @@  @@  @  @@   @@   @@      @@                   
                     @@    #*  @#  @   @%  @@   @%%%%@  %@@@@@@      
                     

    website: https://www.casinocartel.xyz/
    twitter: https://twitter.com/CasinoCartel_
    discord: https://discord.com/invite/nwpuwBWryU
    docs:    https://casino-cartel.gitbook.io/casino-cartel/
*/

contract CartelSeed is Ownable, PaymentSplitter {
    using FixedPointMathLib for uint256;

    ICARTEL public cartelToken;
    ICARTEL public escrowedCartelToken;

    uint256 public price;
    uint256 public supply;
    uint256 public sold = 0;
    uint256 public ratio = 40; /// 40% of tokens will be escrowed

    bool public seedOpen = false;

    uint256 public maxBuy = 101500 ether;
    uint256 public minBuy = 10150 ether;

    address payable public receiptAddress;

    mapping(address => uint256) public buyers;

    event Enterseed(address indexed sender, uint256 amount);
    event AllocateToken(address sender, uint256 amount);

    constructor(
        address _cartelToken,
        address _escrowedCartelToken,
        uint256 _seedSupply,
        uint256 _seedPrice,
        address _receiptAddress,
        address[] memory payees,
        uint256[] memory shares
    ) PaymentSplitter(payees, shares) {
        cartelToken = ICARTEL(_cartelToken);
        escrowedCartelToken = ICARTEL(_escrowedCartelToken);

        receiptAddress = payable(_receiptAddress);

        supply = _seedSupply;
        price = _seedPrice;
    }

    function enterSeed(uint256 amount) public payable {
        require(seedOpen, "First round is closed");
        require(sold <= supply, "Sold out");

        require(buyers[msg.sender] + amount <= maxBuy, "Max buy exceeded");
        require(buyers[msg.sender] + amount >= minBuy, "Min buy not reached");

        uint256 amountToPay = price.fmul(amount, FixedPointMathLib.WAD);

        require(msg.value >= amountToPay, "Wrong amount sent");

        uint256 amountEscrowed = (amount * ratio) / 100;

        sold += amount;
        buyers[msg.sender] += amount;

        cartelToken.mintFromPresale(msg.sender, amount - amountEscrowed);
        escrowedCartelToken.mintFromPresale(msg.sender, amountEscrowed);

        emit Enterseed(msg.sender, amount);
    }

    fallback() external payable {
        emit AllocateToken(msg.sender, msg.value);
    }

    function distributeAllocation(
        address[] calldata receiver,
        uint256[] calldata allocation
    ) public onlyOwner {
        if (!seedOpen) revert("First round is closed");
        for (uint256 i = 0; i < receiver.length; i++) {
            sold += allocation[i];
            buyers[receiver[i]] += allocation[i];

            uint256 amountEscrowed = (allocation[i] * ratio) / 100;

            cartelToken.mintFromPresale(
                receiver[i],
                allocation[i] - amountEscrowed
            );
            escrowedCartelToken.mintFromPresale(receiver[i], amountEscrowed);
        }
    }

    function setRatio(uint256 _ratio) public onlyOwner {
        ratio = _ratio;
    }

    function setRoundPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setRoundSupply(uint256 _amount) public onlyOwner {
        supply = _amount;
    }

    function setseedOpen(bool _open) public onlyOwner {
        seedOpen = _open;
    }

    function setMaxBuy(uint256 _maxBuy) public onlyOwner {
        maxBuy = _maxBuy;
    }

    function setMinBuy(uint256 _minBuy) public onlyOwner {
        minBuy = _minBuy;
    }

    function withdrawSeed() public onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = receiptAddress.call{ value: balance } ("");
        require(success, "Transfer failed.");
    }
}
