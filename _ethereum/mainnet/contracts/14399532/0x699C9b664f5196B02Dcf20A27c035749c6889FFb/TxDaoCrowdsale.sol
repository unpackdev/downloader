//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract TxDaoCrowdsale is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string _defaultBaseURI = "https://metadata.txdao.org/";
    bool public _saleIsActive = true;
    address[] public _signers;
    uint256[] public _usedVouchers;

    constructor(string memory tokenName_,
                string memory tokenSymbol_,
                string memory defaultBaseURI_,
                address signer_
              )
        ERC721(tokenName_, tokenSymbol_)
        payable
    {
      _defaultBaseURI = defaultBaseURI_;
      _signers.push(signer_);
    }

    function _baseURI()
        internal view override
        returns (string memory)
    {
        return _defaultBaseURI;
    }

    function setBaseURI(string memory newBaseURI_)
        public
        onlyOwner
    {
        _defaultBaseURI = newBaseURI_;
    }

    function toggleSaleState()
        public
        onlyOwner
    {
        _saleIsActive = !_saleIsActive;
    }

    function addSigner(address _signer)
      public onlyOwner
    {
      _signers.push(_signer);
    }

    function removeSigner(uint _signerIndex)
      public onlyOwner
    {
      delete _signers[_signerIndex];
    }

    function voucherIsUsed(uint256 voucherId)
      public
      view
      returns (bool)
    {
        for (uint i = 0; i < _usedVouchers.length; i++) {
          if (_usedVouchers[i] == voucherId) {
            return true;
          }
        }
        return false;
    }

    function totalTokens()
      public
      view
      returns (uint256)
    {
        return _tokenIds.current();
    }

    function mintToken(bytes memory signature, uint256 spots, uint256 voucherId, uint256 tokenQty)
        public
    {
        require(verify(signature, spots, voucherId), "This address is not whitelisted.");
        require(_saleIsActive, "Sale must be active");
        require(tokenQty <= spots, "Quantity exceeded");
        require(!voucherIsUsed(voucherId), "Voucher already used");

        _usedVouchers.push(voucherId);

        for(uint i = 0; i < tokenQty; i++) {
          _tokenIds.increment();

          uint256 newItemId = _tokenIds.current();
          _safeMint(msg.sender, newItemId);
        }
    }


    // Contract level metadata
    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract")) : "";
    }

    function getMessageHash(address _address, uint256 _spots, uint256 _voucherId)
      public
      pure
      returns (bytes32)
    {
      return keccak256(abi.encodePacked(_address, _spots, _voucherId));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
      public
      pure
      returns (bytes32)
    {
      /*
      Signature is produced by signing a keccak256 hash with the following format:
      "\x19Ethereum Signed Message\n" + len(msg) + msg
      */
      return
          keccak256(
              abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
          );
    }


    function verify(bytes memory signature, uint256 spots, uint256 voucherId)
      private
      view
      returns (bool)
    {
      bytes32 messageHash = getMessageHash(msg.sender, spots, voucherId);
      bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

      address signer = recoverSigner(ethSignedMessageHash, signature);

      // Check if the signer is any of the contract valid signers

      for (uint i = 0; i < _signers.length; i++) {
        if (_signers[i] == signer) {
          return true;
        }
      }
      return false;
    }


    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
      public
      pure
      returns (address)
    {
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

      return ecrecover(_ethSignedMessageHash, v, r, s);
    }


    function splitSignature(bytes memory sig)
      public
      pure
      returns (
          bytes32 r,
          bytes32 s,
          uint8 v
      )
    {
      require(sig.length == 65, "invalid signature length");

      assembly {
          /*
          First 32 bytes stores the length of the signature

          add(sig, 32) = pointer of sig + 32
          effectively, skips first 32 bytes of signature

          mload(p) loads next 32 bytes starting at the memory address p into memory
          */

          // first 32 bytes, after the length prefix
          r := mload(add(sig, 32))
          // second 32 bytes
          s := mload(add(sig, 64))
          // final byte (first byte of the next 32 bytes)
          v := byte(0, mload(add(sig, 96)))
      }

      // implicitly return (r, s, v)
    }

}
