// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract BeeverseErc721 is ERC721, Ownable {
    using Strings for uint256;

    string public baseURI;
    mapping(address => bool) public minter;

    event SetMinter(address indexed minter, bool status);

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    modifier onlyMinter() {
        require(minter[msg.sender] || owner() == msg.sender, 'ERC721: caller is not owner or minter.');
        _;
    }

    function setMinter(address _minter, bool _status) external onlyOwner {
        minter[_minter] = _status;
        emit SetMinter(_minter, _status);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        super._requireMinted(_tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), '.json')) : '';
    }

    function mint(address _to, uint256 _tokenId) external onlyMinter {
        super._safeMint(_to, _tokenId);
    }

    function burn(uint256 _tokenId) external {
        require(super._isApprovedOrOwner(msg.sender, _tokenId), 'ERC721: caller is not token owner or approved.');
        super._burn(_tokenId);
    }
}
