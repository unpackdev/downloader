//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Moondoge is ERC721A, Ownable, ReentrancyGuard {
    uint256 public publicMaxMint;
    uint256 public immutable maxSupply;
    uint256 public price;
    uint256 public FreeMintLimit;
    string public baseURI;
    event Minted(address minter, uint256 amount);

    enum Status {
        NotActive,
        PublicSale,
        Done
    }

    Status public status;

    constructor() ERC721A("Moondoge", "MOONDOGE") {
        publicMaxMint = 15;
        maxSupply = 9999;
        price = 0.01 * 10**18; // 0.01ETH
        status = Status.PublicSale;
        FreeMintLimit = 1500;
        baseURI = "ipfs://Qmem3Jof6dZkrkVqSgpzJRyDT7R6sAYZfTs2MrgqFoh4aa/";
    }

    function withdraw() external nonReentrant onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function publicSale(uint256 amount) external payable nonReentrant {
        require(status == Status.PublicSale, "Sale is not active.");
        require(!Address.isContract(msg.sender), "Contracts are not allowed.");
        require(
            amount <= publicMaxMint,
            "Amount should not exceed max mint number per transaction."
        );
        require(
            totalSupply() + amount <= maxSupply,
            "Amount should not exceed max supply."
        );


        if (totalSupply() + amount <= FreeMintLimit) {
            _safeMint(msg.sender, amount);
            emit Minted(msg.sender, amount);
        }
        else{
            require(msg.value >= price * amount, "Ether value sent is incorrect.");
            _safeMint(msg.sender, amount);
            emit Minted(msg.sender, amount);
        }
    }

    // URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setFreeMintLimit(uint256 limit) external onlyOwner {
        FreeMintLimit = limit;
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function updateMaxmint(uint256 __max) public onlyOwner {
        publicMaxMint = __max;
    }
}
