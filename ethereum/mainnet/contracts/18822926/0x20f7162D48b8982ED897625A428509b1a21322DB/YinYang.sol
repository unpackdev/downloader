// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: @yungwknd
/// @artist: Molly McCutcheon

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Holder.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract YinYang is ERC721, ERC721Enumerable, ERC721Burnable, ERC721Holder, Ownable {
    uint public cost = 0.44 ether;
    mapping(uint => string) public tokenURIs;
    mapping(uint => uint) public pairs;
    string public placeHolderURI = "";
    bool public publicSale = false;
    uint public saleMints = 0;
    bytes32 public merkleRoot;
    uint public nextToken = 0;

    constructor() ERC721("YinYang", "YY") Ownable(_msgSender()) {}

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setTokenURIs(string[] memory uris, uint[] memory tokenIds) public onlyOwner {
        require(uris.length == tokenIds.length, "Lengths don't match");
        for (uint i = 0; i < uris.length; i++) {
            tokenURIs[tokenIds[i]] = uris[i];
        }
    }

    function configure(bool _publicSale, uint _cost, string memory _placeHolderURI, bytes32 _merkleRoot) public onlyOwner {
        publicSale = _publicSale;
        cost = _cost;
        placeHolderURI = _placeHolderURI;
        merkleRoot = _merkleRoot;
    }

    function isAllowlisted(bytes32[] memory proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function mint(bytes32[] memory proof) public payable {
        require(msg.value == cost, "Not enough ETH");
        require(publicSale || isAllowlisted(proof), "Not on allowlist");
        require(saleMints < 17, "No more tokens");
        _safeMint(msg.sender, nextToken);
        nextToken++;
        saleMints++;
    }

    function ownerMint(address to) public onlyOwner {
        _safeMint(to, nextToken);
        nextToken++;
        saleMints++;
    }

    function setPairs(uint[] memory tokenIds) public onlyOwner {
        for (uint i = 0; i < tokenIds.length; i+= 2) {
            pairs[tokenIds[i]] = tokenIds[i + 1];
            pairs[tokenIds[i+1]] = tokenIds[i];
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return bytes(tokenURIs[tokenId]).length > 0 ? tokenURIs[tokenId] : placeHolderURI;
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function onERC721Received(
        address,
        address from,
        uint256 id,
        bytes memory
    ) public override returns(bytes4) {
        // If it's the first token in the pair, just hold it in the contract
        uint pairToken = pairs[id];

        if (ownerOf(pairToken) != address(this)) {
            return this.onERC721Received.selector;
        } else {
            burn(id);
            burn(pairToken);
            // If it's the second token in the pair, mint the complete token and burn both
            _safeMint(from, nextToken);
            nextToken++;
        }

        return this.onERC721Received.selector;
    }

    function recover(uint256 tokenId, address destination) public onlyOwner {
        IERC721(address(this)).transferFrom(address(this), destination, tokenId);
    }

    function withdraw(address receiver) public onlyOwner() {
        payable(receiver).transfer(address(this).balance);
    }
}