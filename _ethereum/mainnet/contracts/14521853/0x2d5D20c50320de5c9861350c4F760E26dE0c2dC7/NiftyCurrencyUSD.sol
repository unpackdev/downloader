// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract NiftyCurrencyUSD is ERC20 {

   address constant public _default = 0x00000000000000000000000000000000DeaDBeef;

   constructor() ERC20("USD on Nifty Gateway", "USD") {
      _mint(_default, 100);
      _burn(_default, 100);
   }

   function decimals() public view virtual override returns (uint8) {
      return 2;
   }
   
}