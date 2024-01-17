// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";

contract DOGECOLLIE is ERC721 {
    string baseURI;
    address manager;

    address public owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string _contractURI;

    constructor(
        address owner_,
        string memory baseURI_,
        string memory _contractURI_
    ) ERC721("DOGE COLLIE", "DOGE COLLIE") {
        owner = owner_;
        manager = msg.sender;
        baseURI = baseURI_;
        _tokenIds.increment();
        _contractURI = _contractURI_;
    }

    function mint(address player) external onlyManager {
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _tokenIds.increment();
    }

    function mintBatch(address player, uint times) external onlyManager{
        for (uint i; i < times; i++) {
            _mint(player, _tokenIds.current());
            _tokenIds.increment();
        }
    }

    function setBaseURI(string memory baseURI_) external onlyManager {
        baseURI = baseURI_;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string.concat(baseURI, Strings.toString(tokenId), ".json");
    }

    function setContractURI(string memory contractURI_) external onlyManager {
        _contractURI = contractURI_;
    }

    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "NOT_OWNER");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "NOT_MANAGER");
        _;      
    }
}
