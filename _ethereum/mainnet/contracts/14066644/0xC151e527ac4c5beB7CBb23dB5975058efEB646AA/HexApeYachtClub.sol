// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

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
        string memory uri = string(
            abi.encodePacked(
                "https://gateway.pinata.cloud/ipfs/QmWRFZvdByMYhHLmDC9J9kWSXqZj9LmCFo4AyVNvBMaQGe/",
                Strings.toString(tokenId+1),
                ".png"
            )
        );
        return uri;
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
