// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// Utils /////
import "./SafeERC20.sol";

/// Interfaces /////
import "./IVotes.sol";
import "./IGovernanceModule.sol";
import "./ISnapshotDelegation.sol";

///@title  UserProxy
///@notice Holds ERC20 token and votes on users behalf.
///        The proxy delegate calls to the upgradable governance diamond.
///        It is deployed by the Governance Module upon a users first governanceDeposit and can only
/// be called
///        via the Governance Module
contract UserProxy {
  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  ///@notice governance module which has deployed the proxy
  address immutable GOVERNANCE_MODULE;

  ///@notice when counting votes, Snapshot queries this contract address for delegates
  address constant DELEGATE_REGISTRY = 0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446;

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  ///@notice Initializes the UserProxy
  ///@param _governanceModule Address of the governance module
  constructor(address _governanceModule) {
    GOVERNANCE_MODULE = _governanceModule;
  }

  /*//////////////////////////////////////////////////////////////
                            ERC20 DELEGATION
    //////////////////////////////////////////////////////////////*/

  ///@notice Delegates voting power of this contract to another address.
  ///@param _delegate Address of delegate.
  ///@param _asset ERC20 token for delegation
  function delegateVotingRights(address _delegate, address _asset) external {
    IVotes(_asset).delegate(_delegate);
  }

  /*//////////////////////////////////////////////////////////////
                           SNAPSHOT DELEGATION
    //////////////////////////////////////////////////////////////*/

  ///@notice sets a delegate for snapshot-delegation strategy
  ///@param _id Snapshot namespace for which to delegate
  ///@param _delegate address of delegate
  function setDelegate(bytes32 _id, address _delegate) external {
    ISnapshotDelegation(DELEGATE_REGISTRY).setDelegate(_id, _delegate);
  }

  ///@notice revokes the delegation
  ///@param _id Snapshot namespace for which delegation is revoked
  function clearDelegate(bytes32 _id) external {
    ISnapshotDelegation(DELEGATE_REGISTRY).clearDelegate(_id);
  }

  /*//////////////////////////////////////////////////////////////
                                EIP-1271
    //////////////////////////////////////////////////////////////*/

  ///@notice Implementation of EIP 1271.
  ///        Returns whether the signature provided is valid for the provided data.
  ///@param _msgHash Hash of a message signed on the behalf of a contract
  ///@param _signature Signature byte array associated with _msgHash
  function isValidSignature(bytes32 _msgHash, bytes memory _signature)
    external
    view
    returns (bytes4)
  {
    require(_signature.length == 65, "TM: invalid signature length");
    address signer = _recoverSigner(_msgHash, _signature, 0);
    address proxyOwner = IGovernanceModule(GOVERNANCE_MODULE).proxyToUser(address(this));
    if (proxyOwner == signer) return 0x1626ba7e;
    else return 0xffffffff;
  }

  ///@notice Helper method to recover the signer at a given position from a list of concatenated
  /// signatures.
  ///@param _signedHash The signed hash
  ///@param _signatures The concatenated signatures.
  ///@param _index The index of the signature to recover.
  function _recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint256 _index)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
    // we jump 32 (0x20) as the first slot of bytes contains the length
    // we jump 65 (0x41) per signature
    // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
    // solhint-disable-next-line no-inline-assembly
    assembly {
      r := mload(add(_signatures, add(0x20, mul(0x41, _index))))
      s := mload(add(_signatures, add(0x40, mul(0x41, _index))))
      v := and(mload(add(_signatures, add(0x41, mul(0x41, _index)))), 0xff)
    }
    require(v == 27 || v == 28, "Utils: bad v value in signature");

    address recoveredAddress = ecrecover(_signedHash, v, r, s);
    require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
    return recoveredAddress;
  }
}
