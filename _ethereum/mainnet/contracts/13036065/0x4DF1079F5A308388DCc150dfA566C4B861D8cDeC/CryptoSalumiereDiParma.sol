//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ICryptoProsciuttiDiParma.sol";

contract CryptoSalumiereDiParma is Initializable, OwnableUpgradeable {
    uint256 public constant PRICE_PER_PROSCIUTTO_DI_PARMA = 0.05 ether;
    uint256 public constant MAX_PURCHASE_PROSCIUTTI_DI_PARMA = 20;
    uint256 public constant NUMBER_PROSCIUTTI_DI_PARMA_PER_RESERVATON = 30;

    bool public isOpen;
    address public cryptoProsciuttiDiParma;

    function initialize(address _cryptoProsciuttiDiParma) public initializer {
        __Ownable_init();
        cryptoProsciuttiDiParma = _cryptoProsciuttiDiParma;
        isOpen = false;
    }

    function open() external onlyOwner {
        isOpen = true;
    }

    function close() external onlyOwner {
        isOpen = false;
    }

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setCryptoProsciuttiDiParma(address _cryptoProsciuttiDiParma) external onlyOwner {
        cryptoProsciuttiDiParma = _cryptoProsciuttiDiParma;
    }

    function buy(uint256 _numberOfProsciuttiDiParma) external payable {
        require(isOpen, "CryptoSalumiereDiParma not opened");
        require(_numberOfProsciuttiDiParma <= MAX_PURCHASE_PROSCIUTTI_DI_PARMA, "You cannot buy more than 20 Prosciutti di Parma at a time");
        require(msg.value >= PRICE_PER_PROSCIUTTO_DI_PARMA * _numberOfProsciuttiDiParma, "We don't give away anything");
        ICryptoProsciuttiDiParma(cryptoProsciuttiDiParma).mint(msg.sender, _numberOfProsciuttiDiParma);
    }

    function reserve() external onlyOwner {
        ICryptoProsciuttiDiParma(cryptoProsciuttiDiParma).mint(msg.sender, NUMBER_PROSCIUTTI_DI_PARMA_PER_RESERVATON);
    }
}
