// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract KarmaChameleons is Ownable, ERC721A {
    using Strings for uint256;

    uint256 public price = 0.042 ether;
    uint256 public constant whalePrice = 5.52 ether;
    uint64 public maxPerWallet = 10;
    uint64 public maxSupply = 3149;
    uint64 public constant whaleOrder = 69;

    string private baseURI;
    mapping(address => uint256) public minted;

    constructor() ERC721A("KarmaChameleons", "CHAMELEON") {}

    function mint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        require(tx.origin == _msgSender(), "No contracts");
        if (quantity == whaleOrder) {
            require(msg.value >= whalePrice, "Incorrect ETH amount");
        } else {
            require(
                quantity + minted[msg.sender] <= maxPerWallet,
                "Exceeded per wallet limit"
            );
            require(msg.value >= quantity * price, "Incorrect ETH amount");
            minted[msg.sender] += quantity;
        }
        _mint(msg.sender, quantity);
    }

    function setBaseURI(string calldata data) external onlyOwner {
        baseURI = data;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerWallet(uint64 limit) external onlyOwner {
        maxPerWallet = limit;
    }

    function setMaxSupply(uint64 newSupply) external onlyOwner {
        require(
            newSupply > totalSupply(),
            "New max suppy should be higher than current number of minted tokens"
        );
        maxSupply = newSupply;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
