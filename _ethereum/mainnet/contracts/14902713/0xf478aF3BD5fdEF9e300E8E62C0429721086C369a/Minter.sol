// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./Strings.sol";
import "./Ownable.sol";


interface Balot {
  function safeMint(address to, string calldata uri) external returns (uint256);
  function transferOwnership(address newOwner) external;
}

contract Minter is Ownable {
  function safeMintRange(
    address collection,
    address to,
    uint16 start,
    uint16 end
  ) external onlyOwner {
    Balot b = Balot(collection);
    for (uint256 tokenId = start; tokenId <= end; tokenId += 1) {
      b.safeMint(to, string(abi.encodePacked(
        Strings.toString(tokenId),
        ".json"
      )));
    }
  }

  function transferCollection(address collection, address nextOwner) external onlyOwner {
    Balot b = Balot(collection);
    b.transferOwnership(nextOwner);
  }
}
