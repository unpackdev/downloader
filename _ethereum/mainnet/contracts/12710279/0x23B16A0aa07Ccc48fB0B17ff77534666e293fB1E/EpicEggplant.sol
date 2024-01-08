// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract EpicEggplant is ERC721Enumerable, Ownable {
  /*
  MMMWOlkWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMMXdlOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMMXdcx00OkkkOO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMW0occcccccccccldKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  N0dlccc:ccccccc:ccl0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  klcccccccccccccccccoKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  ccc:ccccccccccccccccxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  cccccccccccccc::::::l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  lccccc:cc:::c:;;;;;;;cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  klcccc:::;;:::;;;;;;;;;lkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  NOoc::;;;;;;;;;;;;;;;;;;;lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MWXx:,,',;;;;;;;;;;;;;;;;;:o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMMXo,''',,;;;;;;;;;;;;;;;;;:dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMMMKl'''',;;;;;;;;;;;;;;;;;;;cdKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMMMWO:'''',;;;;;;;;;;;;;;;;;;;;cdk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMMMMWk;'''',;;;;;;;;;;;;;;;;;;;;;;:d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMMMMMNx,'''',;;;;;;;;;;;;;;;;;;;;;;;:lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMMMMMMXo,'''',,;;;;;;;;;;;;;;;;;;;;;;;;:okKNWMMMMMMMMMMMMMMMMMMMMMMM
  MMMMMMMMXl,'''',;;;;;;;;;;:oxO000OOkoc;;;;;:ldOKXWWMMMMMMMMMMMMMMMMMM
  MMMMMMMMMKl,'''',,;;;;;;;lONMWNXNWMMWKo;;;;;;;;:codk0XWMMMMMMMMMMMMMM
  MMMMMMMMMW0c''''',;;;;;;:kNNNOlclONWMWOc;;;;;;;;;;;;;:lx0NWMMMMMMMMMM
  MMMMMMMMMMW0c''''',,;;;;;clll:;;:kXNMWO:;;;;;;;;;;;;;;;;:lx0NMMMMMMMM
  MMMMMMMMMMMWO:''''',,;;;;;;;;;;lONMMW0l;;;;;;;;;;;;;;;;;;;;:oONMMMMMM
  MMMMMMMMMMMMWO:''''',,;;;;;;;:kNWWNKd:;;;;;;;;;;;;;;;;;;;;;;;;lONMMMM
  MMMMMMMMMMMMMW0c''''',,;;;;;;dNMNklc;;;;;;;;;;;;;;;;;;;;;;;;;;;:dKWMM
  MMMMMMMMMMMMMMW0c,'''',,;;;;;lxkdc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;l0WM
  MMMMMMMMMMMMMMMWKo,''''',,;;;codo:;;;;;;;;;;;;;;;;;;;;;;;;;;;:cc:;cOW
  MMMMMMMMMMMMMMMMMNx;''''',,;cOWWNx:;;;;;;;;;;;;;;;;;;;;;;;;;cOX0o;;l0
  MMMMMMMMMMMMMMMMMMWOc,''''',;oO0kl;;;;;;;;;;;;;;;;;;;;;;;;;;cxOxc;;;d
  MMMMMMMMMMMMMMMMMMMWXd;'''''',;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:
  MMMMMMMMMMMMMMMMMMMMMNk:,''''',,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  MMMMMMMMMMMMMMMMMMMMMMWKo,'''''',,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  MMMMMMMMMMMMMMMMMMMMMMMMNOc,'''''''',,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;c
  MMMMMMMMMMMMMMMMMMMMMMMMMWXx:,''''''''',,,,;;;;;;;;;;;;;;;;;;;;;;;;ck
  MMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc,''''''''''',,,,,;;;;;;;;;;;;;;;;;;cON
  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo;,,'''''''''''',,,,,,,;;;;;;;;;:dKWM
  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK0ko:,'''''''''''''''',,,,,,;cd0NMMM
  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdl:;,'''''''''''',;cokKWMMMMM
  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOdl:;,,''',;:ldOXWMMMMMMMM
  (c) low-effort studios
  */
  uint public constant MAX_EGGPLANTS = 10000;
	string _baseTokenURI;
	bool public paused;

  /*10% of all primary sales will go to Cole's wallet.
  He's the founder of MyFuckingPickle and will distribute this money
  fairly among himself and the pickle community*/
  address public colethereum = 0xFe5573C66273313034F7fF6050c54b5402553716;

  // And now stop doxing around
  constructor(string memory baseURI) ERC721("EpicEggplants", "EPICEGGPLANTS")  {
      setBaseURI(baseURI);
      paused = true;
  }

  modifier saleIsOpen{
      require(totalSupply() < MAX_EGGPLANTS, "Sale end");
      _;
  }

  function mintEggplant(address _to, uint _count) public payable saleIsOpen {
      if(msg.sender != owner()){
          require(!paused, "Pause");
      }
      require(totalSupply() + _count <= MAX_EGGPLANTS, "Max limit");
      require(totalSupply() < MAX_EGGPLANTS, "Sale end");
      require(_count <= 20, "Exceeds 20");
      require(msg.value >= price(_count), "Value below price");

      for(uint i = 0; i < _count; i++){
          _safeMint(_to, totalSupply());
      }

      //if you are still around: this is the code that gives money to the pickles
      if (msg.value > 0) {
        payable(colethereum).transfer(msg.value*10/100);
      }
  }

  function price(uint _count) public view returns (uint256) {
      uint _id = totalSupply();
      // free 1000
      if(_id <= 1000 ){
          return 0;
      }

      return 10000000000000000 * _count; // 0.01 ETH
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }
  function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
  }

  // nothing interesting down here, just get a life and stop reading, ser
  function walletOfOwner(address _owner) external view returns(uint256[] memory) {
      uint tokenCount = balanceOf(_owner);

      uint256[] memory tokensId = new uint256[](tokenCount);
      for(uint i = 0; i < tokenCount; i++){
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }

      return tokensId;
  }

  function pause(bool val) public onlyOwner {
      paused = val;
  }

  function withdrawAll() public payable onlyOwner {
      require(payable(_msgSender()).send(address(this).balance));
  }
}
