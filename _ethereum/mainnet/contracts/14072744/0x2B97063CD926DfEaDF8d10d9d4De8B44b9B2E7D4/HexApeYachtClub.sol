// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";

contract HexApeYachtClub is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 constant fixedSupply = 10000;
    uint256 constant maxPerAddress = 10;
    uint256 constant minPriceInWei = 20000000000000000; // 0.020 ETH
    
    constructor() ERC721("HexApeYachtClub", "HAYC") Ownable() {}

    /// Token URI
    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        string memory output = string(
            abi.encodePacked(
                "https://gateway.pinata.cloud/ipfs/Qmeh7GWT6tm2wMNSXXHa6VpB4jAZ81gzacTevT7U7pAso3/",
                Strings.toString(tokenId+1),
                ".png"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "HAYC #',
                        Strings.toString(tokenId + 1),
                        '", "description": "The Hex Ape Yacht Club is a collection of 10K unique Hex Ape NFTs, unique digital collectibles living on the Ethereum blockchain. Inspired, but not affiliated with BAYC.", "image": "',
                        output,
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    /// Reserve for Owner
    function reserveForOwner() public onlyOwner returns (uint256) {
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < 50; i++) {
            _safeMint(msg.sender, supply + i);
        }
        return totalSupply();
    }

    /// Mint tokens
    /// @param amount Amount
    function mint(uint256 amount) public payable returns (uint256) {
        uint256 currSupply = totalSupply();
        require(currSupply + amount <= fixedSupply, "Mint already at max supply");
        require(balanceOf(_msgSender()) + amount <= maxPerAddress, "Mint cap exceeded");
        require(
            msg.value >= minPriceInWei * amount,
            "Sent amount too low"
        );
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), currSupply + i);
        }
        return amount;
    }

    /// Withdraw for owner
    function withdraw() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        return true;
    }
}
