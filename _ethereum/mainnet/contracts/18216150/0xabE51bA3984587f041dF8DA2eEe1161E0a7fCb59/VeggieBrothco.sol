// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";

contract veggiebrothko is ERC721A, Ownable {
    error MintClosed();
    error ExceedsSupply();
    error InvalidAmount();
    error InvalidValue();
    error MismatchedLengths();
    error NoContracts();

    uint256 public maxSupply = 666;
    uint256 public mintPrice = .001 ether;
    uint256 public maxPerTx = 5;
    uint256 public constant MAX_FREE = 101;
    string public baseURI;
    bool public isMintOpen = false;
    mapping(address => bool) public hasAddressMinted;

    constructor() payable ERC721A("veggie brothko", "vggbrko") {
        _mint(msg.sender, 1);
    }

    function mint(uint256 _amount) external payable {
        if (msg.sender != tx.origin) revert NoContracts();
        if (!isMintOpen) revert MintClosed();
        if (_amount > maxPerTx) revert InvalidAmount();
        unchecked {
            if (_totalMinted() + _amount > maxSupply) revert ExceedsSupply();
            if (
                hasAddressMinted[msg.sender] == false &&
                _totalMinted() + 1 < MAX_FREE
            ) {
                if (msg.value != mintPrice * (_amount - 1))
                    revert InvalidValue();
                hasAddressMinted[msg.sender] = true;
            } else {
                if (msg.value != mintPrice * _amount) revert InvalidValue();
            }
        }
        _mint(msg.sender, _amount);
    }

    function airdrop(address[] memory _receivers, uint256[] memory _amounts)
        external
        onlyOwner
    {
        uint256 length = _receivers.length;
        if (length != _amounts.length) revert MismatchedLengths();
        for (uint256 i = 0; i < length; ) {
            _mint(_receivers[i], _amounts[i]);
            unchecked {
                ++i;
            }
        }
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

    function setBaseURI(string calldata _URI) external onlyOwner {
        baseURI = _URI;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMintOpen() external onlyOwner {
        isMintOpen = !isMintOpen;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
