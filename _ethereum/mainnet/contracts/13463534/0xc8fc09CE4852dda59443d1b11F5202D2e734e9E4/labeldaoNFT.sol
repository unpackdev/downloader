pragma solidity >=0.6.0 <0.7.0;
//SPDX-License-Identifier: MIT

//import "./console.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract labeldaoNFT is ERC721, Ownable {

  address payable public constant labeldao = 0xe690401F91Fbd93898aDAc81e753EE4F9142d821;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() public ERC721("labeldaoNFT", "LBL") {
    _setBaseURI("https://ipfs.io/ipfs/");
  }

  uint256 public constant limit = 3450; //change to exact
  uint256 public requested;

  function mintItem(address to, string memory tokenURI)
      public
      onlyOwner
      returns (uint256)
  {
      require( _tokenIds.current() < limit , "DONE MINTING");
      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(to, id);
      _setTokenURI(id, tokenURI);

      return id;
  }

  event Request(address to, uint256 value);

  function requestMint()
      public
      payable
  {
    require( requested++ < limit , "DONE MINTING");
    require( msg.value >= .08 ether, "NOT ENOUGH");
    (bool success,) = labeldao.call{value:msg.value}("");
    require( success, "could not send");
    emit Request(msg.sender, msg.value);
  }
}
