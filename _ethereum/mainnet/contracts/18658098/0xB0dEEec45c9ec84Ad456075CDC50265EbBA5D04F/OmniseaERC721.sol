// SPDX-License-Identifier: MIT
// omnisea-contracts v0.1

pragma solidity ^0.8.7;

import "./IOmniseaERC721.sol";
import "./ERC721.sol";
import "./IOmniseaPortal.sol";
import "./Strings.sol";
import "./ERC721Structs.sol";


contract OmniseaERC721 is IOmniseaERC721, ERC721 {
    using Strings for uint256;

    IOmniseaPortal public omniseaPortal;
    bytes32 public omniseaId;
    address public owner;
    string internal _contractURI;
    mapping(uint256 => string) public tokenURIs;
    uint256 public override totalSupply;
    bool private isInitialized;

    function initialize(BasicCollectionParams memory params, bytes32 _collectionId) external {
        require(!isInitialized);
        _init(params.name, params.symbol);
        isInitialized = true;
        omniseaPortal = IOmniseaPortal(msg.sender);
        owner = params.owner;
        _contractURI = params.uri;
        omniseaId = _collectionId;
    }

    function name() public view override(IOmniseaERC721, ERC721) returns (string memory) {
        return super.name();
    }

    function symbol() public view override(IOmniseaERC721, ERC721) returns (string memory) {
        return super.symbol();
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(IOmniseaERC721, ERC721) returns (string memory) {
        return tokenURIs[tokenId];
    }

    function mint(address _owner, uint256 _tokenId, string memory _tokenURI) override external {
        require(msg.sender == address(omniseaPortal));
        tokenURIs[_tokenId] = _tokenURI;
        _mint(_owner, _tokenId);
        unchecked {
            totalSupply++;
        }
    }

    function burn(uint256 _tokenId) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _burn(_tokenId);
        delete tokenURIs[_tokenId];
        unchecked {
            totalSupply--;
        }
    }

    function circulatingSupply() public view override returns (uint256) {
        return totalSupply - balanceOf(address(omniseaPortal));
    }
}
