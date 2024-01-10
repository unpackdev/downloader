// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Ownable.sol";
import "./Context.sol";
import "./KnitToken.sol";
import "./MultiSigWallet.sol";

contract KnitFactory is Ownable {
  event CreateAsset(address indexed token);
  event ChangeOwnership(address indexed owner);

  address[] public knitAssets;
  address whitelist;
  address knitSecurity;
  address multiSigAddress;
  MultiSigWallet public multiSigWallet;

  constructor(
    address _whitelist,
    address _knitSecurity,
    address _multiSigWallet)
  {
    whitelist = _whitelist;
    knitSecurity = _knitSecurity;
    multiSigAddress = _multiSigWallet;
    multiSigWallet = MultiSigWallet(_multiSigWallet);
  }

  modifier _onlySigner() {
      require(multiSigWallet.isSigner(msg.sender), "singer not valid!");
      _;
  }

  function createAsset(
    string memory name,
    string memory symbol,
    bytes[] memory _signatures,
    uint _nonce
  ) public _onlySigner returns (address newToken) {

    bytes32 txHash = multiSigWallet.getTxHash('createAsset(string,string,bytes[],uint)',_nonce);
    require(multiSigWallet.isValid(_signatures, txHash),"invalid signature");

    KnitToken newCredits = new KnitToken(
        name,
        symbol,
        multiSigAddress,
        whitelist,
        knitSecurity
    );

    knitAssets.push(address(newCredits));
    changeOwnership(address(newCredits));

    emit CreateAsset(address(newCredits));
    emit ChangeOwnership(_msgSender());

    return address(newCredits);
  }

  function changeOwnership(address target) private{
    (bool success, ) = target.call(abi.encodeWithSignature("transferOwnership(address)",_msgSender()));
    require(success, "Transaction execution reverted.");
  }
}
