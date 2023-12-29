// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IToken {
    function collectTaxes() external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
}

contract Safe {

    address public token;
    address public pair;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint public amount; // Should be ~5% of ETH in LP

    receive() external payable {

      if(IERC20(WETH).balanceOf(pair) >= amount && amount != 0) {
        IToken(token).collectTaxes();
      }

    }

    function execute(address _token, address _pair, uint _amount) public {

      token = _token;
      pair = _pair;
      amount = _amount;

      IToken(token).collectTaxes();

    }

}
