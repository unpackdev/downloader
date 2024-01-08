// contracts/Culties.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Culties is ERC721, Ownable {
    using SafeMath for uint256;
    uint public constant MAX_CULTIES = 10000;
    bool public hasSaleStarted = true;

    string public METADATA_PROVENANCE_HASH = "";

    constructor(string memory baseURI) ERC721("Culties","CULTIES")  {
        setBaseURI(baseURI);
        _safeMint(owner(), 0);
        _safeMint(owner(), 1);
        _safeMint(owner(), 2);
        _safeMint(owner(), 3);
        _safeMint(owner(), 4);
        _safeMint(owner(), 5);
        _safeMint(owner(), 6);
        _safeMint(owner(), 7);
        _safeMint(owner(), 8);
        _safeMint(owner(), 9);
        _safeMint(owner(), 10);
        _safeMint(owner(), 11);
        _safeMint(owner(), 12);
        _safeMint(owner(), 13);
        _safeMint(owner(), 14);
        _safeMint(owner(), 15);
        _safeMint(owner(), 16);
        _safeMint(owner(), 17);
        _safeMint(owner(), 18);
        _safeMint(owner(), 19);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale has not started");
        require(totalSupply() < MAX_CULTIES, "Sale has already ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 9900) {
            return 640000000000000000;
        } else if (currentSupply >= 9500) {
            return 320000000000000000;
        } else if (currentSupply >= 7500) {
            return 160000000000000000;
        } else if (currentSupply >= 3500) {
            return 80000000000000000;
        } else if (currentSupply >= 1500) {
            return 40000000000000000;
        } else if (currentSupply >= 500) {
            return 20000000000000000;
        } else {
            return 10000000000000000;
        }
    }

    function calculatePriceForToken(uint _id) public pure returns (uint256) {
        require(_id < MAX_CULTIES, "Sale has already ended");

        if (_id >= 9900) {
            return 640000000000000000;
        } else if (_id >= 9500) {
            return 320000000000000000;
        } else if (_id >= 7500) {
            return 160000000000000000;
        } else if (_id >= 3500) {
            return 80000000000000000;
        } else if (_id >= 1500) {
            return 40000000000000000;
        } else if (_id >= 500) {
            return 20000000000000000;
        } else {
            return 10000000000000000;
        }
    }

   function adopt(uint256 numCulties) public payable {
        require(totalSupply() < MAX_CULTIES, "Sale has already ended");
        require(numCulties > 0 && numCulties <= 50, "You can adopt minimum 1, maximum 50 Culties");
        require(totalSupply().add(numCulties) <= MAX_CULTIES, "Exceeds MAX_CULTIES");
        require(msg.value >= calculatePrice().mul(numCulties), "Ether value sent is below the price");

        for (uint i = 0; i < numCulties; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}
