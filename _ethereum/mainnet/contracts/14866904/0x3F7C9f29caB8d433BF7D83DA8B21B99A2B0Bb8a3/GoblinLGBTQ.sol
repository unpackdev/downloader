//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .-----------------. .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |   _____      | || |    ______    | || |   ______     | || |  _________   | || |    ___       | || |    ______    | || |     ____     | || |   ______     | || |   _____      | || |     _____    | || | ____  _____  | || |    _______   | |
// | |  |_   _|     | || |  .' ___  |   | || |  |_   _ \    | || | |  _   _  |  | || |  .'   '.     | || |  .' ___  |   | || |   .'    `.   | || |  |_   _ \    | || |  |_   _|     | || |    |_   _|   | || ||_   \|_   _| | || |   /  ___  |  | |
// | |    | |       | || | / .'   \_|   | || |    | |_) |   | || | |_/ | | \_|  | || | /  .-.  \    | || | / .'   \_|   | || |  /  .--.  \  | || |    | |_) |   | || |    | |       | || |      | |     | || |  |   \ | |   | || |  |  (__ \_|  | |
// | |    | |   _   | || | | |    ____  | || |    |  __'.   | || |     | |      | || | | |   | |    | || | | |    ____  | || |  | |    | |  | || |    |  __'.   | || |    | |   _   | || |      | |     | || |  | |\ \| |   | || |   '.___`-.   | |
// | |   _| |__/ |  | || | \ `.___]  _| | || |   _| |__) |  | || |    _| |_     | || | \  `-'  \_   | || | \ `.___]  _| | || |  \  `--'  /  | || |   _| |__) |  | || |   _| |__/ |  | || |     _| |_    | || | _| |_\   |_  | || |  |`\____) |  | |
// | |  |________|  | || |  `._____.'   | || |  |_______/   | || |   |_____|    | || |  `.___.\__|  | || |  `._____.'   | || |   `.____.'   | || |  |_______/   | || |  |________|  | || |    |_____|   | || ||_____|\____| | || |  |_______.'  | |
// | |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract GoblinLGBTQ is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  bool public sleepunngg = true;
  bool public revealuuuag = false;
  uint256 constant public LGBTQGoblins = 6943;
  uint256 constant public maxlgbtq = 6;
  mapping(address => uint256) public clanSize;

  event GuardWentKnockout(address account);

  event GuardMAD(address account);

  event WeBrokeThrough(address account);

  constructor(
  ) ERC721A("LGBTQGoblins", "LGBTQG") {
  }

  modifier callerIsLGBTQGoblin() {
    require(tx.origin == msg.sender, "The caller is another contract!");
    _;
  }

  modifier sleepingGoblinGuard() {
    require(!sleepunngg, "guarrd is sleepunngg zzzz..!");
    _;
  }

  function callForHelp(uint256 quantity)
    external
    nonReentrant
    callerIsLGBTQGoblin
    sleepingGoblinGuard
  {
    require(totalSupply() + quantity < LGBTQGoblins, "no miore golds left uadha!");
    require(
      clanSize[msg.sender] + quantity < maxlgbtq,
      "too many goblin handssds uauah!"
    );
    clanSize[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function slapGuardKnockout() public onlyOwner {
    sleepunngg = true;
    emit GuardWentKnockout(msg.sender);
  }

  function throwWaterInGuardFace() public onlyOwner {
    sleepunngg = false;
    emit GuardMAD(msg.sender);
  }

  function meRevealHEHE() public onlyOwner {
    revealuuuag = true;
    emit WeBrokeThrough(msg.sender);
  }

  // metadata URI
  string private _endOfTheRainbow;

  function _baseURI() internal view virtual override returns (string memory) {
    return _endOfTheRainbow;
  }

  function setBaseURI(string calldata newRainbow) external onlyOwner {
    _endOfTheRainbow = newRainbow;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "this one is still sleepungg!");

    string memory baseURI = _baseURI();
    string memory json = ".json";

    if(revealuuuag){
      return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
        : '';
    }else{
      return baseURI;
    }
  }

  function gibFunds() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success, "Failed to melt precious gold.");
	}
}
