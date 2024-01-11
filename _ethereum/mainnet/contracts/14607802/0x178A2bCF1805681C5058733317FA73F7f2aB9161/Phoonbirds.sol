// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Strings.sol";
import "ERC721.sol";
import "Ownable.sol";

contract Phoonbirds is ERC721, Ownable {
    using Strings for uint256;

    string private _tokenBaseURI =
        "https://gateway.pinata.cloud/ipfs/QmW1sgPHDoGcuGVx6pSU5o4fhsZ23fmU3b9k6iNZ9QSuZ8/";
    uint256 public tokenCounter;
    uint256 public PHOONBIRD_PRICE = 0.01 ether;
    bool public mintLive;

    constructor() ERC721("Phoonbirds", "PHB") {
        tokenCounter = 0;
        mintLive = false;
    }

    function mint(uint256 tokenQuantity) external payable {
        require(mintLive, "MINT_CLOSED");
        require(tokenCounter + tokenQuantity <= 9947, "EXCEED_MAX");
        require(
            PHOONBIRD_PRICE * tokenQuantity <= msg.value,
            "INSUFFICIENT_ETH"
        );

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, tokenCounter);
            tokenCounter++;
        }
    }

    function toggleMint() external onlyOwner {
        mintLive = !mintLive;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _tokenBaseURI,
                    "phoonbird_",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter;
    }
}
