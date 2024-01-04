// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

import "./ERC721PresetMinterPauser.sol";
import "./ISpaceShips.sol";

contract MysteryShip is ERC721PresetMinterPauser {
    uint256 public constant maxSupply = 888;

    uint256 nextId;

    ISpaceShips spaceships;
    uint8[] private revealedModels;

    constructor(address _spaceships)
        public
        ERC721PresetMinterPauser(
            "Mystery Ship",
            "Mystery Ship",
            "https://mystery.service.cometh.io/"
        )
    {
      spaceships = ISpaceShips(_spaceships);
    }

    function mint(address to) public {
        uint256 tokenId = nextId;
        require(tokenId < maxSupply, 'MysteryShip: already minted max supply');

        nextId++;
        super.mint(to, tokenId);
    }

    function hasBeenRevealed() public view returns (bool) {
      return revealedModels.length > 0;
    }
    
    function revealedModel(uint256 tokenId) external view returns (uint256) {
      return uint256(revealedModels[tokenId]);
    }

    function reveal(uint256[] calldata tokenIds) external {
      require(hasBeenRevealed(), 'MysteryShip: reveal has not happened yet');

      for (uint256 i = 0; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        require(ownerOf(tokenId) == msg.sender, 'MysteryShip: sender is not token owner');
        uint256 model = revealedModels[tokenId];

        _burn(tokenId);
        spaceships.mint(msg.sender, model);
      }
    }

    function setRevealedModels(uint8[] calldata models) external {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MysteryShip: must have admin role to reveal");
      revealedModels = models;
    }

    function supply() external view returns (uint256) {
      return maxSupply - nextId;
    }
}
