// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ACIDAPESbyLORS is ERC721A, Ownable {
    uint256 public maxSupply = 200;
    uint256 public mintPrice = .01 ether;
    uint256 public maxPerTx = 2;
    string public baseURI;
    bool public sale;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor(string memory baseURI_)
        payable
        ERC721A("ACID APES by LORS", "ACDAPES")
    {
        baseURI = baseURI_;
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < mintPrice * _amount) revert NotEnoughETH();

        _mint(msg.sender, _amount);
    }

    function airdrop(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function toggleSale() external onlyOwner {
        sale = !sale;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
