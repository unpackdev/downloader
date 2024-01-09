// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IMetaPool.sol";
import "./IERC20.sol";

// solhint-disable func-name-mixedcase
contract MetaPoolMock is IMetaPool {
  address public lpToken;

  address[2] public tokens;

  constructor(address _lpToken, address[2] memory _tokens) {
    lpToken = _lpToken;
    tokens = _tokens;
  }

  function calc_token_amount(uint256[2] memory amounts, bool) external pure override returns (uint256 minted) {
    for (uint8 i = 0; i < 2; i++) {
      minted += amounts[i];
    }
  }

  function add_liquidity(uint256[2] memory amounts, uint256) external override returns (uint256 minted) {
    for (uint8 i = 0; i < 2; i++) {
      IERC20 token = IERC20(tokens[i]);
      if (amounts[i] > 0) {
        require(token.allowance(msg.sender, address(this)) >= amounts[i], "MetaPoolMock::add_liquidity: token not allowance");
        token.transferFrom(msg.sender, address(this), amounts[i]);
      }
      minted += amounts[i];
    }
    IERC20(lpToken).transfer(msg.sender, minted);
  }
}
