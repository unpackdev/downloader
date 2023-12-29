pragma solidity ^0.5.13;

contract EXCH {
    function distribute() public payable returns (uint256);
}

contract TOKEN {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract UniswapExchangeInterface {
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
}

contract UniswapV1Distribution {
    EXCH private stableth = EXCH(address(0xe01e2a3CEaFA8233021Fc759E5A69863558326b6));
    TOKEN private erc20 = TOKEN(address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39));
    UniswapExchangeInterface private uniHEXInterface = UniswapExchangeInterface(address(0x05cDe89cCfa0adA8C88D5A23caaa79Ef129E7883));

    constructor() public {
    }

    function() payable external {
    }

    function accounting() public {
      uint256 _balance = erc20.balanceOf(address(this));
      erc20.approve(address(0x05cDe89cCfa0adA8C88D5A23caaa79Ef129E7883), _balance);
      uniHEXInterface.tokenToEthSwapInput(_balance, 1, now + 120);

      if (address(this).balance > 0) {
        stableth.distribute.value(address(this).balance)();
      }
    }
}