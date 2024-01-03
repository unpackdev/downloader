/*

  This token serves as a derivative within Omni Market Protocol. Its function is 
  as a token proxy operated by the debt controller module, which rebalances yield 
  and symbolizes a fluid debt stance.

  It should be noted that this is not the official $OMM governance token, and it 
  will retain its illiquidity on Uniswap V3.

  Omni Market Links:
  Website:             https://omnimarket.finance/
  Dapp:                https://app.omnimarket.finance/
  Twitter:             https://twitter.com/Omni_Market
  Docs:                https://omni-market.gitbook.io/
  Telegram:            https://t.me/OmniMarketPortal
  Articles:            https://medium.com/@omnimarket
  
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract oUSDC {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Omni Market USDC";
    string public symbol = "oUSDC";
    uint8 public decimals = 18;

    address public debtController = 0xAE7EFAe157675b66e16cfF44aEaE20B50fb3E423;
    address public implementation = 0x000000000000000000000000000000000000dEaD;

    modifier onlyDebtController() {
        require(msg.sender == debtController, "Not debtController");
        _;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function executeImplementationLogic() public onlyDebtController {
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature("executeImplementationLogic()")
        );

        require(success);
    }

    function upgradeDebtController(address _debtController) public onlyDebtController {
      debtController = _debtController;
    }

    function upgradeImplementation(address _implementation) public onlyDebtController {
      implementation = _implementation;
    }
}
