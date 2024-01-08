//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract BoredApeSpaceAgency is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint public fee;
    event PriceUpdated(uint newPrice);
    bool public isSaleHalted;
    string private baseURI;

    constructor() ERC721("BoredApeSpaceAgency", "BASA") {
        fee = 40000000000000000 wei; //0.04 ETH
        baseURI = "https://gateway.pinata.cloud/ipfs/QmPhKVsyP7EBtomrxqemoTG51K2wfFwCb2SGkGFahEyHPF/";
        isSaleHalted = false;
    }

    function mintNFT(uint numberOfMints) public payable{
        require(!isSaleHalted, "Sale must be active to mint a BASA Token.");	
        require(_tokenIds.current() + numberOfMints <= 1000, "Maximum amount of BASA Tokens already minted.");
        require(msg.value >= fee * numberOfMints, "Fee is not correct.");
        require(numberOfMints <= 20, "You can only mint a maximum of 20 BASA Tokens at once.");

        for(uint i = 0; i < numberOfMints; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function toggleSaleState() public onlyOwner {
        isSaleHalted = !isSaleHalted;
    }

    function updateFee(uint newFee) public onlyOwner{
       fee = newFee;
       emit PriceUpdated(newFee);
    }

    function getFee() public view returns (uint) {
       return fee;
    }

    function getCurrentTokenId() public view returns (uint) {
        return _tokenIds.current();
    }

    function withdraw() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function totalSupply() public pure override returns (uint) {
       return 1000;
    }

}
