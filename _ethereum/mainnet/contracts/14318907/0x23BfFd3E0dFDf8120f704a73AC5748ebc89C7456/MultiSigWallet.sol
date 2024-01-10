// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "./ECDSA.sol";

contract MultiSigWallet {
    event AddSigner(address _signer);
    event RemoveSigner(address _signer);

    using ECDSA for bytes32;

    mapping(address => bool) public isSigner;
    address[] public signers;
    uint public numConfirmationsRequired;

    modifier onlySigner() {
        require(isSigner[msg.sender], "singer not valid!");
        _;
    }

    constructor(
      address[] memory _signers,
      uint _numConfirmationsRequired)
    {
      require(_signers.length > 0, "singer required");
      require(
            _numConfirmationsRequired > 1 &&
                _numConfirmationsRequired <= _signers.length,
            "invalid number of required confirmations"
        );

      for (uint i = 0; i < _signers.length; i++) {
        _addSigner(_signers[i]);
      }
      numConfirmationsRequired = _numConfirmationsRequired;
    }

    function _addSigner(address _signer) internal {
      require(_signer != address(0), "invalid signer");
      require(!isSigner[_signer], "signer not unique");

      isSigner[_signer] = true;
      signers.push(_signer);

      emit AddSigner(_signer);
    }

    function _removeSigner(address _signer) internal {
      require(_signer != address(0), "invalid signer");
      require(isSigner[_signer], "signer not exist");

      isSigner[_signer] = false;

      emit RemoveSigner(_signer);
    }

    function addSigner(
      bytes[] memory _signatures,
      address _signer,
      uint _nonce) external onlySigner
    {
      bytes32 txHash = getTxHash("addSigner(bytes[],address,uint)",_nonce);
      require(isValid(_signatures, txHash), "invalid signature");

      _addSigner(_signer);
    }

    function removeSigner(
      bytes[] memory _signatures,
      address _signer,
      uint _nonce) external onlySigner
    {
      bytes32 txHash = getTxHash("removeSigner(bytes[],address,uint)",_nonce);
      require(isValid(_signatures, txHash), "invalid signature");

      _removeSigner(_signer);
    }

    function getSigners() public view returns (address[] memory) {
        return signers;
    }

    function getTxHash(string memory signature, uint _nonce) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this),bytes4(keccak256(bytes(signature))),_nonce));
    }

    function isValid(bytes[] memory _signatures, bytes32 _txHash)
        public
        view
        returns (bool)
    {
      require(
            _signatures.length == numConfirmationsRequired,
            "invalid number of required confirmations"
        );

      bytes32 ethSignedHash = _txHash.toEthSignedMessageHash();

      for (uint i = 0; i < _signatures.length; i++) {
          address signer_ = ethSignedHash.recover(_signatures[i]);
          bool valid = isSigner[signer_];

          if (!valid) {
              return false;
          }
      }

      return true;
    }

}
