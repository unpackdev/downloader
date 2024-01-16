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
import "./IERC721Metadata.sol";

/**
 * @title DQURI
 * @dev tokenURI render library for DQ contract.
 * @author 0xAnimist (kanon.art)
 */
library DQURI {

  function packSVG(uint256 _tokenId, uint256 _sourceTokenId, address _sourceContract) public view returns(string memory) {
    string memory sourceContractName = IERC721Metadata(_sourceContract).name();
    string[9] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="40" class="base">DQ-NFT token #: ';

        parts[1] = Strings.toString(_tokenId);

        parts[2] = '</text><text x="10" y="60" class="base">';

        parts[3] = 'Source Contract Name: ';

        parts[4] = sourceContractName;

        parts[5] = '</text><text x="10" y="80" class="base">';

        parts[6] = 'Source Token Id: ';

        parts[7] = Strings.toString(_sourceTokenId);

        parts[8] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));

        return string(abi.encodePacked(output, parts[8]));
  }

  function packName(uint256 _tokenId, uint256 _sourceTokenId, address _sourceContract) public view returns(string memory) {
    string memory sourceContractName = IERC721Metadata(_sourceContract).name();
    return string(abi.encodePacked('"name": "', sourceContractName, ' #', Strings.toString(_sourceTokenId), ' (DQ NFT)",'));
  }

  function packDescription(uint256 _tokenId, uint256 _sourceTokenId, address _sourceContract) public view returns(string memory) {
    string memory sourceContractName = IERC721Metadata(_sourceContract).name();
    string memory description = '"description": "This token is set as the ERC721Delegable delegate of token #';
    return string(abi.encodePacked(description, Strings.toString(_sourceTokenId), ' of the NFT contract at ', toString(_sourceContract), ' (', sourceContractName,'). WARNING: Holders of delegate tokens can reassign the ERC721Delegable delegate role to another token at any time. Do not purchase delegate tokens unless they are first staked in a secure sale contract.",'));
  }

  function packVersion(uint256 _tokenId) public pure returns(string memory) {
    return '"version": "0.1",';
  }

  function packSourceContract(uint256 _tokenId, address _sourceContract) public pure returns(string memory) {
    string memory sourceContract = '"sourceContract": "';
    return string(abi.encodePacked(sourceContract, toString(_sourceContract), '",'));
  }

  function packSourceTokenId(uint256 _tokenId, uint256 _sourceTokenId) public pure returns(string memory) {
    string memory sourceTokenId = '"sourceTokenId": "';
    return string(abi.encodePacked(sourceTokenId, Strings.toString(_sourceTokenId), '",'));
  }

  function renderURI(
    string memory _name,
    string memory _description,
    string memory _version,
    string memory _sourceContract,
    string memory _sourceTokenId,
    string memory _svg
  ) public pure returns(string memory) {
    string memory metadata = string(abi.encodePacked(
      '{',
      _name,
      _description,
      _version,
      _sourceContract,
      _sourceTokenId
    ));

    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      metadata,
      '"image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(_svg)),
      '"}'))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }


  //Address to string encoding by k06a
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
