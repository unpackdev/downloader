/*

  .,-:::::/ .,::::::::::::::::::    .::    .   .:::  ...      :::  .   .,::::::                             
,;;-'````'  ;;;;'''';;;;;;;;''''    ';;,  ;;  ;;;'.;;;;;;;.   ;;; .;;,.;;;;''''                             
[[[   [[[[[[/[[cccc      [[          '[[, [[, [[',[[     \[[, [[[[[/'   [[cccc                              
"$$c.    "$$ $$""""      $$            Y$c$$$c$P $$$,     $$$_$$$$,     $$""""                              
 `Y8bo,,,o88o888oo,__    88,            "88"888  "888,_ _,88P"888"88o,  888oo,__                            
   `'YMUP"YMM""""YUMMM   MMM             "M "M"    "YMMMMMP"  MMM "MMP" """"YUMMM    
   
                          
    ...    :::::::..       :::::::-.  :::.,::::::      :::::::. :::::::..       ...      :::  .   .,::::::  
 .;;;;;;;. ;;;;``;;;;       ;;,   `';,;;;;;;;''''       ;;;'';;';;;;``;;;;   .;;;;;;;.   ;;; .;;,.;;;;''''  
,[[     \[[,[[[,/[[['       `[[     [[[[[ [[cccc        [[[__[[\.[[[,/[[['  ,[[     \[[, [[[[[/'   [[cccc   
$$$,     $$$$$$$$$c          $$,    $$$$$ $$""""        $$""""Y$$$$$$$$c    $$$,     $$$_$$$$,     $$""""   
"888,_ _,88P888b "88bo,      888_,o8P'888 888oo,__     _88o,,od8P888b "88bo,"888,_ _,88P"888"88o,  888oo,__ 
  "YMMMMMP" MMMM   "W"       MMMMP"`  MMM """"YUMMM    ""YUMMMP" MMMM   "W"   "YMMMMMP"  MMM "MMP" """"YUMMM


                  ˙·٠•●♥ ƸӜ̵̨̄Ʒ ♥●•٠·˙·::[[ Д0sviДaniya krΞw ]]::˙·٠•●♥ ƸӜ̵̨̄Ʒ ♥●•٠·˙


JOIN THE REVOLUTION !

www.getwoke.io

https://t.me/WokeTokenOfficial

https://twitter.com/GetWokeio

HOW BOUT THEY CANCEL DEEZ NUTZ AYYYYYYYYYY

*/

// SPDX-License-Identifier: MIT

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Swapper.sol";

pragma solidity ^0.8.19;

