// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./BridgeToken.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract BridgeBase is Ownable, Pausable {
  address public admin;
  IToken public token;
  mapping(address => mapping(uint => bool)) public processedNonces;

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    address to,
    string operation,
    uint amount,
    uint date,
    uint nonce,
    bytes signature,
    Step indexed step
  );

  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
  }

  function setAdmin(address new_admin) external onlyOwner {
    require(new_admin != address(0), "zero address not allowed");
    admin = new_admin;
  }

  function burn(address to, uint amount, uint nonce, bytes calldata signature) external virtual {}

  function mint(
    address from, 
    address to, 
    uint amount, 
    uint nonce,
    bytes calldata signature
  ) external virtual {}

  /**
    * @dev Pause `contract` - pause events.
    *
    * See {BEP20Pausable-_pause}.
    */
  function pauseContract() external virtual onlyOwner {
      _pause();
  }
  
  /**
    * @dev Pause `contract` - pause events.
    *
    * See {BEP20Pausable-_pause}.
    */
  function unPauseContract() external virtual onlyOwner {
      _unpause();
  }

  /**
    * @dev Hook that is called before any transfer of tokens. This includes
    * minting and burning.
    *
    * Calling conditions:
    *
    * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
    * will be to transferred to `to`.
    * - when `from` is zero, `amount` tokens will be minted for `to`.
    * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
    * - `from` and `to` are never both zero.
    *
    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    */
  function _beforeTokenTransfer() internal virtual {}

  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = splitSignature(sig);
  
    return ecrecover(message, v, r, s);
  }

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
  
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  
    return (v, r, s);
  }
}
