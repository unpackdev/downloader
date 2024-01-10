// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./KnitWhitelist.sol";
import "./KnitSecurity.sol";
import "./MultiSigWallet.sol";


contract KnitToken is ERC20, ERC20Pausable, Ownable{
  event Mint(address _to,uint256 amount);

  KnitWhitelist public whitelist;
  KnitSecurity public knitSecurity;
  MultiSigWallet public multiSig;

  constructor(
    string memory name,
    string memory symbol,
    address _multiSig,
    address _whitelist,
    address _knitSecurity)
    ERC20(name, symbol)
  {
   whitelist = KnitWhitelist(_whitelist);
   knitSecurity = KnitSecurity(_knitSecurity);
   multiSig = MultiSigWallet(_multiSig);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  modifier _onlySigner() {
      require(multiSig.isSigner(msg.sender), "singer not valid!");
      _;
  }

  function mint(address to, uint256 amount, bytes[] memory _signatures, uint _nonce) public whenNotPaused {
    bytes32 txHash = multiSig.getTxHash('mint(address,uint256,bytes[],uint)',_nonce);
    require(multiSig.isValid(_signatures, txHash),"invalid signature");
    require(!knitSecurity.isGloballyPaused(), "KnitSecurity: minting paused globally");
    require(whitelist.isValid(address(this), to, amount), "KnitWhitelist: wallet is not valid!");

    _mint(to, amount);
    emit Mint(to, amount);
  }

  function burn(uint256 amount) public virtual {
    require(!knitSecurity.isGloballyPaused(), "KnitSecurity: Burning paused globally!");
    _burn(_msgSender(), amount);
  }

  function burnFrom(address account, uint256 amount) public virtual {
      require(!knitSecurity.isGloballyPaused(), "KnitSecurity: Burning paused globally!");
      uint256 currentAllowance = allowance(account, _msgSender());
      require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
      _approve(account, _msgSender(), currentAllowance - amount);
      _burn(account, amount);
  }

  function pause() public _onlySigner {
    _pause();
  }

  function unpause() public _onlySigner {
    _unpause();
  }
}
