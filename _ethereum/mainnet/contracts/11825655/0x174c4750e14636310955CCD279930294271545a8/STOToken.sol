// SPDX-License-Identifier: UNLICENSED
// Inspired on https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/presets/ERC20PresetMinterPauser.sol
pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "./Context.sol";
import "./Initializable.sol";
import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./ERC20Capped.sol";

import "./ERC20Whitelisted.sol";

contract STOToken is Initializable, ContextUpgradeSafe, AccessControlUpgradeSafe, ERC20Whitelisted, ERC20CappedUpgradeSafe, ERC20PausableUpgradeSafe {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 private _maxPoolPercent;
    uint256 private _minPoolPercent;

    event SwapTokens(address indexed from, address indexed to, uint256 tokens);

    function initialize(string memory name, string memory symbol, uint256 supply, uint256 minPoolPercent, uint256 maxPoolPercent) public {
      __STOToken_init(name, symbol, supply, minPoolPercent, maxPoolPercent);
    }

    function __STOToken_init(string memory name, string memory symbol, uint256 supply, uint256 minPoolPercent, uint256 maxPoolPercent) internal initializer {
      __Context_init_unchained();
      __AccessControl_init_unchained();
      __ERC20_init_unchained(name, symbol);
      __ERC20Whitelisted_init();
      __ERC20Capped_init(supply);
      __Pausable_init_unchained();
      __ERC20Pausable_init_unchained();
      __STOToken_init_unchained(minPoolPercent, maxPoolPercent);
    }

    function __STOToken_init_unchained(uint256 minPoolPercent, uint256 maxPoolPercent) internal initializer {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(PAUSER_ROLE, _msgSender());
      _minPoolPercent = minPoolPercent;
      _maxPoolPercent = maxPoolPercent;
    }

    function fullySold() public view returns(bool){
      uint256 cap = cap();

      if (totalSupply() >= cap.sub(cap.mul(_maxPoolPercent).div(100))) {
        return true;
      }
      return false;
    }

    function couldReceiveContribution(uint256 tokens) public view returns(bool){
      uint256 cap = cap();
      if (cap.sub(cap.mul(_minPoolPercent).div(100)) >= totalSupply().add(tokens)) {
        return true;
      }
      return false;
    }

    function grantMinterRole(address minterAddress) public onlyOwner {
      grantRole(MINTER_ROLE, minterAddress);
    }

    function grantPauserRole(address pauserAddress) public onlyOwner {
      grantRole(PAUSER_ROLE, pauserAddress);
    }

    function getPoolTokens() public onlyOwner {
      _mint(_msgSender(), cap().sub(totalSupply()));
    }

    function swapTokens(address _from, address _to) public onlyOwner {
      require(_from != address(0), "STOToken: _from address is the zero address");
      require(_to != address(0), "STOToken: _from address is the zero address");
      require(balanceOf(_from) > 0, "STOToken: no tokens to transfer");

      uint256 fromBalance = balanceOf(_from);
      _transfer(_from, _to, fromBalance);

      emit SwapTokens(_from, _to, fromBalance);
    }

    function mint(address to, uint256 amount) public {
      require(hasRole(MINTER_ROLE, _msgSender()), "STOToken: must have minter role to mint");
      require(!fullySold(), "STOToken: Token fully sold");
      require(couldReceiveContribution(amount), "STOToken: tokens reserved for pool");
      _mint(to, amount);
    }

    function pause() public {
      require(hasRole(PAUSER_ROLE, _msgSender()), "STOToken: must have pauser role to pause");
      _pause();
    }

    function unpause() public {
      require(hasRole(PAUSER_ROLE, _msgSender()), "STOToken: must have pauser role to unpause");
      _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Whitelisted, ERC20CappedUpgradeSafe, ERC20PausableUpgradeSafe) {
      super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}
