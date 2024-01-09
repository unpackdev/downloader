// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ERC721.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";


contract MetaverseIdV1 is ERC721, Ownable, ReentrancyGuard {
    // initial configuration
    uint256 nextId = 1;

    // Where to look for ERC-721 token metadata
    string metadataServer;

    // Maps usernames to NFT token IDs and back
    mapping (string => uint256) public handleToId;
    mapping (uint256 => string) public idToHandle;

    // Controller contracts are authorized to mint new NFTs.
    mapping(address=>bool) public controllers;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event MetadataServerChanged(string url);
    event Mint(address indexed to, uint256 tokenId, string handle);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataServer
    ) ERC721(_name, _symbol) {
        metadataServer = _metadataServer;
    }

    // Controller Functions

    function mint(string memory handle, address owner) external onlyController nonReentrant {
        require(handleToId[handle] == 0, "already-exists");
        uint256 id = nextId;
        nextId++;
        handleToId[handle] = id;
        idToHandle[id] = handle;
        emit Mint(owner, id, handle);
        _safeMint(owner, id);
    }

    // Admin Functions

    // Authorises a controller, who can mint new IDs
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    // changes the metadata server
    function setMetadataServer(string memory newServer) external onlyOwner {
        metadataServer = newServer;
        emit MetadataServerChanged(newServer);
    }

    // Helpers

    modifier onlyController {
        require(controllers[msg.sender], "not-controller");
        _;
    }

    // NFT Standard
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(metadataServer, idToHandle[tokenId], ".json"));
    }
}