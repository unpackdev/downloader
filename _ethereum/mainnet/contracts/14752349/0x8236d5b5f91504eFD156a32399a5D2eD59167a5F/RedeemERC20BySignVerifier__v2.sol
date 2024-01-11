// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";

contract RedeemERC20BySignVerifier__v2 is Ownable {
  using ECDSA for bytes32;

  mapping(uint256 => bool) public isRedeemed;
  address public signVerifier;
  address public erc20Address;
  uint256 public amountPerToken;

  constructor(address _erc20Address, uint256 _amountPerToken) {
    erc20Address = _erc20Address;
    signVerifier = 0xF504941EF7FF8f24DC0063779EEb3fB12bAc8ab7;
    amountPerToken = _amountPerToken;
    require(address(IERC20(_erc20Address)) != address(0), "Must pass in an ERC20 token for redemption");
  }

  function setSignVerifier(address verifier) external onlyOwner {
    signVerifier = verifier;
  }

  function redeemTokens(
    bytes memory sig,
    uint256 blockExpiry,
    uint256 tokenId
  ) external {
    bytes32 message = getClaimSigningHash(blockExpiry, msg.sender, tokenId).toEthSignedMessageHash();
    require(ECDSA.recover(message, sig) == signVerifier, "Permission to call this function failed");
    require(block.number < blockExpiry, "Signature expired");
    require(isRedeemed[tokenId] == false, "tokenId has already redeemed tokens");

    isRedeemed[tokenId] = true;
    require(IERC20(erc20Address).transfer(msg.sender, amountPerToken), "Transfer of redeemed token failed");
  }

  function getClaimSigningHash(
    uint256 blockExpiry,
    address recipient,
    uint256 tokenId
  ) public view returns (bytes32) {
    return keccak256(abi.encodePacked(blockExpiry, recipient, tokenId, address(this)));
  }

  function getSignVerifier() external view returns (address) {
    return signVerifier;
  }

  function getIsRedeemed(uint256 tokenId) public view returns (bool) {
    return isRedeemed[tokenId];
  }

  function setAmountPerToken(uint256 amount) external onlyOwner {
    amountPerToken = amount;
  }
}
