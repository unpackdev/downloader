// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title Puppy
 */
contract Puppy is ERC20, Ownable {
    string public constant NAME = "Puppy";
    string public constant SYMBOL = "PUP";

    uint public constant INITIAL_PRESALE_PRICE_WEI = 1000000000;
    uint public constant PUPPY_WEI_PER_PUPPY = 1000;
    uint public presalePriceWei;
    bool public presaleOpen;

    constructor () public ERC20(NAME, SYMBOL) {
      presaleOpen = true;
      presalePriceWei = INITIAL_PRESALE_PRICE_WEI;
    }

    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function presalePurchase(uint num) public payable {
      require(presaleOpen, "Presale is closed");
      require(msg.value >= SafeMath.mul(num, presalePriceWei), "Insufficent amount sent");
      _mint(msg.sender, SafeMath.mul(num, PUPPY_WEI_PER_PUPPY));
    }

    function setPresalePriceWei(uint newValue) public onlyOwner {
      presalePriceWei = newValue;
    }

    function endPresale() public onlyOwner {
      presaleOpen = false;
    }

    function withdraw() public onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }
}