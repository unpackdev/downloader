// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

/**
 *
 *             .-'''-.
 *           '   _    \            .---.
 *          /   /` '.   \ /|        |   |.--.   _..._   /|
 *   .--./).   |     \  ' ||        |   ||__| .'     '. ||                               _.._
 *  /.''\\ |   '      |  '||        |   |.--..   .-.   .||                  .-,.--.    .' .._|
 * | |  | |\    \     / / ||  __    |   ||  ||  '   '  |||  __        __    |  .-. |   | '
 *  \`-' /  `.   ` ..' /  ||/'__ '. |   ||  ||  |   |  |||/'__ '.  .:--.'.  | |  | | __| |__
 *  /("'`      '-...-'`   |:/`  '. '|   ||  ||  |   |  ||:/`  '. '/ |   \ | | |  | ||__   __|
 *  \ '---.               ||     | ||   ||  ||  |   |  |||     | |`" __ | | | |  '-    | |
 *   /'""'.\              ||\    / '|   ||__||  |   |  |||\    / ' .'.''| | | |        | |
 *  ||     ||             |/\'..' / '---'    |  |   |  ||/\'..' / / /   | |_| |        | |
 *  \'. __//              '  `'-'`           |  |   |  |'  `'-'`  \ \._,\ '/|_|        | |
 *   `'---'                                  '--'   '--'           `--'  `"            |_|
 *
 */

contract goblinbarfNFT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  string public _partslink;
  bool public byebye = false;
  uint256 public goblins = 9999;
  uint256 public goblinbyebye = 5;
  uint256 public free = 0 ether;
  uint256 public pay = 0.005 ether;
  uint256 public goblintreasure = 0;
  uint256 public goblinmaxtreasure = 500;

  constructor() ERC721A("goblinbarf", "GB") {}

  function _baseURI() internal view virtual override returns (string memory) {
    return _partslink;
  }
  
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No goblins");
    return string(abi.encodePacked(_partslink, tokenId.toString(), ".json"));
  }

  function makingobblin(uint256 _goblins) external payable nonReentrant {
    uint256 totalgobnlinsss = totalSupply();
    uint256 totalnottreasuregoblins = totalgobnlinsss - goblintreasure;
    require(byebye);
    require(totalnottreasuregoblins + goblinmaxtreasure + _goblins <= goblins, "Too much goblins...");
    require(msg.sender == tx.origin);
    require(balanceOf(msg.sender) + _goblins <= goblinbyebye, "Greedy humans...");
    require(msg.value >= price(totalnottreasuregoblins) * _goblins, "You poor humans..");
    _safeMint(msg.sender, _goblins);
  }

  function makegoblinnnfly(address lords, uint256 _goblins) public onlyOwner {
    uint256 totalgobnlinsss = totalSupply();
    require(goblintreasure + _goblins <= goblinmaxtreasure, "Goblin Fault is full");
    require(totalgobnlinsss + _goblins <= goblins, "Too much goblins...");
    goblintreasure += _goblins;
    _safeMint(lords, _goblins);
  }

  function makegoblngobyebye(bool _bye) external onlyOwner {
    byebye = _bye;
  }

  function spredgobblins(uint256 _byebye) external onlyOwner {
    goblinbyebye = _byebye;
  }

  function makegobblinhaveparts(string memory parts) external onlyOwner {
    _partslink = parts;
  }

  function _startTokenId() internal view override virtual returns (uint256) {
      return 1;
  }

  function price(uint256 supply) public view returns (uint256){
    return supply < 1500 ? free : pay;
  }

  function sumthinboutfunds() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}