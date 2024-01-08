// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CoolShit is Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    uint constant public MAX_PURCHASE = 11;
    uint constant public MAX_NUM_OF_COOL_SHIT = 1001;
    uint256 constant public COOL_SHIT_PRICE = 0.02 ether;

    uint public coolShitReserveForTeam = 11;

    string public provenance;
    string public baseUri;
    bool public saleIsActive = false;

    constructor(
        string memory uri
    ) ERC721("CoolShit", "CS") {
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function reserveCoolShit() public onlyOwner {
        uint256 total = totalSupply();
        for (uint i = 1; i <= coolShitReserveForTeam; i++) {
            _safeMint(msg.sender, total + i);
        }
    }

    function mintCoolShit(uint numOfTags) public payable {
        require(saleIsActive, "Sale is not active");
        require(numOfTags > 0, "Must at least mint 1 tag");
        require(numOfTags < MAX_PURCHASE, "Cannot mint more than 30 tags at once");
        uint256 total = totalSupply();

        require(total.add(numOfTags) < MAX_NUM_OF_COOL_SHIT, "Cannot exceed max number of tags");
        require(COOL_SHIT_PRICE.mul(numOfTags) == msg.value, "Ether value sent is not correct");

        for (uint i = 1;
            i <= numOfTags;
            i++) {
            require((total + i) < MAX_NUM_OF_COOL_SHIT, "Cannot exceed max supply");

            if (!_exists(total + i)) {
                _safeMint(msg.sender, total + i);
            }
        }
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseUri = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
}
