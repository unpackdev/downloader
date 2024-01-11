// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Eggs is ERC721, Ownable, ERC721Burnable {
    // Token state
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply = 4646;
    uint256 private _mintValue = 30000000000000000;
    address private _feeReceiver;

    string public _provenanceHash;
    string public _baseURL;

    bool private _isMintOpen = false;

    constructor() ERC721("Eggs", "EGS") {}

    function _baseMint(uint256 count, address recipient) private {
        require(_tokenIds.current() + count <= _maxSupply, "Can not mint more than max supply.");

        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(recipient, _tokenIds.current());
        }
    }

    function mint(uint256 amount) external payable {
        require(_isMintOpen, "Mint is not active.");
        require(amount > 0 && amount <= 10, "You can mint between 1 and 10 in one transaction.");
        require(msg.value >= amount * _mintValue, "Insufficient payment");

        _baseMint(amount, msg.sender);

        bool success = false;
        (success,) = _feeReceiver.call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }

    function reservedMint(uint amount, address recipient) public onlyOwner {
        _baseMint(amount, recipient);
    }

    // Setters
    function flipMintState() public onlyOwner {
        _isMintOpen = !_isMintOpen;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        _maxSupply = newMaxSupply;
    }

    function setMintValue(uint256 newMintValue) public onlyOwner {
        _mintValue = newMintValue;
    }

    function setFeeReceiver(address newFeeReceiver) public onlyOwner {
        _feeReceiver = newFeeReceiver;
    }

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        _provenanceHash = newProvenanceHash;
    }

    function setBaseURL(string memory newBaseURI) public onlyOwner {
        _baseURL = newBaseURI;
    }

    // Getters
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function mintValue() public view returns (uint256) {
        return _mintValue;
    }

    function feeReceiver() public view returns (address) {
        return _feeReceiver;
    }

    function isMintOpen() public view returns (bool) {
        return _isMintOpen;
    }
}

