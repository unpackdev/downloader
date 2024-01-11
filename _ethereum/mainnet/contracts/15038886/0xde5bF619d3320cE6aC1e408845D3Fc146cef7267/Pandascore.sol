//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";

contract Pandascore is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    enum Status { MEMBER, FORMER_MEMBER }
    uint8 public constant MAX_PER_TRANSACTION = 20;

    uint256 private _revealLimitId;
    string private _baseTokenURI;
    string private _unrevealedTokenURI;

    mapping(uint256 => Status) private _statuses;
    mapping(address => bool) private _transferWhitelist;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory _unrevealedURI) ERC721("Pandascore", "PANDA") {
        setUnrevealedTokenURI(_unrevealedURI);
    }


    function status(uint256 _tokenId) public view returns(Status) {
        require(_exists(_tokenId), "Token does not exist");

        return _statuses[_tokenId];
    }


    function isAllowedToTransfer(address _address) public view returns(bool) {
        return _transferWhitelist[_address];
    }

 
    function setUnrevealedTokenURI(string memory _uri) public onlyOwner {
        _unrevealedTokenURI = _uri;
    }


    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }


    function setStatus(uint256 _tokenId, Status _status) external onlyOwner {
        require(_exists(_tokenId), "Token does not exist");

        _statuses[_tokenId] = _status;
    }


    function addToTransferWhiteList(address _address) external onlyOwner {
        require(_address != address(0), "Cannot whitelist null address");

        _transferWhitelist[_address] = true;
    }


    function removeFromTransferWhitelist(address _address) external onlyOwner {
        require(_transferWhitelist[_address], "Address is not whitelisted");

        delete _transferWhitelist[_address];
    }


    function mint(address[] calldata addresses) external onlyOwner {
        require(
            addresses.length <= MAX_PER_TRANSACTION,
            "Not allowed to mint that many."
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot mint for null address");

            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(addresses[i], tokenId);
        }
    }


    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }


    function reveal(uint256 tokenId) external onlyOwner {
        _revealLimitId = tokenId;
    }


    function setBaseTokenURIAndReveal(string memory _uri, uint256 _tokenId) external onlyOwner {
        setBaseTokenURI(_uri);
        _revealLimitId = _tokenId;
    }


    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (tokenId < _revealLimitId) {
            return super.tokenURI(tokenId);
        }

        return _unrevealedTokenURI;
    }


    function _canTransfer(address from, address to) internal view returns(bool) {
        // Minting / Burning
        if (from == address(0) || to == address(0)) {
            return true;
        }

        // Contract owner can send / receive NFT
        if (from == owner() || to == owner()) {
            return true;
        }

        // Whitelisted address can send / receive NFT
        if (_transferWhitelist[from] || _transferWhitelist[to]) {
            return true;
        }

        return false;
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        if (_canTransfer(from, to) == false) {
            revert("Transfer not allowed, Panda forever.");
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }
    

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
