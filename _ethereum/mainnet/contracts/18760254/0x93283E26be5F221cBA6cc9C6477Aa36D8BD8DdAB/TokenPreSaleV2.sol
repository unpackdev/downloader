// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenPreSale.sol";
import "./ITether.sol";

contract TokenPreSaleV2 is TokenPreSale {
  // * Version
  function version() override public pure returns (string memory) {
      return "2";
  }

  // * 특정 ERC-20 토큰으로 프리세일 토큰 구매
  function buyTokenBySpecificToken(uint256 amount, address specificToken) virtual override public whenNotPaused {
    require(amount > 0, "can not buy zero tokens.");

    uint256 price = specificTokenPrice(specificToken);
    require(price > 0, "not registered specific token.");
    
    uint256 targetTotalPrice = (amount * price) / 1 ether;
    _validateERC20BalAndAllowance(_msgSender(), specificToken, targetTotalPrice);
    _transferToken(specificToken, _msgSender(), recipient, targetTotalPrice);

    _validateERC20BalAndAllowance(tokenSpender, tokenAddress, amount);
    _transferToken(tokenAddress, tokenSpender, _msgSender(), amount);
    emit BuyTokenBySpecificToken(_msgSender(), amount, specificToken);
  }

  // * 테더로 프리세일 토큰 구매
  function buyTokenByTether(uint256 amount, address tetherAddress) virtual public whenNotPaused {
    require(amount > 0, "can not buy zero tokens.");

    uint256 price = specificTokenPrice(tetherAddress);
    require(price > 0, "not registered specific token.");
    
    uint256 targetTotalPrice = (amount * price) / 1 ether;
    _validateTetherBalAndAllowance(_msgSender(), tetherAddress, targetTotalPrice);
    _transferTether(tetherAddress, _msgSender(), recipient, targetTotalPrice);

    _validateERC20BalAndAllowance(tokenSpender, tokenAddress, amount);
    _transferToken(tokenAddress, tokenSpender, _msgSender(), amount);
    emit BuyTokenBySpecificToken(_msgSender(), amount, tetherAddress);
  }

  // * 테더 allowance와 잔액 검증
  function _validateTetherBalAndAllowance(address _spender, address currency, uint256 amount) virtual internal view {
    require(
      ITether(currency).balanceOf(_spender) >= amount &&
        ITether(currency).allowance(_spender, address(this)) >= amount,
      "!BALTether"
    );
  }

  // * 테더 인출(transferFrom)
  function _transferTether(address _tokenAddress, address from, address to, uint256 amount) virtual internal {
    ITether(_tokenAddress).transferFrom(from, to, amount);
  }
}
