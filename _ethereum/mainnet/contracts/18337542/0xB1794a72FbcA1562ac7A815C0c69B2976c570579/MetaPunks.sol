// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MetaPunks is ERC721A, Ownable {
    uint256 public maxSupply = 879;
    uint256 public mintPrice = .002 ether;
    uint256 public maxPerTx = 5;
    uint256 public maxFree = 1;
    uint256 public maxFreeMint = 200;
    uint256 public freeMintCounter = 0;
    string public baseURI = "ipfs://QmSrHxYARoj1NQJB16xtc1vUqQWWkJyFP4nwwtLJiTxQ8m/";
    bool public sale;
    mapping(address => uint256) public mintedFreeAmount;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error InsufficientFunds();
    error FreeLimitReached();

    constructor() payable ERC721A("MetaPunks", "MP") {}

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();

        uint256 _mintPrice = (msg.value == 0 &&
            (mintedFreeAmount[msg.sender] + _amount <= maxFree))
            ? 0
            : mintPrice;

        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < _mintPrice * _amount) revert InsufficientFunds();
        if (_mintPrice == 0 && freeMintCounter >= maxFreeMint) revert FreeLimitReached();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyReached();

        if (_mintPrice == 0) {
            mintedFreeAmount[msg.sender] += _amount;
            freeMintCounter++;
        }

        _safeMint(msg.sender, _amount);
    }

    function airdrop(address _receiver, uint256 _amount) external onlyOwner {
        _mint(_receiver, _amount);
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

    function setBaseURI(string calldata _newBaseTokenURI) external onlyOwner {
        baseURI = _newBaseTokenURI;
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

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxFree(uint256 _maxFree) external onlyOwner {
        maxFree = _maxFree;
    }

    function setMaxFreeMint(uint256 _maxFreeMint) external onlyOwner {
        maxFreeMint = _maxFreeMint;
    }

    function toggleSale() external onlyOwner {
        sale = !sale;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
