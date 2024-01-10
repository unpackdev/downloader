//SPDX-License-Identifier: Unlicense

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@    LaiTopepez    @@@@@@@@@@@@@@@&&&&@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@&&&&&@@@@@@@@&&&&&@@@@@@@@@@@@@
// @@   laitopepez.xyz    @@@@@@@@@@@@@&&&&@@@@@@@@@&&&&&@@@@@@@@&&&&&@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@&&&&@@@@@@@@@&&&&&@@@@&&&&&@@@@&&&&@@@@@@@@@
// @@  0.0069 ETH / 6969   &&&@@@@@@@@@&&&&@@@@@@@@@&&&&&@@@@&&&&&@@@@&&&&@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@&&&&@@@@@@@@@&&&&&@@@@&&&&@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@&&&&%%%%@@@@@@@@@@@@@@&&&&@@@@@@@@@&&&&&@@@@&&&&@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@(,,,,,,,,%@@@@@@@@@@@@@&&&&@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@****,,,,,,,,,,,,,,................................ . %@@@@@@@@
// @@@@@@@@@@@@@@@@@@****,,,,,,,,,,,,,,...............................    %@@@@@@@@
// @@@@@@@@@@@@@&********,,,,,@@@@&&&&&@@@@&&&&&@@@@....*@@@@&&&&&@@@@&&&&@@@@@@@@@
// @@@@@@@@@@@@@%********,,,,,@@@@&&&&&@@@@&&&&&@@@@....*@@@@&&&&&@@@@&&&&@@@@@@@@@
// @@@@@@@@@*************,,,,,,,,,,.,.,...................... . .              @@@@
// @@@@@@@@@*************,,,,,,,,,,..........................                  @@@@
// @@@@@@@@@**************,,,,             $$$$$    ....              $$$$,    @@@@
// @@@@@@@@@*************,,,,,             $$$$$                      $$$$(****@@@@
// @@@@@@@@@*************,,,,,....         $$$$$$$$$$                 $$$$$$$$$@@@@
// @@@@@@@@@*************,,,,,..................                               @@@@
// @@@@@@@@@*************,,,,,,.,...............                               @@@@
// @@@@@@@@@*********,,,,******************************************************@@@@
// @@@@@@@@@*********,,,,******************************************************@@@@
// @@@@@@@@@*********,,,,*****&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&sSSssSSssS@@@@
// @@@@@@@@@*********,,,,*****&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&SsSSSsSSSSSsSS@@@@
// @@@@@@@@@*********,,,,,,,,,*************************************************@@@@
// @@@@@@@@@%%%%#****,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,.,.........%%%%%%%%%@@@@
// @@@@@@@@@@@@@%****,,,,,,,,,,,,,,...............................    @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@(....,,,,,.,.,......................@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@(....,,,,,..........................@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@&****,,,,,,,,,...........................             @@@@@@@@@@@@@
// @@@@@@@@@@@@@%****,,,,,,,,,...........................             @@@@@@@@@@@@@
// @@@@@@@@@@@@@%****@@@@(,,,,,,,,.......................    @@@@/    @@@@@@@@@@@@@
// @@@@@@@@@@@@@%****@@@@(,,,,,,,,.......................    @@@@/    @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@#****,,,,,,,,,,,,,.,.,..........    @@@@@@@@@@@@@@@@@@@@@@


pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract LaiTopepez is ERC721A, Ownable {
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 6969;
  uint256 public constant MAX_BY_TX = 69;
  uint256 public constant PRICE = 0.0069 ether;

  address private constant LAI_ADDRESS = 0xf6474692D51EF0c0Ba42e1aE53FAa9800d906318;
  address private constant DEV_ADDRESS = 0xafeCA736E2FE082A7e21a224Bd5950948808a9b2;
  address private constant CHAR_ADDRESS = 0xE6E52e8aaC4d5b48a49fCB3D9308f67600537952;

  bool public saleState;

  string public baseURI;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_
  ) ERC721A(name_, symbol_) {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 _amount) external payable {
    require(saleState, "Sale is closed!");
    require(totalSupply() + _amount <= MAX_SUPPLY, "Exceed MAX_SUPPLY");
    require(_amount > 0 && _amount <= MAX_BY_TX, "Invalid amount");
    require(msg.value == PRICE * _amount, "Invalid ETH amount!");
    _safeMint(msg.sender, _amount);
  }

  /********* laiTopepez Only *********/

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setSaleState(bool _saleState) external onlyOwner {
    saleState = _saleState;
  }

  /********* call me  *********/

  function premint() external {
    require(!saleState && totalSupply() == 0, "Nop");

    _safeMint(CHAR_ADDRESS, 69);
    _safeMint(LAI_ADDRESS, 20 );
    _safeMint(DEV_ADDRESS, 10);
  }

  function withdraw() external {
    uint256 laiTopepezAmount = (address(this).balance * 60) / 100;
    uint256 devAmount = (address(this).balance * 30) / 100;
    uint256 charAmount = (address(this).balance * 10) / 100;

    (bool success1, ) = LAI_ADDRESS.call{value: laiTopepezAmount}("");
    (bool success2, ) = DEV_ADDRESS.call{value: devAmount}("");
    (bool success3, ) = CHAR_ADDRESS.call{value: charAmount}("");

    require(success1 && success2 && success3, "Withdraw failed");
  }

}
