/*

  Website:    https://omnimarket.finance/
  Dapp:       https://app.omnimarket.finance/
  Twitter:    https://twitter.com/Omni_Market
  Docs:       https://omni-market.gitbook.io/
  Telegram:   https://t.me/OmniMarketPortal
  Articles:   https://medium.com/@omnimarket

*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Buffer.sol";

contract OMM is Buffer, IERC20 {

    uint public totalSupply;
    uint8 public decimals = 18;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    string private _name = "Omni Market";
    string private _symbol = "OMM";

    constructor (address _owner, uint _amount) {
      owner = _owner;

      balanceOf[owner] += _amount;
      totalSupply += _amount;
      emit Transfer(address(0), owner, _amount);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
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

    function transfer(address recipient, uint amount) external returns (bool) {
        require(live);

        balanceOf[msg.sender] -= amount;

        if (msg.sender == pool) {

          uint noTaxAmount = deductTax(msg.sender, amount);
          balanceOf[recipient] += noTaxAmount;

          uint tokenThreshold = totalSupply * buyLimit / 10000;
          require(tokenThreshold >= balanceOf[recipient]);

          emit Transfer(msg.sender, recipient, noTaxAmount);

        } else {

          balanceOf[recipient] += amount;
          emit Transfer(msg.sender, recipient, amount);

        }

        return true;

    }

    /**
     * @dev Deducts tax from buy order and returns the recipient's
     * transfer amount without the tax.
    */
    function deductTax(address sender, uint amount) private returns (uint) {
        uint256 tax = amount * buyFee / 10000;
        balanceOf[address(this)] += tax;
        emit Transfer(sender, address(this), tax);

        return amount - tax;
    }


}
