//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract MurderedApesCanoeClub is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    uint256 public maxTokens = 1000;
    uint256 public maxTokensPerTx = 5;
    uint256 public price = 0.025 ether;
    string private baseURI;
    bool public saleActive = false;

    constructor(string memory _ipfsBaseURI)
        ERC721("Murdered Apes Canoe Club Eth Collection", "MACC")
    {
        baseURI = _ipfsBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            string(
                abi.encodePacked(
                    "ipfs://",
                    baseURI,
                    "/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function totalSupply() public view returns (uint256) {
        return tokenIds.current();
    }

    function toggleMinting() public onlyOwner {
        saleActive = !saleActive;
    }

    function createCollectible(uint256 amount) public payable {
        require(saleActive, "Minting new collectibles is paused!");
        require(
            amount > 0 && amount < maxTokensPerTx + 1,
            string(
                abi.encodePacked(
                    "You can buy max ",
                    maxTokensPerTx.toString(),
                    " tokens per transaction."
                )
            )
        );
        require(
            msg.value >= price * amount,
            string(
                abi.encodePacked(
                    "Not enough ETH! At least ",
                    (price * amount).toString(),
                    " wei has to be sent!"
                )
            )
        );
        require(
            maxTokens > amount + tokenIds.current() + 1,
            "All the tokens are sold out!"
        );

        for (uint256 i = 0; i < amount; i++) {
            tokenIds.increment();
            uint256 newItemId = tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }
    }

    function withdrawBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdrawal failed!");
    }
}
