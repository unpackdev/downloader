// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ContractDeployerV1 {
  event Deployed(address createdContract, address sender);

  function deploy(bytes memory bytecode, uint256 nonce)
    external
    payable
    returns (address)
  {
    bytes32 salt = keccak256(abi.encodePacked(msg.sender, nonce));

    address createdContract;
    assembly {
      createdContract := create2(
        callvalue(),
        add(bytecode, 0x20),
        mload(bytecode),
        salt
      )
    }
    require(
      createdContract != address(0),
      'contract deployment failed'
    );

    // sighash of `owner()`
    bytes4 ownerSig = hex"8da5cb5b";
    bool isOwner;

    // ContractDeployer can be given ownership during creation
    // of contracts that implement Ownable. We want to transfer ownership
    // back to the deployer.
    assembly {
        let ownerSigLoc := mload(0x40)
        mstore(ownerSigLoc, ownerSig)
        let ownerAddressLocation := add(mload(0x40), 0x4)

        let hasOwner := staticcall(gas(), createdContract, ownerSigLoc, 0x4, ownerAddressLocation, 0x20)
        if hasOwner {
            isOwner := eq(address(), mload(ownerAddressLocation))
        }
    }

    if (isOwner) {
        try Ownable(createdContract).transferOwnership(msg.sender) {
        } catch { }
    }

    emit Deployed(createdContract, msg.sender);
    return createdContract;
  }
}
