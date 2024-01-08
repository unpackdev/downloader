// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./AccessControl.sol";

contract CandyCard is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "caller does not have required role");
        _;
    }

    uint constant MAX_SUPPLY = 10000;
    uint _tokenIdCounter = 0;

    constructor() ERC721("Candy Card", "CC") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setBaseURI("https://img.horrorsociety.io/cards/");
    }
    
    function mint(address receiver) external onlyRole(MINTER_ROLE) {
        require(_tokenIdCounter < MAX_SUPPLY, "max supply reached");
        _safeMint(receiver, _tokenIdCounter++);
    }
    
    function burn(uint tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId) || hasRole(BURNER_ROLE, msg.sender), "caller must be owner or approved");
        _burn(tokenId);
    }
    
    function setBaseURI(string memory _baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_baseURI);
    }
}
