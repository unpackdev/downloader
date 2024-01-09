//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract PuppyTakeover is ERC721, Ownable {
    uint16 public rareTokenIds = 1;
    uint16 public exoticTokenIds = 851;
    uint256 public MAX_TOKENS_PER_SALE = 5;
    uint256 public rarePrice = 0.05 ether;
    uint256 public exoticPrice = 0.08 ether;
    string private ipfsBaseURI;
    bool public active = false;

    constructor(string memory _ipfsBaseURI) ERC721("PuppyTakeover", "PUP") {
        ipfsBaseURI = _ipfsBaseURI;
    }

    function toggleMinting() external onlyOwner {
        if (active) {
            active = false;
        } else {
            active = true;
        }
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
                    ipfsBaseURI,
                    "/",
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    function mintTokens(uint256 _amount, uint16 _tokenId)
        internal
        returns (uint16 newTokenId)
    {
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, _tokenId);
            _tokenId++;
        }
        return _tokenId;
    }

    function createCollectible(uint256 _amount, bool _exotic) public payable {
        require(active, "Minting not active!");
        require(
            _amount > 0 && _amount < MAX_TOKENS_PER_SALE + 1,
            string(
                abi.encodePacked(
                    "You can buy max ",
                    Strings.toString(MAX_TOKENS_PER_SALE),
                    " tokens per transaction."
                )
            )
        );
        if (_exotic) {
            require(
                exoticTokenIds + _amount < 1000 + 2,
                "Not enough exotic pups available!"
            );
            require(
                msg.value >= exoticPrice * _amount,
                string(
                    abi.encodePacked(
                        "Not enough ETH! At least ",
                        Strings.toString(exoticPrice * _amount),
                        " wei has to be sent!"
                    )
                )
            );
            exoticTokenIds = mintTokens(_amount, exoticTokenIds);
        } else {
            require(
                rareTokenIds + _amount < 850 + 2,
                "Not enough rare pups available!"
            );
            require(
                msg.value >= rarePrice * _amount,
                string(
                    abi.encodePacked(
                        "Not enough ETH! At least ",
                        Strings.toString(rarePrice * _amount),
                        " wei has to be sent!"
                    )
                )
            );
            rareTokenIds = mintTokens(_amount, rareTokenIds);
        }
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Paying for minting failed!");
    }
}
