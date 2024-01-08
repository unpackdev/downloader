// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Dosa1 is ERC1155, Ownable {

    address public constant HANDAO = 0xe189a4C9F6468dFb7bBcFf246fa358CdEEAe2071;

    uint256 public constant LO = 0;
    uint256 public constant LK = 1;
    uint256 public constant DH = 2;
    uint256 public constant SH = 3;
    uint256 public constant KK = 4;
    uint256 public constant JG = 5;
    uint256 public constant JM = 6;
    uint256 public constant MM = 7;
    uint256 public constant JL = 8;
    uint256 public constant DK = 9;
    uint256 public constant HJ = 10;
    uint256 public constant YK = 11;
    uint256 public constant YL = 12;
    uint256 public constant JP = 13;
    uint256 public constant DL = 14;
    uint256 public constant SY = 15;
    uint256 public constant WJ = 16;
    uint256 public constant MH = 17;
    uint256 public constant BG = 18;
    uint256 public constant JY = 19;
    uint256 public constant JH = 20;
    uint256 public constant EL = 21;
    uint256 public constant JO = 22;


    mapping (uint256 => string) private _uris;

    constructor() ERC1155("https://2miziqycmdjpozf7oucf73aswbogpddkv5y7m65u5ogk2wpt6nla.arweave.net/0xGUQwJg0vdkv3UEX-wSsFxnjGqvcfZ7tOuMrVnz81Y/{id}.json") {
      _mint(HANDAO, LO, 1, "");
      _mint(HANDAO, LK, 1, "");
      _mint(HANDAO, DH, 1, "");
      _mint(HANDAO, SH, 1, "");
      _mint(HANDAO, KK, 1, "");
      _mint(HANDAO, JG, 1, "");
      _mint(HANDAO, JM, 1, "");
      _mint(HANDAO, MM, 1, "");
      _mint(HANDAO, JL, 1, "");
      _mint(HANDAO, DK, 1, "");
      _mint(HANDAO, HJ, 1, "");
      _mint(HANDAO, YK, 1, "");
      _mint(HANDAO, YL, 1, "");
      _mint(HANDAO, JP, 1, "");
      _mint(HANDAO, DL, 1, "");
      _mint(HANDAO, SY, 1, "");
      _mint(HANDAO, WJ, 1, "");
      _mint(HANDAO, MH, 1, "");
      _mint(HANDAO, BG, 1, "");
      _mint(HANDAO, JY, 1, "");
      _mint(HANDAO, JH, 1, "");
      _mint(HANDAO, EL, 1, "");
      _mint(HANDAO, JO, 1, "");

    }

    function uri(uint256 tokenId) override public view returns (string memory) {
      return(
        string(abi.encodePacked(
          "https://2miziqycmdjpozf7oucf73aswbogpddkv5y7m65u5ogk2wpt6nla.arweave.net/0xGUQwJg0vdkv3UEX-wSsFxnjGqvcfZ7tOuMrVnz81Y/",
          Strings.toString(tokenId),
          ".json"
          ))
        );
    }
}
