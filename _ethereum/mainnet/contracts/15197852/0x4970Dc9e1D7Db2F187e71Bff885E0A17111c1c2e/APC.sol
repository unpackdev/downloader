// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Strings.sol";
import "ERC721.sol";
import "Ownable.sol";

contract AlienPartyClub is ERC721, Ownable {
    using Strings for uint256;

    string private _tokenBaseURI =
        "https://bafybeifta34rvuqrzahu53b3gelszk4aaobl2z4v3bjfzbcijbai3sa5di.ipfs.nftstorage.link/";
    uint256 public tokenCounter;
    uint256 public TICKET_PRICE = 0.1 ether;
    bool public mintLive;

    constructor() ERC721("AlienPartyClub", "APC") {
        tokenCounter = 0;
        mintLive = false;
    }

    function mint(uint256 tokenQuantity) external payable {
        require(mintLive, "MINT_CLOSED");
        require(tokenCounter + tokenQuantity <= 10000, "EXCEED_MAX");
        require(TICKET_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");

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
                    "apc_",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter;
    }
}
