// SPDX-License-Identifier: UNLICENSED

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

pragma solidity ^0.8.0;

contract GeomesToken is ERC721Enumerable, Ownable {
    uint256 public constant MAX = 2000;
    uint256 public constant price = 0.02 ether;

    mapping(uint256 => uint256) public creationDates;

    // will be set after the sale ends
    string public _generatorBaseURI;
    string private _metadataBaseURI;

    constructor() ERC721('Geomes', 'GEOM') {
        string memory chainIdSuffix = block.chainid == 1
            ? ''
            : string(abi.encodePacked(Strings.toString(block.chainid), '/'));
        _metadataBaseURI = string(
            abi.encodePacked('https://codemakes.art/api/token/', chainIdSuffix)
        );

        for (uint256 i = 1; i <= 20; i++) {
            creationDates[i] = block.number;
            _safeMint(msg.sender, i);
        }
    }

    function mint(uint256 count) public payable {
        require(totalSupply() < MAX, 'Sale has already ended');
        require(count > 0 && count <= 20, 'Can mint 1..20');
        require(totalSupply() + count <= MAX, 'Not enough left');
        require(msg.value >= price * count, 'Not enough ether');

        for (uint256 i = 0; i < count; i++) {
            uint256 mintIndex = totalSupply() + 1;
            creationDates[mintIndex] = block.number;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function tokenHash(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), 'nonexistent token');
        return
            keccak256(
                abi.encodePacked(address(this), creationDates[tokenId], tokenId)
            );
    }

    function tokenGeneratorURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), 'nonexistent token');
        return
            string(
                abi.encodePacked(
                    _generatorBaseURI,
                    '?id=',
                    Strings.toString(tokenId),
                    '&hash=',
                    Strings.toHexString(uint256(tokenHash(tokenId)))
                )
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _metadataBaseURI;
    }

    function setGeneratorBaseURI(string memory uri) public onlyOwner {
        _generatorBaseURI = uri;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _metadataBaseURI = baseURI;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
