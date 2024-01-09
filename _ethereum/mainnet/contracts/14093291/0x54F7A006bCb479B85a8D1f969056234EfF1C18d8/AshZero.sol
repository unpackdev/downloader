// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/////////////////////////////////
//                             //
//                             //
//                             //
//                             //
//                             //
//           Ash Zero          //
//              —              //
//             0xG             //
//                             //
//                             //
//                             //
//                             //
/////////////////////////////////

import "./IERC165.sol";

interface ICreatorExtensionTokenURI is IERC165 {
  function tokenURI(address creator, uint256 tokenId) external view returns (string memory);
}

contract AshZero is ICreatorExtensionTokenURI {
  address private _creator;
  address private _ash;
  address private _owner;
  uint8 state = 0;
  uint public max;
  mapping(uint => uint) public seeds;

  constructor(address creator, address ash) {
    _creator = creator;
    _ash = ash;
    _owner = msg.sender;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
    return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  function setState(uint8 newstate) external {
    require(msg.sender == _owner, 'unauthorized');
    state = newstate;
  }

  function drop(address[] memory to) external {
    require(msg.sender == _owner, 'unauthorized');
    state = 1;
    for (uint8 i=0; i<to.length; i++) {
      _mint(to[i]);
    }
  }

  event Mint(address to, uint id);
  function mint() external {
    require(state == 1, 'mint disabled');
    require(IERC721(_creator).balanceOf(msg.sender) == 0, 'only one per wallet');
    _mint(msg.sender);
  }

  function _mint(address to) internal {
    uint balance = IERC20(_ash).balanceOf(to) / 1000000000000000000;
    require(balance > 0, 'need to own some ash to mint');
    uint tokenId = IERC721CreatorCore(_creator).mintExtension(to);
    seeds[tokenId] = balance;
    if (tokenId > 3 && balance > max) {
      max = balance;
    }
    emit Mint(to, tokenId);
  }

  // Classes.
  // 0 the most rare. There are only four: token 1, 2, 3 and the highest Ash balance.
  // 1-199 the lower the more rare.
  // 200 common. This is a holder who has carbon role (< 100 Ash).
  function getClass(uint tokenId) public view returns (uint) {
    return tokenId < 4 || seeds[tokenId] == max ? 0 : seeds[tokenId] < 100 ? 200 : 200 - (199 * seeds[tokenId] / max);
  }

  function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
    require(creator == _creator, 'invalid creator');
    require(seeds[tokenId] != 0, 'AshZero: URI query for nonexistent token');
    uint c = getClass(tokenId);

    return string(
      abi.encodePacked(
        "data:application/json;utf8,",
        '{"name":"Zero',
        c > 0 ? string(abi.encodePacked(" [", toString(c), "]")) : "",
        '","created_by":"0xG","description":"Memory.","image":"',
          "data:image/svg+xml,%3Csvg viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg' style='background-color: %23",
          tokenId == 3 ? "fff" : "111",
          "'%3E%3Crect stroke-dasharray='",
          c == 0 ? "0" : c == 200 ? "1" : toString(200 - c),
          "' height='50' width='50' y='25' x='25' stroke='%23",
          tokenId == 3 ? "111" : c == 0 && tokenId < 3 ? "fff" : c == 200 ? "42474c" : "c9cbce",
          "' fill='transparent' /%3E%3C/svg%3E",
        '","attributes":[',
          '{"trait_type":"Class","value":"',toString(c),'"},',
          '{"trait_type":"Seed","value":"',toString(seeds[tokenId]),'"}',
        "]}"
      )
    );
  }

  // Taken from "@openzeppelin/contracts/utils/Strings.sol";
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}

interface IERC721 is IERC165 {
  function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
}

interface IERC721CreatorCore {
  function mintExtension(address to) external returns (uint256);
}

