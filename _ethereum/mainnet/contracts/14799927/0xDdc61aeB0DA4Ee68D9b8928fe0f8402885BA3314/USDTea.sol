/*

 /$$   /$$  /$$$$$$  /$$$$$$$  /$$$$$$$$                 
| $$  | $$ /$$__  $$| $$__  $$|__  $$__/                 
| $$  | $$| $$  \__/| $$  \ $$   | $$  /$$$$$$   /$$$$$$ 
| $$  | $$|  $$$$$$ | $$  | $$   | $$ /$$__  $$ |____  $$
| $$  | $$ \____  $$| $$  | $$   | $$| $$$$$$$$  /$$$$$$$
| $$  | $$ /$$  \ $$| $$  | $$   | $$| $$_____/ /$$__  $$
|  $$$$$$/|  $$$$$$/| $$$$$$$/   | $$|  $$$$$$$|  $$$$$$$
 \______/  \______/ |_______/    |__/ \_______/ \_______/
                                                         
The first stablecoin backed by cans of AriZona Iced Tea.                                     

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Pausable.sol";

contract USDTea is ERC20Pausable, Ownable {

    uint256 public cap;
    uint256 public shippingFee;
    uint256 public mintPrice;
    uint256 public maxPerMint;
    uint256 public mintCount = 0;
    uint256 public maxPerRedeem;
    uint256 public minPerRedeem;

    constructor(
        uint256 initialCap, 
        uint256 initialMintPrice, 
        uint256 initialMaxPerMint,
        uint256 initialShippingFee,
        uint256 initialMaxPerRedeem,
        uint256 initalMinPerRedeem,
        uint256 amtToOwner) ERC20("USDTea", "USDTEA") {
        cap = initialCap;
        mintPrice = initialMintPrice;
        maxPerMint = initialMaxPerMint;
        shippingFee = initialShippingFee;
        maxPerRedeem = initialMaxPerRedeem;
        minPerRedeem = initalMinPerRedeem;
        _mint(msg.sender, amtToOwner);
        mintCount += amtToOwner;
    }

    function mint(uint256 amt) public payable whenNotPaused {
        uint256 amtAdjusted = amt * (10 ** 18);
        require(msg.value == mintPrice * amt, 'LOW_ETHER');
        require(amtAdjusted <= maxPerMint, 'TOO_MANY');
        require(mintCount + amtAdjusted <= cap, 'CAP_MAXED');
        _mint(msg.sender, amtAdjusted);
        mintCount += amtAdjusted;
    }

    function redeem(uint256 amt) public payable whenNotPaused {
        uint256 amtAdjusted = amt * (10 ** 18);
        require(balanceOf(msg.sender) >= amtAdjusted, 'LOW_BALANCE');
        require(amtAdjusted <= maxPerRedeem, 'REDEEM_MAX');
        require(amtAdjusted >= minPerRedeem, 'REDEEM_MIN');
        require(msg.value == shippingFee, 'LOW_ETHER');
        _burn(msg.sender, amtAdjusted);
    }

    function setCap(uint256 newCap) public onlyOwner{
        cap = newCap;
    }

    function setMintPrice(uint256 newMintPrice) public onlyOwner{
        mintPrice = newMintPrice;
    }

    function setMaxPerMint(uint256 newMaxPerMint) public onlyOwner{
        maxPerMint = newMaxPerMint;
    }

    function setShippingFee(uint256 newShippingFee) public onlyOwner{
        shippingFee = newShippingFee;
    }

    function setMaxPerRedeem(uint256 newMaxPerRedeem) public onlyOwner{
        maxPerRedeem = newMaxPerRedeem;
    }

    function setMinPerRedeem(uint256 newMinPerRedeem) public onlyOwner{
        minPerRedeem = newMinPerRedeem;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }
}