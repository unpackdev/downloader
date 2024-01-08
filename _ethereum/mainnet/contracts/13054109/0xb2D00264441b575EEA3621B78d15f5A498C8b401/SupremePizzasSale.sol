// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ISupremePizzas.sol";

interface PaymentSplitter {
    function pay(uint id) external payable;
}

contract SupremePizzasSale is Ownable {
    using SafeMath for uint256;
    ISupremePizzas public supremePizzas;

    PaymentSplitter _paymentSplitter;
    uint _splitterId;

    bool public hasSaleStarted = false;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public price;

    constructor(address _supremePizzas) {
        supremePizzas = ISupremePizzas(_supremePizzas);
        price = 0.08 ether;
        _paymentSplitter = PaymentSplitter(0xAFde32E520222C8163e9ed162167759bAE585122);
    }

    /**
     * @dev Main sale function. Mints Pizzas
     */
    function mintNFT(uint256 numberOfPizzas) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(
            supremePizzas.totalSupply().add(numberOfPizzas) <= MAX_SUPPLY,
            "Exceeds MAX_SUPPLY"
        );
        require(
            price.mul(numberOfPizzas) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < numberOfPizzas; i++) {
            supremePizzas.mint(msg.sender);
        }
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function mintPizzasToAddresses(address[] calldata receivers)
        external
        onlyOwner
    {
        for (uint256 index; index < receivers.length; index++) {
            supremePizzas.mint(receivers[index]);
        }
    }

    function mintPizzaTo(address receiver) external onlyOwner {
        supremePizzas.mint(receiver);
    }

    function totalSupply() external view returns (uint256) {
        return supremePizzas.totalSupply();
    }

    function setSplitterId(uint __splitterId) public onlyOwner {
        _splitterId = __splitterId;
    }

    function withdrawAll() public payable onlyOwner {
        _paymentSplitter.pay{value: address(this).balance}(_splitterId);
    }
}
