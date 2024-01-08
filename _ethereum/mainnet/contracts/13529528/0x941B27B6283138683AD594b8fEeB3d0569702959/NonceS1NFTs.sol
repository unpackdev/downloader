// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract NonceS1NFT is ERC1155, Ownable {

    address public constant NONCEFAM = 0xe672ff567ca21238a3BAfaC8EB981A570c4892DB;

    uint256 public constant LNG0 = 0;
    uint256 public constant LNG1 = 1;
    uint256 public constant LNG2 = 2;
    uint256 public constant LNG3 = 3;
    uint256 public constant LNG4 = 4;
    uint256 public constant LNG5 = 5;
    uint256 public constant SIH0 = 6;
    uint256 public constant SIH1 = 7;
    uint256 public constant SIH2 = 8;
    uint256 public constant SIH3 = 9;
    uint256 public constant SIH4 = 10;
    uint256 public constant SIH5 = 11;


    mapping (uint256 => string) private _uris;

    constructor() ERC1155("https://xzsvxtprrlyuvxjd47gtirf7ob4f5z5o5x22tmzyeifgj2btqxnq.arweave.net/vmVbzfGK8UrdI-fNNES_cHhe567t9amzOCIKZOgzhds/{id}.json") {
      _mint(NONCEFAM, LNG0, 50, "");
      _mint(NONCEFAM, LNG1, 10, "");
      _mint(NONCEFAM, LNG2, 10, "");
      _mint(NONCEFAM, LNG3, 10, "");
      _mint(NONCEFAM, LNG4, 10, "");
      _mint(NONCEFAM, LNG5, 10, "");
      _mint(NONCEFAM, SIH0, 50, "");
      _mint(NONCEFAM, SIH1, 10, "");
      _mint(NONCEFAM, SIH2, 10, "");
      _mint(NONCEFAM, SIH3, 10, "");
      _mint(NONCEFAM, SIH4, 10, "");
      _mint(NONCEFAM, SIH5, 10, "");
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
      return(
        string(abi.encodePacked(
          "https://xzsvxtprrlyuvxjd47gtirf7ob4f5z5o5x22tmzyeifgj2btqxnq.arweave.net/vmVbzfGK8UrdI-fNNES_cHhe567t9amzOCIKZOgzhds/",
          Strings.toString(tokenId),
          ".json"
          ))
        );
    }
}
