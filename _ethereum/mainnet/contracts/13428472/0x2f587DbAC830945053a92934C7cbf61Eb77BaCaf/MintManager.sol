// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721Enumerable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

interface BaseTokenContract {
      function mintTokenPrivileged(address _recipient) external payable;
}

contract MintManagerTokenWhitelist is Initializable, OwnableUpgradeable {

    address public whitelistAddress;
    address public tokenAddress;

    uint256 public mintLimit;
    uint256 public mintCount;
    bool public enabled;

    mapping (uint256 => bool) whitelistTokenIsRedeemed;

    function initialize(address _whitelistAddress, address _tokenAddress, uint256 _mintLimit) public initializer {
      __Ownable_init();
      whitelistAddress = _whitelistAddress;
      tokenAddress = _tokenAddress;
      mintLimit = _mintLimit;
      mintCount = 0;
      enabled = false;
    }

    function whitelistedMint() public payable {
      // Contract must be enabled
      require(enabled == true, "Whitelist minting not enabled");

      // Check below the limit
      require(mintCount < mintLimit, "Whitelist limit reached");
      mintCount++;

      // Check that whitelist token has not been redeemed
      uint256 ownedTokenID = IERC721Enumerable(whitelistAddress).tokenOfOwnerByIndex(msg.sender, 0);
      require(whitelistTokenIsRedeemed[ownedTokenID] == false, "Token already redeemed");
      whitelistTokenIsRedeemed[ownedTokenID] = true;

      // Send msg.value, which base contract will check
      BaseTokenContract(tokenAddress).mintTokenPrivileged{value: msg.value}(msg.sender);
    }

    function setMintingEnabled(bool _enabled) public onlyOwner {
        enabled = _enabled;
    }

}
