// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ITWWL.sol";

interface PaymentSplitter {
    function pay(uint id) external payable;
}

contract TWWLSale is Ownable {
    using SafeMath for uint256;
    ITWWL public TWWL;

    bool public hasSaleStarted = false;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public price;
    PaymentSplitter _paymentSplitter;
    uint _splitterId = 8;

    constructor(address _TWWL) {
        TWWL = ITWWL(_TWWL);
        price = 0.04 ether;
        _paymentSplitter = PaymentSplitter(0xAFde32E520222C8163e9ed162167759bAE585122);
    }

    /**
     * @dev Main sale function. Mints TWWLs
     */
    function mintNFT(uint256 numberOfTWWLs) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(
            TWWL.totalSupply().add(numberOfTWWLs) <= MAX_SUPPLY,
            "Exceeds MAX_SUPPLY"
        );
        require(
            price.mul(numberOfTWWLs) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < numberOfTWWLs; i++) {
            TWWL.mint(msg.sender);
        }

        _paymentSplitter.pay{value: address(this).balance}(_splitterId);
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

    function mintTWWLToAddresses(address[] calldata receivers)
        external
        onlyOwner
    {
        for (uint256 index; index < receivers.length; index++) {
            TWWL.mint(receivers[index]);
        }
    }

    function mintTWWLTo(address receiver) external onlyOwner {
        TWWL.mint(receiver);
    }

    function totalSupply() external view returns (uint256) {
        return TWWL.totalSupply();
    }
}
