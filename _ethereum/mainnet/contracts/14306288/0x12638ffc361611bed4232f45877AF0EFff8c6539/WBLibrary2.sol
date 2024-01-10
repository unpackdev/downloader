// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ECDSAUpgradeable.sol";

library WBLibrary2 {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  function uri(uint256 tokenId) external pure returns (string memory) {
    // That should be plenty already although not enough for uint256.
    bytes memory buffer = new bytes(32);
    // Do not start at 32 or you will end at -1 which is not good for Uint
    for (uint256 i = buffer.length; i > 0; i--) {
      buffer[i - 1] = _HEX_SYMBOLS[tokenId & 0xf];
      tokenId >>= 4;
    }
    return string(bytes.concat("https://wallburners.art/meta/0x", buffer));
  }

  function checkTokenAndGetSigner(
    uint256 tokenId,
    uint256 price,
    address owner,
    address buyer,
    uint256 deadline,
    uint256 cutAmount,
    address cutAccount,
    bytes memory signature,
    bytes32 domainSeparator,
    bool tokenExists,
    address currentOwner
  ) public view returns (address) {
    bytes32 digest = ECDSAUpgradeable.toTypedDataHash(
      domainSeparator,
      keccak256(abi.encode(
        keccak256("SP(uint256 tokenId,uint256 price,address owner,address buyer,uint256 deadline,uint256 cutAmount,address cutAccount)"),
        tokenId, price, owner, buyer, deadline, cutAmount, cutAccount
      ))
    );
    address signer = ECDSAUpgradeable.recover(
      ECDSAUpgradeable.toEthSignedMessageHash(digest),
      signature
    );

    if (tokenExists) {
      require(owner == currentOwner, "WBR: invalid token  - owner changed");
    }
    require(signer != address(0), "WBR: invalid price signature");
    require(block.timestamp < deadline, "WBR: price signature expired");
    return signer;
  }
}
