// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC1155.sol";
import "./Strings.sol";

contract CelesteDAC is ERC1155 {
    uint256 public constant CelesteDAC1 = 0;
    uint256 public constant CelesteDAC2 = 1;
    uint256 public constant CelesteDAC3 = 2;
    uint256 public constant CelesteDAC4 = 3;
    uint256 public constant CelesteDAC5 = 4;
    uint256 public constant CelesteDAC6 = 5;
    uint256 public constant CelesteDAC7 = 6;
    uint256 public constant CelesteDAC8 = 7;
    uint256 public constant CelesteDAC9 = 8;
    uint256 public constant CelesteDAC10 = 9;
    uint256 public constant CelesteDAC11 = 10;
    uint256 public constant CelesteDAC12 = 11;
    uint256 public constant CelesteDAC13 = 12;
    uint256 public constant CelesteDAC14 = 13;
    uint256 public constant CelesteDAC15 = 14;
    uint256 public constant CelesteDAC16 = 15;
    uint256 public constant CelesteDAC17 = 16;
    uint256 public constant CelesteDAC18 = 17;
    uint256 public constant CelesteDAC19 = 18;
    uint256 public constant CelesteDAC20 = 19;
    uint256 public constant CelesteDAC21 = 20;
    uint256 public constant CelesteDAC22 = 21;
    uint256 public constant CelesteDAC23 = 22;
    uint256 public constant CelesteDAC24 = 23;
    uint256 public constant CelesteDAC25 = 24;
    address public admin;

    mapping (address => uint256) public buyBalance;
    mapping (uint256 => uint256) public IdSold;
    uint256 public sold;
    uint256 public id = 0;

    constructor() ERC1155("https://ipfs.io/ipfs/bafybeiahrr4hqmodlmb3e44cvovf2viqhazezqqnvvoesryrl254kpljli/{id}.json") {
        _mint(msg.sender , CelesteDAC1, 25, "");
        _mint(msg.sender , CelesteDAC2, 25, "");
        _mint(msg.sender , CelesteDAC3, 25, "");
        _mint(msg.sender , CelesteDAC4, 25, "");
        _mint(msg.sender , CelesteDAC5, 25, "");
        _mint(msg.sender , CelesteDAC6, 25, "");
        _mint(msg.sender , CelesteDAC7, 25, "");
        _mint(msg.sender , CelesteDAC8, 25, "");
        _mint(msg.sender , CelesteDAC9, 25, "");
        _mint(msg.sender , CelesteDAC10, 25, "");
        _mint(msg.sender , CelesteDAC11, 25, "");
        _mint(msg.sender , CelesteDAC12, 25, "");
        _mint(msg.sender , CelesteDAC13, 25, "");
        _mint(msg.sender , CelesteDAC14, 25, "");
        _mint(msg.sender , CelesteDAC15, 25, "");
        _mint(msg.sender , CelesteDAC16, 25, "");
        _mint(msg.sender , CelesteDAC17, 25, "");
        _mint(msg.sender , CelesteDAC18, 25, "");
        _mint(msg.sender , CelesteDAC19, 25, "");
        _mint(msg.sender , CelesteDAC20, 25, "");
        _mint(msg.sender , CelesteDAC21, 25, "");
        _mint(msg.sender , CelesteDAC22, 25, "");
        _mint(msg.sender , CelesteDAC23, 25, "");
        _mint(msg.sender , CelesteDAC24, 25, "");
        _mint(msg.sender , CelesteDAC25, 25, "");
        admin = msg.sender;
    }

    function uri(uint256 _tokenId) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/bafybeiahrr4hqmodlmb3e44cvovf2viqhazezqqnvvoesryrl254kpljli/",
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }

    function buy(uint256 n) public returns (bool) {
        require(buyBalance[msg.sender] < 3 && n <= 3, "you can only buy 3 NFTs");
        require(n <= 3 - buyBalance[msg.sender], "invalid n");
        if(id < 25) {
            if(IdSold[id] <= 21) {
                if(21 - IdSold[id] >= n) {
                    _safeTransferFrom( admin, msg.sender, id, n, "0x00");
                    buyBalance[msg.sender] += n;
                    sold += n;
                    if(21 - IdSold[id] == n) id++; 
                    IdSold[id] += n;
                } else {
                    uint256 _n = 21 - IdSold[id];
                    _safeTransferFrom( admin, msg.sender, id, _n, "0x00");
                    buyBalance[msg.sender] += _n;
                    sold += _n;
                    IdSold[id] += _n;    
                    
                    id++;
                    _n = n - _n;
                    _safeTransferFrom( admin, msg.sender, id, _n, "0x00");
                    buyBalance[msg.sender] += _n;
                    sold += _n;
                    IdSold[id] += _n; 
                }
            }
        }
        return true;
    }
}