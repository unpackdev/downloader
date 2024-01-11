// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ContractDeployer is Ownable {
  event Deployed(address createdContract, address sender);

  address public deployTokenAddress;

  bool private _isDeployTokenLocked;

  constructor(address payable _owner) {
    transferOwnership(_owner);
    deployTokenAddress = _owner;
  }

  // See details here:
  // https://github.com/0xsequence/create3/blob/5f2569de603d2d75610746b419f7453aded9ff2c/contracts/Create3.sol#L13-L34
  bytes internal constant CONTRACT_INITIALIZER_BYTECODE =
    hex'67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3';
  bytes32 internal constant KECCAK256_CONTRACT_INITIALIZER_BYTECODE =
    0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

  function deploy(bytes memory bytecode, uint256 nonce)
    external
    payable
    returns (address)
  {
    require(msg.sender == deployTokenAddress, 'invalid sender');

    // Assembly code requires in-memory variable.
    // We copy the constant in here.
    bytes memory contractInitializerBytecode = CONTRACT_INITIALIZER_BYTECODE;

    address contractInitializerAddress;
    assembly {
      contractInitializerAddress := create2(
        0,
        add(contractInitializerBytecode, 0x20),
        mload(contractInitializerBytecode),
        nonce
      )
    }
    require(
      contractInitializerAddress != address(0),
      'contractInitializer contract deployment failed'
    );

    (bool success, ) = contractInitializerAddress.call{value: msg.value}(
      bytecode
    );
    address deployedContract = _generateContractAddress(
      contractInitializerAddress
    );
    require(
      success && deployedContract.code.length > 0,
      'target deployment failed'
    );

    emit Deployed(deployedContract, msg.sender);
    return deployedContract;
  }

  function setDeployTokenAddress(address _deployerNFTAddress) public onlyOwner {
    require(!_isDeployTokenLocked, 'cannot change NFT contract address');

    deployTokenAddress = _deployerNFTAddress;
    _isDeployTokenLocked = true;
  }

  function generateContractAddress(uint256 _nonce)
    public
    view
    returns (address)
  {
    address initializerAddress = _toAddress(
      keccak256(
        abi.encodePacked(
          hex'ff',
          address(this),
          _nonce,
          KECCAK256_CONTRACT_INITIALIZER_BYTECODE
        )
      )
    );

    return _generateContractAddress(initializerAddress);
  }

  function _generateContractAddress(address contractInitializerAddress)
    internal
    pure
    returns (address)
  {
    return
      _toAddress(
        keccak256(
          abi.encodePacked(hex'd6_94', contractInitializerAddress, hex'01')
        )
      );
  }

  function _toAddress(bytes32 hash) internal pure returns (address) {
    return address(uint160(uint256(hash)));
  }
}
