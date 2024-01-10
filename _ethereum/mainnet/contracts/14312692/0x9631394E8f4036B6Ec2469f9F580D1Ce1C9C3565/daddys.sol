//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract daddys is ERC721, Ownable {

  address payable public constant addr_ = 0x7D0f95FcE3e839369f2fA464B172C361d5349618;

  using Counters for Counters.Counter;
  Counters.Counter public _tokenIds;

  constructor() public ERC721("daddy", "DADDY") {
    _setBaseURI("https://areyawinningson.xyz/meta");
  }

  uint256 public constant limit = 10021;
  uint256 public requested = 0;
  uint256 public constant daddyPrice = 0.069 ether;

  function setBaseURI(string calldata baseURI_) external onlyOwner() {
      _setBaseURI(baseURI_);
  }

  function mint()
    public
    payable
  {
    uint qty = msg.value.div(daddyPrice);
    require( qty >= 1, "Not enough ETH.");
    require( (requested + qty) <= limit, "Limit Reached, done minting" );
    require( msg.value >= daddyPrice * qty, "Not enough ETH");
    (bool success,) = addr_.call{value: msg.value}("");
    require( success, "Could not complete, please try again");
    requested += qty;
    for (uint i = 1; i <= qty; i++ ) {
      _tokenIds.increment();
      _mint(msg.sender, _tokenIds.current());
    }
  }
}
