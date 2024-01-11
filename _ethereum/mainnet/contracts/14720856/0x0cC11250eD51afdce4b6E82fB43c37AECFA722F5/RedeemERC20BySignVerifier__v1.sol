// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";

contract RedeemERC20BySignVerifier__v1 is Ownable {
  using ECDSA for bytes32;

  mapping(uint256 => uint256) public redeemableTokenBalance;
  address public signVerifier;
  address public erc20Address;

  constructor(address _erc20Address) {
    erc20Address = _erc20Address;
    signVerifier = 0xF504941EF7FF8f24DC0063779EEb3fB12bAc8ab7;
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
    require(redeemableTokenBalance[tokenId] > 0, "No tokens available to claim for the tokenId");
    require(
      IERC20(erc20Address).transfer(msg.sender, redeemableTokenBalance[tokenId]),
      "Transfer of redeemed token failed"
    );
    redeemableTokenBalance[tokenId] = 0;
  }

  function fundRedemptions(uint256[] memory tokenIds, uint256 amountPerToken) external onlyOwner {
    require(amountPerToken > 0, "Amount per token must be greater than zero");
    require(tokenIds.length > 0, "At least one token must be added");
    IERC20 erc20 = IERC20(erc20Address);
    require(
      erc20.allowance(msg.sender, address(this)) >= tokenIds.length * amountPerToken,
      "Minimum allowance is amount per token x amount of tokens"
    );
    require(
      erc20.transferFrom(msg.sender, address(this), tokenIds.length * amountPerToken),
      "TransferFrom of redemption token failed"
    );

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      redeemableTokenBalance[tokenIds[i]] += amountPerToken;
    }
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

  function getRedeemableTokenBalance(uint256 tokenId) public view returns (uint256) {
    return redeemableTokenBalance[tokenId];
  }
}