contract WokeToken is ERC20Burnable, DirectSwapper, Ownable {
  using SafeERC20 for IERC20;

  event SetPair(address indexed pair, address indexed router);
  event WhitelistAddress(address indexed account, bool isExcluded);

  mapping(address => bool) public _whiteListed;
  mapping(address => bool) public _blacklisted;
  mapping(address => uint256) private _lastTransfer;

  mapping(address => LiquidityPairs) public _routerPairs;

  bool private reset = false;
  bool private swapping;

  uint8 public multiplier = 10;

  address payable public fundingWallet;

  uint256 public clearBlock;

  uint256 public constant DIVISOR = 100_000;

  // snipe and bot limiters
  uint256 public cooldown = 5;
  uint256 public initLimit = 50_000 * 10 ** decimals(); // max tx amount ( ~0.5 eth)

  uint256 public exitFee = 4200;
  uint256 public tokenThreshold = 100 * 10 ** decimals();

  constructor() ERC20("Woke", "WOKE") {
    _mint(msg.sender, 8_000_000_000 * 10 ** decimals());

    fundingWallet = payable(msg.sender);

    whitelistAddress(msg.sender, true);
    whitelistAddress(address(this), true);
  }

  receive() external payable {}

  function balanceOf(address account) public view override returns (uint256) {
    return super.balanceOf(account);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20) {
    super._beforeTokenTransfer(from, to, amount);
  }

  function whitelistAddress(address account, bool setting) public onlyOwner {
    require(_whiteListed[account] != setting, "Account already at setting");
    _whiteListed[account] = setting;

    emit WhitelistAddress(account, setting);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override(ERC20) {
    if (swapping || reset) return super._transfer(sender, recipient, amount);
    if (clearBlock == 0) require(_whiteListed[sender], "PreTrade");
    require(!_blacklisted[sender] && !_blacklisted[recipient], "!!blacklisted");

    if (
      !swapping &&
      _routerPairs[recipient].base != address(0) &&
      !_whiteListed[sender] &&
      !_whiteListed[recipient]
    ) {
      uint256 contractBalance = balanceOf(address(this));
      uint256 dynamicThreshold = amount / multiplier;

      uint256 liquidationAmount = contractBalance > 0 &&
        contractBalance > dynamicThreshold
        ? dynamicThreshold
        : contractBalance;

      uint256 feeRate;
      if (block.timestamp < clearBlock) feeRate = exitFee * multiplier;
      else feeRate = exitFee;

      uint256 fees = (amount * feeRate) / DIVISOR;
      amount -= fees;

      swapping = true;
      if (liquidationAmount != 0)
        super._transfer(address(this), recipient, liquidationAmount);

      super._transfer(sender, recipient, fees);

      _swapToCollateral(recipient);
      swapping = false;
    }

    super._transfer(sender, recipient, amount);
  }

  function _swapToCollateral(address targetPair) internal entryGuard {
    _swapSupportingFeeOnTransferTokens(
      targetPair,
      [address(this), _routerPairs[targetPair].base],
      fundingWallet
    );
  }

  function setExitFee(uint256 _exitFee) external onlyOwner {
    require(_exitFee <= 5000, "Max exit fee is 5%");
    exitFee = _exitFee;
  }

  function setPretrade(address pair, address base) external onlyOwner {
    require(clearBlock == 0, "Pretrade already set");
    clearBlock = block.number + 100;

    _routerPairs[pair].base = base;

    emit SetPair(pair, base);
  }

  function __TEST_CLEAR_PRETRADE(address pair) external onlyOwner {
    require(block.chainid == 1337, "not testnet");
    clearBlock = 0;
    _routerPairs[pair].base = address(0);
  }

  function addPair(address pair, address base) public onlyOwner {
    _routerPairs[pair].base = base;

    emit SetPair(pair, base);
  }

  function setReset(bool _reset) external onlyOwner {
    reset = _reset;
  }

  function setTokenThreshold(uint256 _tokenThreshold) external onlyOwner {
    tokenThreshold = _tokenThreshold;
  }

  function setFundingWallet(address payable _wallet) external onlyOwner {
    fundingWallet = _wallet;
    _whiteListed[address(_wallet)] = true;
  }

  function blacklistAddress(address account, bool value) external onlyOwner {
    _blacklisted[account] = value;
  }

  // The following functions are overrides required by Solidity.

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20) {
    super._burn(account, amount);
  }

  // internal-only function, required to override imports properly
  function _mint(address account, uint256 amount) internal override(ERC20) {
    super._mint(account, amount);
  }

  function rescueTokens(
    address recipient,
    address token,
    uint256 amount
  ) public onlyOwner returns (bool) {
    require(
      _routerPairs[token].base == address(0),
      "Can't transfer out LP tokens!"
    );

    require(IERC20(token).transfer(recipient, amount), "tx fail"); //use of the _ERC20 traditional transfer

    return true;
  }

  function rescueTokensSafe(
    address recipient,
    address token,
    uint256 amount
  ) public onlyOwner returns (bool) {
    require(
      _routerPairs[token].base == address(0),
      "Can't transfer out LP tokens!"
    );

    IERC20(token).safeTransfer(recipient, amount); //use of the _ERC20 traditional transfer

    return true;
  }

  function rescueEth(address payable recipient) public onlyOwner {
    recipient.transfer(address(this).balance);
  }
}
