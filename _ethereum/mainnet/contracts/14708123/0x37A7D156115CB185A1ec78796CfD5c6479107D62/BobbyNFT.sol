// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract BobbyBuyBot is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    /// Provenance gained by 1) sha256 of each image. 2) A sha256 of the 5000 hashes as one string.
    string public BOBBY_PROVENANCE = "1b8e996a9821b9a3eedc801d9d9ac1e0e8de1dd797f7f589ccacf08e90d6ce83";
    uint256 public constant bobbyPrice = 100000000000000000; //0.1 ETH
    uint public constant maxBobbyPurchase = 20;
    uint96 public MAX_BOBBYS;
    bool public saleIsActive = false;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    string private _baseTokenURI;

    constructor(uint96 maxNftSupply, uint numberToReserve) ERC721("BobbyBuyBot", "Bobby") {
        MAX_BOBBYS = maxNftSupply;
        reserveBobbys(numberToReserve);
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function reserveBobbys(uint numberToMint) public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < numberToMint; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    function mintBobby(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Bobby");
        require(numberOfTokens <= maxBobbyPurchase, "Can only mint up to 20 Bobbys at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_BOBBYS, "Purchase would exceed max supply of Bobbys");
        require(bobbyPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_BOBBYS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }   
}