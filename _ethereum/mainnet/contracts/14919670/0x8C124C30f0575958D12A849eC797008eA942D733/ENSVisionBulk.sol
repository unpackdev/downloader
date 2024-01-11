// SPDX-License-Identifier: o0o0o0o0o00o
// lcfr.eth
// birdapp/github: @lcfr_eth
// deployed: 0x22256a2812f7a771b8b224e4fb34c6f245f3e330
// http://ens.vision

pragma solidity ^0.8.7;

import "./IETHRegistrarController.sol";

contract ENSVisionBulk {

  address public ENS = 0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5;

  IETHRegistrarController controller = IETHRegistrarController(ENS);

  address owner;
  address multisig;

  constructor(address _multisig) {
    owner = msg.sender;
    multisig = _multisig;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "not owner.");
    _;
  }

  function _updateOwner(address _newOwner) external onlyOwner {
    owner = _newOwner;
  }

  function _adminWithdraw() external onlyOwner {
    (bool sent,) = multisig.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function commitAll(bytes32[] calldata _commitments) external {
    for ( uint i = 0; i < _commitments.length; ++i ) {
      controller.commit(_commitments[i]);
    }
  }

  function registerAll(string[] calldata _names, bytes32[] calldata _secrets, uint256 _duration) external payable { 
    require(_names.length == _secrets.length, "names/secrets length mismatch");

    for( uint i = 0; i < _names.length; ++i ) {
      uint price = controller.rentPrice(_names[i], _duration);
      controller.register{value: price}(_names[i], msg.sender, _duration, _secrets[i]);
    }

  }

  function priceAll(string[] calldata _names, uint256 _duration) external view returns(uint total) {
    for (uint i = 0; i < _names.length; ++i) {
      total += controller.rentPrice(_names[i], _duration);
    }
  }

  function multicall(address _who, bytes[] calldata _what) external returns(bytes[] memory results) {
    results = new bytes[](_what.length);
    for(uint i = 0; i < _what.length; ++i) {
        (bool success, bytes memory result) = _who.delegatecall(_what[i]);
        require(success);
        results[i] = result;
    }
    return results;
  }

}