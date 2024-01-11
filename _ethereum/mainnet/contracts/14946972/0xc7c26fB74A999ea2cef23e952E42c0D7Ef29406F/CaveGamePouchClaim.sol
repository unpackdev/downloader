// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";
import "./WoolPouch.sol";

contract CaveGamePouchClaim is
  Initializable,
  OwnableUpgradeable,
  PausableUpgradeable
{
  using ECDSA for bytes32;

  address public signer;
  WoolPouch public woolPouch;

  mapping(address => bool) public claimed;

  event Claim(
    address recipient,
    uint128 amount
  );

  /**
   * instantiates contract
   * @param _signer the address of the server signing the messages
   * @param _woolPouch reference to WoolPouch
  */
  function initialize(
    address _signer,
    address _woolPouch
  ) external initializer {
    __Ownable_init();
    __Pausable_init();

    signer = _signer;
    woolPouch = WoolPouch(_woolPouch);
  }


  /**
   * claims a wool pouch for an address
   * @param signature the signature created off-chain to verify access
   * @param amount the amount of WOOL being claimed (only used for verification)
   */
  function claim(bytes memory signature, uint128 amount) external whenNotPaused {
    require(!claimed[_msgSender()], "CANNOT CLAIM POUCH TWICE");
    bytes memory packed = abi.encode(_msgSender(), amount);
    bytes32 messageHash = keccak256(packed);
    require(
      messageHash.toEthSignedMessageHash().recover(signature) == signer,
      "THAT SIGNATURE IS A FAKE"
    );

    claimed[_msgSender()] = true;
    woolPouch.mintWithoutClaimable(_msgSender(), amount, 365 * 4);

    emit Claim(_msgSender(), amount);
  }

  /**
   * enables owner to pause / unpause claiming
   * @param _p the new pause state
  */
  function setPaused(bool _p) external onlyOwner {
    if (_p) _pause();
    else _unpause();
  }

  /**
   * updates the signer of claims
   * @param _signer the new signing address
  */
  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }
}