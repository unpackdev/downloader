// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";

contract BallStorm is ReentrancyGuard, ERC721 {
  uint256 public constant MAX_SUPPLY = 1024;
  uint256 public constant MINT_PRICE = 0.02 ether;
  uint256 public totalSupply;
  address internal _owner;

  constructor() ERC721("BallStorm", "BallStorm") {
    _owner = msg.sender;
  }

  function mint(address _to, uint256 _amount) external payable nonReentrant {
    require(totalSupply + _amount < MAX_SUPPLY, "EXCEEDS_SUPPLY");
    require(msg.value >= MINT_PRICE * _amount, "NOT_ENOUGH_ETHER");
    payable(_owner).transfer(msg.value);
    for(uint256 i; i < _amount; i++) {
      _safeMint(_to, totalSupply);
      totalSupply++;
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    require(totalSupply > tokenId, "NOT_EXISTS");
    return
      string(
        abi.encodePacked(
          "ipfs://QmPy4LHUbMySPj9Rujy6R51e4SwBzjmNqY5upDStAoRNmL/",
          Strings.toString(tokenId)
        )
      );
  }
}
