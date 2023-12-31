// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IQuadPassportStore.sol";
import "./PoolBase.sol";

/// @notice This contract describes Pool's KYC checks
abstract contract PoolDID is PoolBase {
  bool public kycRequired;

  function _getKYCAttributes(address lender) internal override {
    if (kycRequired && lender != manager) {
      (IQuadPassportStore.Attribute[] memory attr, uint256 queriedAttributes) = factory
        .getKYCAttributes(lender);

      require(attr.length == queriedAttributes, 'ALM');

      require(attr[0].value != bytes32(0), 'CAM');
      require(
        (attr[0].value != keccak256(abi.encodePacked('US')) && // United States of America
          attr[0].value != keccak256(abi.encodePacked('BY')) && // Belarus
          attr[0].value != keccak256(abi.encodePacked('CD')) && // Democratic Republic of the Congo
          attr[0].value != keccak256(abi.encodePacked('CU')) && // Cuba
          attr[0].value != keccak256(abi.encodePacked('KP')) && // Korea Democratic People's Republic
          attr[0].value != keccak256(abi.encodePacked('IR')) && // Iran
          attr[0].value != keccak256(abi.encodePacked('IQ')) && // Iraq
          attr[0].value != keccak256(abi.encodePacked('LB')) && // Lebanon
          attr[0].value != keccak256(abi.encodePacked('LY')) && // Libya
          attr[0].value != keccak256(abi.encodePacked('ML')) && // Mali
          attr[0].value != keccak256(abi.encodePacked('MM')) && // Myanmar
          attr[0].value != keccak256(abi.encodePacked('NI')) && // Nicaragua
          attr[0].value != keccak256(abi.encodePacked('RU')) && // Russia
          attr[0].value != keccak256(abi.encodePacked('SD')) && // Sudan
          attr[0].value != keccak256(abi.encodePacked('SO')) && // Somalia
          attr[0].value != keccak256(abi.encodePacked('SS')) && // South Sudan
          attr[0].value != keccak256(abi.encodePacked('SY'))), // Syria
        'RCT'
      );

      require(uint256(attr[1].value) <= 5, 'HAS');
    }
  }
}
