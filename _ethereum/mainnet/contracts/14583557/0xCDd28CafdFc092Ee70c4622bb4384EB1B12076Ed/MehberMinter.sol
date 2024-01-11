// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./IMehberCollection.sol";
import "./IMehtaverse.sol";

contract MehberMinter is Ownable {
  IMehberCollection public MehberCollection;
  IMehtaverse public Mehtaverse;

  mapping(uint256 => bool) public tokenPublicMintEnabled;

  mapping(uint256 => mapping(address => bool)) public mintPassMinted;
  mapping(uint256 => uint256) public mintPassMints;

  constructor(address MehberAddress, address MehtaverseAddress) {
    MehberCollection = IMehberCollection(MehberAddress);
    Mehtaverse = IMehtaverse(MehtaverseAddress);
  }

  function updateMintPassAmount(uint256 tokenId, uint256 amount)
    public
    onlyOwner
  {
    mintPassMints[tokenId] = amount;
  }

  function toggleTokenPublicMint(uint256 tokenId) public onlyOwner {
    tokenPublicMintEnabled[tokenId] = !tokenPublicMintEnabled[tokenId];
  }

  function publicMint(uint256 tokenId) external {
    require(tokenPublicMintEnabled[tokenId], "PUBLIC_SALE_DISABLED");

    MehberCollection.mint(msg.sender, tokenId, 1);
  }

  function mintPassMint(uint256 tokenId) external {
    uint256 mehBalance = Mehtaverse.balanceOf(msg.sender);

    require(mehBalance > 0, "MUST_OWN_MEHS");
    require(mintPassMints[tokenId] > 0, "NO_MEHBER_MINTS");
    require(!mintPassMinted[tokenId][msg.sender], "MEHBER_ALREADY_MINTED");

    mintPassMinted[tokenId][msg.sender] = true;

    MehberCollection.mint(
      msg.sender,
      tokenId,
      mehBalance * mintPassMints[tokenId]
    );
  }
}
