// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Mintable.sol";
import "./ERC721.sol";
import "./LondonBurnAshen.sol";
import "./LondonBurnGift.sol";
import "./LondonBurnNoble.sol";
import "./LondonBurnPristine.sol";
import "./LondonBurnEternal.sol";
import "./LondonBurnMinterBase.sol";

contract LondonBurnMinter is LondonBurnMinterBase, LondonBurnNoble, LondonBurnAshen, LondonBurnGift, LondonBurnPristine, LondonBurnEternal {
  constructor(
      address _mintableNFT, 
      address _payableErc20,
      address _externalBurnableERC721,
      address _sushiswap
  ) LondonBurnMinterBase(_mintableNFT, _payableErc20, _externalBurnableERC721, _sushiswap) {
  }
}