// SPDX-License-Identifier: MIT

/* 

██████╗░███████╗██████╗░░█████╗░░█████╗░██████╗░██╗███████╗░██████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║██╔════╝██╔════╝
██████╔╝█████╗░░██████╔╝██║░░██║██║░░██║██║░░██║██║█████╗░░╚█████╗░
██╔═══╝░██╔══╝░░██╔═══╝░██║░░██║██║░░██║██║░░██║██║██╔══╝░░░╚═══██╗
██║░░░░░███████╗██║░░░░░╚█████╔╝╚█████╔╝██████╔╝██║███████╗██████╔╝
╚═╝░░░░░╚══════╝╚═╝░░░░░░╚════╝░░╚════╝░╚═════╝░╚═╝╚══════╝╚═════╝░

*/

pragma solidity ^0.8.19;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Pepoodies is ERC721A, Ownable {

    uint256 public maxSupply = 1000;
    uint256 public mintPrice = .001 ether;
    uint256 public maxPerTx = 5;
    string public baseURI;
    bool public sale;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error InsufficientFunds();

    constructor(string memory _initBaseURI)
        payable
        ERC721A("Pepoodies", "PEPO")
    {
        baseURI = _initBaseURI;
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < mintPrice * _amount) revert InsufficientFunds();

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

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
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