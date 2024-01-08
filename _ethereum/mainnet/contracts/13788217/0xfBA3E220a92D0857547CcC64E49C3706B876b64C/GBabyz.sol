//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract GBabyz is ERC721, Ownable {

  address payable public constant addr_ = 0xeeeDa9B4e81cf57fD9EF133e33262b4c8BD25d29;
  address public constant giveawayAddr_ = 0x380932aaFD90D6feaf41340becEDFE346603bb50;

  using Counters for Counters.Counter;
  Counters.Counter public _tokenIds;

  constructor() public ERC721("G-Babyz", "GBABY") {
    _setBaseURI("https://assets.gbabyz.com/meta");
        
    for (uint256 i = 0; i < 50; i++) {
      _tokenIds.increment();
      uint256 id = _tokenIds.current();
      _mint(giveawayAddr_, _tokenIds.current());
      _setTokenURI(id, uintToString(id));
    }
  }

  uint256 public constant limit = 10000;
  uint256 public requested = 50;

  function mint()
    public
    payable
  {
    uint qty = msg.value.div(0.08 ether);
    require( qty >= 1, "Send more.");
    require( (requested + qty) <= limit, "Limit Reached, done minting." );
    require( msg.value >= 0.08 ether * qty, "Not enough ETH.");
    (bool success,) = addr_.call{value: msg.value}("");
    require( success, "Could not complete");
    requested += qty;
    for (uint i = 1; i <= qty; i++ ) {
      _tokenIds.increment();
      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);
      _setTokenURI(id, uintToString(id));
    }
  }

  function uintToString(uint256 v) 
    internal
    pure 
    returns (string memory str) 
  {
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;
    while (v != 0) {
        uint256 remainder = v % 10;
        v = v / 10;
        reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i);
    for (uint256 j = 0; j < i; j++) {
        s[j] = reversed[i - 1 - j];
    }
    str = string(s);
  }
}
