// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC721A.sol";
import "./Ownable.sol";

contract BarelyApepens is ERC721A, Ownable {
    uint256 public maxSupply = 444;
    uint256 public cost = 0.0025 ether;
    uint256 public maxPerTx = 4;
    string public baseURI;
    bool public sale;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor(string memory _initURI) payable ERC721A("Barely Apepens", "BAP") {
        baseURI = _initURI;
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < cost * _amount) revert NotEnoughETH();

        _mint(msg.sender, _amount);
    }

    function reserveMint(address _to, uint256 _amount) external onlyOwner {
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function toggleSale() external onlyOwner {
        sale = !sale;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
