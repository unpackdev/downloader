// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
  ______           _                      
 |  ____|         | |                     
 | |__ ___  _ __  | |    _   _  ___ _   _ 
 |  __/ _ \| '__| | |   | | | |/ __| | | |
 | | | (_) | |    | |___| |_| | (__| |_| |
 |_|  \___/|_|    |______\__,_|\___|\__, |
                                     __/ |
                                    |___/ 
*/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract LucyColorfulFriendsContractE is ERC721A, Ownable, ReentrancyGuard {

    using Address for address;

    string public baseTokenURI = "https://ipfs.io/ipfs/QmYQS1ebqrgaskmU7feXAjubMdrTvtneXWzCuFd6Hi9HWv/";

    uint public mintPrice = 0.0418 ether;
    uint public collectionSize = 300;

    constructor() ERC721A("Lucys Colorful Friends", "LCF") {}

    function publicMint() external payable {
        uint remainder = msg.value % mintPrice;
        require(remainder == 0, "send a divisible amount of eth");

        uint amount = msg.value / mintPrice;

        require(amount > 0, "amount to mint is 0");

        require((totalSupply() + amount) <= collectionSize, "sold out");
        _safeMint(_msgSender(), amount);
    }

    function setMintInfo(uint _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdrawAll() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool success, ) = address(this.owner()).call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId), ".json"));
    }
}