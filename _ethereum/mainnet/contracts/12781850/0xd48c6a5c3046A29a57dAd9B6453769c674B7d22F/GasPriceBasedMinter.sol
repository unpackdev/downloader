// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC20Mintable.sol";
import "./Context.sol";
import "./Ownable.sol";

contract BellCurveParametersStorage {
    
    uint256 immutable public a;
    uint256 immutable public b;
    uint256 immutable public c;
    uint256 immutable public d;

    uint256 constant SIG_DIGITS = 3;

    constructor(uint256 _a, uint256 _b, uint256 _c, uint256 _d) {
      a = _a;
      b = _b;
      c = _c;
      d = _d;
    }

    function bellCurve(uint256 x) internal view returns (uint256 y) {
      uint256 decimals = 10 ** SIG_DIGITS;
      // since it is all uints, we will use a ternary to keep it positive 
      uint256 xDiffC = x > c ? (x - c) : (c - x);
      // this complex set of math gets us a bell curve with the ouput in SIG_DIGITS worth of decimals
      return (10 ** (18 - SIG_DIGITS)) * ((d * decimals * decimals) / (decimals + (((xDiffC * decimals) / a))**(2 * b) / decimals));
    }
}

contract GasPriceBasedMinter is BellCurveParametersStorage, Context, Ownable {
    ERC20Mintable public erc20;

    uint256 immutable public blockNumberUpTo;
    bytes32 constant ZERO_HASH = 0xbc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a;

    constructor(uint256 _blockNumberUpTo, uint256 _a, uint256 _b, uint256 _c, uint256 _d) BellCurveParametersStorage(_a, _b, _c, _d) {
      blockNumberUpTo = _blockNumberUpTo;
    }

    function setErc20(address _erc20) public onlyOwner {
      erc20 = ERC20Mintable(_erc20);
    }

    function mintableTokenAtGasPrice(uint256 gasPrice)
      public
      view
      returns (uint256 amount)
    {
      amount = bellCurve(gasPrice);
    }

    fallback() external payable {
      require(block.number < blockNumberUpTo, "CAN'T $MINT ANYMORE");
      require(keccak256(msg.data) == ZERO_HASH, "CAN'T $MINT FROM MACHINE");
      require(msg.value == 0, "DON'T DONATE");
      uint256 amount = mintableTokenAtGasPrice(tx.gasprice);
      // mint amount to _msgSender
      erc20.mint(_msgSender(), amount);
    }
}