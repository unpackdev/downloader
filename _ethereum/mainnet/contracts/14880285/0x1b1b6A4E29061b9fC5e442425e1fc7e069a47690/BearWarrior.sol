//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract BearWarrior is ERC721A, Ownable {

    using ECDSA for bytes32;

    enum SalePhase {
        Locked,
        PublicSale
    }

    SalePhase public phase = SalePhase.Locked;

    uint256 public publicPrice = 0.02 ether;
    uint256 public maxWarriors = 3333;

    uint public constant MAX_PUBLIC_MINT = 10;

    string private baseURI = "https://api.warriorsnft.io/contract/bear/tokens/";

    mapping(address => uint) public tokensMinted;

    constructor(
        uint256 max
    ) ERC721A("Bear Warriors", "BEARWAR") {
        maxWarriors = max;
    }

    // Mints for promotional purposes and founding team/investors
    function reserveMint() public onlyOwner {
        require(totalSupply() == 0, 'PROMO_RUN');
        _safeMint(0x96B0AdfFb0A4dc97166ffaC92899927D5034e095, 50);
    }

    function publicMint(uint256 numTokens) public payable {
        require(phase == SalePhase.PublicSale, 'Public sale is not active');
        require(msg.value == numTokens * publicPrice, 'Incorrect ether amount');
        require(numTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase per transaction");
        require(totalSupply() + numTokens <= maxWarriors, 'MAX_REACHED');
        _safeMint(msg.sender, numTokens);
    }

    function setPhase(SalePhase phase_) external onlyOwner {
        phase = phase_;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMax(uint256 _max) public onlyOwner {
        require(_max > maxWarriors, 'TOO_LOW');
        maxWarriors = _max;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.warriorsnft.io/contract/bear/meta";
    }
}
