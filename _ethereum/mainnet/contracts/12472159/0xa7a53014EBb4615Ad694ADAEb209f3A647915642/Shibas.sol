// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721EnumerableNew.sol";

contract Shibas is ERC721EnumerableNew, Ownable {
    // Maximum amount of Shibas in existance. Ever.
    uint public constant MAX_SHIBA_SUPPLY = 1000;

    // The provenance hash of all Shibas. (Root hash of all 1000 Shiba properties hashes concatenated)
    string public constant METADATA_PROVENANCE_HASH =
        "a860602523bb2225a9bb3f4a29e2459338ea5f1785fe5b5f6b61114f4dfd3f3f";

    // Sale switch.
    bool public hasSaleStarted = false;

    // Base URI of Shiba's metadata
    string private baseURI;

    constructor() ERC721("Shiba", "SHIBA") {}

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0); // Return an empty array
        } else {
            uint[] memory result = new uint[](tokenCount);
            for (uint index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function calculatePrice() public view returns (uint) {
        require(hasSaleStarted, "Sale hasn't started");
        return calculatePriceForToken(totalSupply());
    }

    function calculatePriceForToken(uint _id) public pure returns (uint) {
        require(_id < MAX_SHIBA_SUPPLY, "Sale has already ended");

        if (_id >= 900) {
            return 1 ether; //    900-1000: 1.00 ETH
        } else if (_id >= 800) {
            return 0.64 ether; // 800-900:  0.64 ETH
        } else if (_id >= 600) {
            return 0.32 ether; // 600-800:  0.32 ETH
        } else if (_id >= 400) {
            return 0.16 ether; // 400-600:  0.16 ETH
        } else if (_id >= 200) {
            return 0.08 ether; // 200-400:  0.08 ETH
        } else if (_id >= 100) {
            return 0.04 ether; // 100-200:   0.04 ETH
        } else {
            return 0.02 ether; // 0 - 100     0.02 ETH
        }
    }

    function adoptShibas(uint numShibas) public payable {
        uint _totalSupply = totalSupply();
        require(_totalSupply < MAX_SHIBA_SUPPLY, "Sale has already ended");
        require(_totalSupply + numShibas <= MAX_SHIBA_SUPPLY, "Exceeds maximum Shiba supply");
        require(numShibas > 0 && numShibas <= 20, "You can adopt minimum 1, maximum 20 shibas");
        require(msg.value >= calculatePrice() * numShibas, "Ether value sent is below the price");

        for (uint i = 0; i < numShibas; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        baseURI = __baseURI;
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

    // #0 - #10: Reserved for giveaways and people who helped along the way
    function reserveGiveaway(uint numShibas) public onlyOwner {
        uint currentSupply = totalSupply();
        require(currentSupply + numShibas <= 20, "Exceeded giveaway limit");
        for (uint index = 0; index < numShibas; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@  @@@@@@@@@@@@@@@@  @@@@@@@@@@@
// @@@@@@@@ @@ @ @@       @ @ @@ @@@@@@@@@@
// @@@@@@ @@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@
// @@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@
// @@@@ @@@@@@@  @@@@@@@@@  @@@@@@@ @@@@@@@
// @@@@ @@@@@@@@@@@@@   @@@@@@@@@@@ @@@@@@@
// @@@@@ @@@@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@
// @@@@@@ @@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@
// @@@@@@@   @@@@@@@@@@@@@@@@@   @@@@@@@@@@
// @@@@@@@@@@ @@@@@@@@@@@@@@@ @@@@@@@@@@@@@
// @@@@@@@@@ @@@@@ @ @@ @ @@@@ @@@ @ @@@@@@
// @@@@@@@@ @@@@@@ @ @@ @ @@@@@ @@ @@ @@@@@
// @@@@@@ @@@@@@@@ @ @@ @ @@@@@@@ @@ @@@@@@
// @@@@@     @@@@ @@@  @@@ @@@     @@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@