//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheOthersideDAO is ERC721A, Ownable {
    uint256 public publicMaxMint = 10;
    uint256 public maxSupply = 2000;
    uint256 public price = 0.005 * 10**18;
    string public baseURI =
        "ipfs://QmUNpot4zLXJo2SQLdNreHabtHuajhy6hvgK4hvX5t4yQn/";

    uint256 public startTime = 1651590900;

    constructor() ERC721A("TheOthersideDAO", "TOD") {}

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function devMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(block.timestamp >= startTime, "Sale is not active.");
        require(
            amount <= publicMaxMint,
            "Amount should not exceed max mint number per transaction."
        );
        require(
            totalSupply() + amount <= maxSupply,
            "Amount should not exceed max supply."
        );

        if (numberMinted(msg.sender) == 0)
            require(
                msg.value >= price * (amount - 1),
                "Ether value sent is incorrect."
            );
        else
            require(
                msg.value >= price * amount,
                "Ether value sent is incorrect."
            );

        _safeMint(msg.sender, amount);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function updateSupply(uint256 __supply) public onlyOwner {
        maxSupply = __supply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setTime(uint256 time) external onlyOwner {
        startTime = time;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
}
