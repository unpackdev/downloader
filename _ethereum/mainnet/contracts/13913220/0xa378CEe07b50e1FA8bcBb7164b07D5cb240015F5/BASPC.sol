// SPDX-License-Identifier: AGPL-3.0-only
import {Trust} from "Trust.sol";
import {SolmateERC721} from "SolmateERC721.sol";

pragma solidity >=0.8.0;

contract BASPC is SolmateERC721, Trust {
    uint256 immutable PRICE = 0.05e18;
    uint256 immutable MAX_SUPPLY = 10000;

    constructor(
        string memory _baseURI
    ) SolmateERC721("Bored Ape Seed Phrase Club", "BASPC", _baseURI) Trust(msg.sender) {
        return;
    }

    function mint(uint256 numMint) public payable {
        require(msg.value >= numMint * PRICE, "BASPC: Insufficient Funds");
        require(numMint + totalSupply <= MAX_SUPPLY, "BASPC: Out of Stock");
        for (uint256 i = 0; i < numMint; i += 1) {
            _mint(msg.sender, totalSupply);
        }
    }

    function setBaseURI(string memory newBaseURI) public requiresTrust {
        baseURI = newBaseURI;
    }

    function withdrawAll() public requiresTrust {
        payable(msg.sender).transfer(address(this).balance);
    }
}
