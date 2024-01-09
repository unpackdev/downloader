// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Expand.sol";

contract SOS is ERC721Expand, Ownable, ReentrancyGuard {

    string public baseURI;
    uint256 public constant PRICE = 0.0088 * 10**18; // 0.0088 ETH
    uint256 public maxMint;

    event Minted(address minter, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    constructor(
        string memory initBaseURI,
        uint256 _maxBatchSize,
        uint256 _collectionSize
    ) ERC721Expand("Story Of Seassor", "SOS", _maxBatchSize, _collectionSize)
    {
        baseURI = initBaseURI;
        maxMint = _maxBatchSize;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 amount) external payable {
        require(
            tx.origin == msg.sender,
            "SOS: contract is not allowed to mint."
        );
        require(
            numberMinted(msg.sender) + amount <= maxMint,
            "SOS: Max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + amount <= collectionSize,
            "SOS: Max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        refundIfOver(PRICE * amount);

        emit Minted(msg.sender, amount);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "SOS: Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function withdraw() external nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(0x5B76247E1fa700107D3eaF5ad4dE09D0Aca611bC)
            .call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address account) public view returns (uint256) {
        return _numberMinted(account);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}
