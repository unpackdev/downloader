// SPDX-License-Identifier: MIT

////   //////////          //////////////        /////////////////          //////////////
////          /////      /////        /////      ////          /////      /////        /////
////            ///     ////            ////     ////            ////    ////            ////
////           ////     ////            ////     ////            ////    ////            ////
//////////////////      ////            ////     ////            ////    ////            ////
////                    ////     ///    ////     ////            ////    ////     ///    ////
////      ////          ////     /////  ////     ////            ////    ////     /////  ////
////        ////        ////       /////////     ////            ////    ////       /////////
////         /////       /////       //////      ////          /////      /////       //////
////           /////       ////////    ////      ////   //////////          ////////    ////

pragma solidity ^0.8.0;

import "./Base64.sol";
import "./Strings.sol";
import "./IERC721Dispatcher.sol";
import "./IERC721Delegable.sol";

/**
 * @title RQDQURI
 * @dev Render library for tokenURI of RQDQ sDQ tokens.
 * @author 0xAnimist (kanon.art)
 */
library RQDQURI {

  function packSVG(uint256 _tokenId) public pure returns(string memory) {
    string[9] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base {fill: rgb(40,40,40); font-family: "Helvetica", Arial, sans-serif;} .firstLevel { font-size: 14px;} .secondLevel {font-size: 8px; line-height: 10px;}</style><rect width="100%" height="100%" fill="WhiteSmoke" /><text x="10" y="25" class="base firstLevel">RQDQ token # ';

        parts[1] = Strings.toString(_tokenId);

        parts[2] = '</text><text x="10" y="40" class="base secondLevel">';

        parts[3] = 'See description for redemption chain';

        parts[4] = '</text></svg>';

        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
  }

  function packName(uint256 _tokenId) public pure returns(string memory) {
    return string(abi.encodePacked('"name": "RQDQ token #', Strings.toString(_tokenId), '",'));
  }

  function packDescription(address _RQContract, address _DQContract, uint256 _RQTokenId, uint256 _DQTokenId, uint256 _tokenId) public pure returns(string memory) {
    string[8] memory description;
    description[0] = '"description": "This RQDQ token is redeemable for token #';
    description[1] = Strings.toString(_DQTokenId);
    description[2] = ' of the NFT contract at ';
    description[3] = toString(_DQContract);
    description[4] = ' which is the delegate token for ERC721Delegable token #';
    description[5] = Strings.toString(_RQTokenId);
    description[6] = ' of the NFT contract at ';
    description[7] = toString(_RQContract);

    string memory desc = string(abi.encodePacked(
      description[0],
      description[1],
      description[2],
      description[3],
      description[4],
      description[5],
      description[6],
      description[7]
    ));

    return string(abi.encodePacked(desc, '.",'));
  }

  function tokenURI(uint256 _tokenId) public view returns(string memory) {
    (address RQContract, uint256 RQTokenId) = IERC721Dispatcher(msg.sender).getDepositByTokenId(_tokenId);
    (address DQContract, uint256 DQTokenId) = IERC721Delegable(RQContract).getDelegateToken(RQTokenId);

    string memory name = packName(_tokenId);
    string memory description = packDescription(RQContract, DQContract, RQTokenId, DQTokenId, _tokenId);
    string memory svg = packSVG(_tokenId);

    string memory metadata = string(abi.encodePacked(
      '{',
      name,
      description
    ));

    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      metadata,
      '"image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svg)),
      '"}'))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }


  //Address to string encodeing by k06a
  //see: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
  function toString(address account) internal pure returns(string memory) {
    return toString(abi.encodePacked(account));
  }

  function toString(bytes32 value) internal pure returns(string memory) {
    return toString(abi.encodePacked(value));
  }

  function toString(bytes memory data) internal pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }

}
