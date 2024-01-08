// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IHistoryMoments.sol";

interface PaymentSplitter {
    function pay(uint id) external payable;
}

contract HistoryMomentsSale is Ownable {
    using SafeMath for uint256;
    IHistoryMoments public HistoryMoments;

    bool public hasSaleStarted = false;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public price;
    PaymentSplitter _paymentSplitter;
    uint _splitterId;

    constructor(address _HistoryMoments) {
        HistoryMoments = IHistoryMoments(_HistoryMoments);
        price = 0.07 ether;
        _paymentSplitter = PaymentSplitter(0xAFde32E520222C8163e9ed162167759bAE585122);
    }

    /**
     * @dev Main sale function. Mints HistoryMomentss
     */
    function mintNFT(uint256 numberOfHistoryMomentss) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(
            HistoryMoments.totalSupply().add(numberOfHistoryMomentss) <= MAX_SUPPLY,
            "Exceeds MAX_SUPPLY"
        );
        require(
            price.mul(numberOfHistoryMomentss) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < numberOfHistoryMomentss; i++) {
            HistoryMoments.mint(msg.sender);
        }
    }
    
    // owner mode
    function setSplitterId(uint __splitterId) public onlyOwner {
        _splitterId = __splitterId;
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

    function mintHistoryMomentsToAddresses(address[] calldata receivers)
        external
        onlyOwner
    {
        for (uint256 index; index < receivers.length; index++) {
            HistoryMoments.mint(receivers[index]);
        }
    }

    function mintHistoryMomentsTo(address receiver) external onlyOwner {
        HistoryMoments.mint(receiver);
    }

    function totalSupply() external view returns (uint256) {
        return HistoryMoments.totalSupply();
    }

    function withdrawAll() public payable onlyOwner {
        _paymentSplitter.pay{value: address(this).balance}(_splitterId);
    }
}
