// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";

contract Robotbird is Ownable, ERC721A, ERC721AQueryable {
    // ----------------- MODIFIERS -----------------
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ----------------- VARAIBLES -----------------
    uint256 public immutable mintStartTime;
    uint256 public constant freePerWallet = 4;
    uint256 public constant maxBatchNumber = 10;
    uint256 public constant maxFreeNumber = 6666;
    uint256 public constant maxMintNumber = 10000;
    uint256 public constant maxDevMintNumber = 200;
    uint256 public publicPrice = 0.0066 ether;

    mapping(address => uint256) public freeMints;

    constructor(uint256 _mintStartTime) ERC721A("Robotbird", "RBD") {
        mintStartTime = _mintStartTime;
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(
            block.timestamp >= mintStartTime,
            "Robotbird: Mint is not started"
        );
        require(
            quantity + totalSupply() <= maxMintNumber,
            "Robotbird: Maximum mint quantity reached"
        );
        if (totalSupply() + quantity <= maxFreeNumber) {
            // free mint
            require(msg.value == 0, "Robotbird: Wrong ETH amount");
            require(
                freeMints[msg.sender] + quantity <= freePerWallet,
                "Robotbird: Max free mint per wallet exceeded"
            );
            freeMints[msg.sender] += quantity;
        } else {
            // paid mint
            require(
                msg.value == publicPrice * quantity,
                "Robotbird: Wrong ETH amount"
            );
            require(
                quantity <= maxBatchNumber,
                "Robotbird: Per TX limit exceeded"
            );
        }
        _mint(msg.sender, quantity);
    }

    function setNewPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function devMint() external onlyOwner {
        _mint(msg.sender, maxDevMintNumber);
    }
}
