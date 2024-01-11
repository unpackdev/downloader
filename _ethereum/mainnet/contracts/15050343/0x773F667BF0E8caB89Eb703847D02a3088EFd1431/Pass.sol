// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract FFPASS is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    // public variables
    uint256 public constant MAX = 500;
    uint256 public unitPrice = 0.001 ether;
    mapping(address => bool) public _freeMintAddresses;
    mapping(address => bool) public _freeMintAddressesMinted;

    // private variables
    bytes32 _root;
    string _tokenURI;

    constructor(bytes32 root, string memory newTokenURI)
        ERC721("FFPass", "FFPASS")
    {
        _root = root;
        _tokenURI = newTokenURI;
    }

    // Private functions
    function price(uint256 _count) private view returns (uint256) {
        return unitPrice * _count;
    }

    function addToFreeMintMinted(address _address) private {
        _freeMintAddressesMinted[_address] = true;
    }

    // Only Owner functions
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        unitPrice = newPrice;
    }

    function updateTokenURI(string memory _newURI) public onlyOwner {
        _tokenURI = _newURI;
    }

    function withdrawAll() public onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function updateMerkleTreeRoot(bytes32 _newRoot) public onlyOwner {
        _root = _newRoot;
    }

    // Public functions
    function mint(uint256 _count, bytes32[] memory proof)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        require(totalSupply() + _count <= MAX, "Not enough left to mint");
        require(totalSupply() < MAX, "Not enough left to mint");
        require(_count <= 10, "Exceeds the max you can mint");

        bool hasFreeMintAvailable = isInFreeMint(proof, msg.sender) &&
            !hasMintedInFreeMint(msg.sender);

        uint256 nftsToPayFor = hasFreeMintAvailable ? _count - 1 : _count;
        require(msg.value >= price(nftsToPayFor), "Value below price");

        for (uint256 x = 0; x < _count; x++) {
            _safeMint(msg.sender, totalSupply());
        }

        if (hasFreeMintAvailable) {
            addToFreeMintMinted(msg.sender);
        }
    }

    function isInFreeMint(bytes32[] memory proof, address leaf)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(proof, _root, keccak256(abi.encodePacked(leaf)));
    }

    function hasMintedInFreeMint(address _address) public view returns (bool) {
        return _freeMintAddressesMinted[_address];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string.concat(_tokenURI, Strings.toString(tokenId));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
