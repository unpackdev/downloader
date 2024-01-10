
// SPDX-License-Identifier: BSD-3

pragma solidity ^0.8.0;

import "./Delegated.sol";
import "./ECDSA.sol";

contract Signed is Delegated{
  using ECDSA for bytes32;

  string internal _secret;
  address internal _signer;

  function setSignedConfig( string memory secret, address signer ) public onlyOwner{
    _secret = secret;
    _signer = signer;
  }

  function createHash( string memory data ) internal view returns ( bytes32 ){
    return keccak256( abi.encodePacked( address(this), msg.sender, data, _secret ) );
  }

  function getSigner( bytes32 hash, bytes memory signature ) internal pure returns( address ){
    return hash.toEthSignedMessageHash().recover( signature );
  }

  function isAuthorizedSigner( string memory data, bytes calldata signature ) internal view virtual returns( bool ){
    address extracted = getSigner( createHash( data ), signature );
    return extracted == _signer;
  }

  function verifySignature( string memory data, bytes calldata signature ) internal view {
    require( isAuthorizedSigner( data, signature ), "Signature verification failed" );
  }
}
