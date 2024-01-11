// ███████╗░█████╗░██╗░░██╗███████╗  ███████╗░█████╗░░█████╗░███████╗░██████╗
// ██╔════╝██╔══██╗██║░██╔╝██╔════╝  ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
// █████╗░░███████║█████═╝░█████╗░░  █████╗░░███████║██║░░╚═╝█████╗░░╚█████╗░
// ██╔══╝░░██╔══██║██╔═██╗░██╔══╝░░  ██╔══╝░░██╔══██║██║░░██╗██╔══╝░░░╚═══██╗
// ██║░░░░░██║░░██║██║░╚██╗███████╗  ██║░░░░░██║░░██║╚█████╔╝███████╗██████╔╝
// ╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝  ╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝╚═════╝░

// ███████╗░█████╗░██████╗░  ░██████╗░█████╗░██╗░░░░░███████╗
// ██╔════╝██╔══██╗██╔══██╗  ██╔════╝██╔══██╗██║░░░░░██╔════╝
// █████╗░░██║░░██║██████╔╝  ╚█████╗░███████║██║░░░░░█████╗░░
// ██╔══╝░░██║░░██║██╔══██╗  ░╚═══██╗██╔══██║██║░░░░░██╔══╝░░
// ██║░░░░░╚█████╔╝██║░░██║  ██████╔╝██║░░██║███████╗███████╗
// ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝  ╚═════╝░╚═╝░░╚═╝╚══════╝╚══════╝
//
// FAKE FACES FOR SALE
// Jonathan Dinu (@clearspandex)
// 2022

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./ERC721Royalty.sol";

import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract FakeFaces is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ERC721Burnable,
    ERC721Royalty,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    event PermanentURI(string _value, uint256 indexed _id);

    Counters.Counter private _tokenIdCounter;

    string private constant _placeholder =
        'ipfs://QmXKuLV3DLxUg9wrw11knyFK9KGn9NhxuFETJQwFgeNQGb';
    uint96 private constant _royalty = 10;
    bool private _active = false;
    uint256 private _maxSupply;
    string private _message;

    constructor(uint256 limit, string memory message)
        ERC721('FAKE FACES FOR SALE', 'FFFS')
    {
        _setDefaultRoyalty(owner(), _royalty * 100);
        _maxSupply = limit;
        _message = message;
    }

    function contractURI() public pure returns (string memory) {
        return 'ipfs://QmdfHXKS3saeQMmW9Ga4CbkvSMh6EUoN72pdypBVdmqRRX';
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function openMint() public onlyOwner {
        _active = true;
    }

    function _recoverSigner(bytes memory sig) internal view returns (address) {
        bytes32 messagehash = keccak256(bytes(_message));
        return messagehash.toEthSignedMessageHash().recover(sig);
    }

    function mint(bytes memory signature) public nonReentrant whenNotPaused {
        require(
            _active || msg.sender == owner(),
            'Minting has not been opened yet'
        );

        require(
            totalSupply() < _maxSupply,
            'Total supply of tokens has already been minted....'
        );

        require(
            balanceOf(msg.sender) < 1,
            'Only one token is allowed per address!'
        );

        require(
            _recoverSigner(signature) == owner(),
            'Signature does not match'
        );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _placeholder);
        assert(balanceOf(msg.sender) == 1);
    }

    function updateTokenURI(uint256 tokenId, string memory uri)
        public
        onlyOwner
        whenNotPaused
    {
        bytes32 placeholderUri = keccak256(abi.encodePacked(_placeholder));
        bytes32 oldUri = keccak256(abi.encodePacked(super.tokenURI(tokenId)));
        bytes32 newUri = keccak256(abi.encodePacked(uri));

        require(oldUri != newUri, 'URIs are the same. Please supply a new URI');
        require(placeholderUri == oldUri, 'Metadata can only be updated once.');

        _setTokenURI(tokenId, uri);
        emit PermanentURI(uri, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        if (to != address(0)) {
            require(
                balanceOf(to) < 1,
                'Only one token is allowed per address!'
            );
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
