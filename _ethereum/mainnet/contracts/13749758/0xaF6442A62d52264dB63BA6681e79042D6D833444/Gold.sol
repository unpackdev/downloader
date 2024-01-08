// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;





import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC20Upgradeable.sol";



pragma solidity ^0.8.0;

interface IGold {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Gold is ERC20Upgradeable, IGold, OwnableUpgradeable {

  mapping(address => bool) controllers;       
  mapping(address => uint256) private lastWrite;


  function initialize() initializer public {

          __ERC20_init("Gold", "GLD");
          __Ownable_init();

  }

  function mint(address to, uint256 amount) external override {                    
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  modifier disallowIfStateIsChanging() {
    require(controllers[_msgSender()] || lastWrite[tx.origin] < block.number, "hmmmm what doing?");
    _;
  }

  function updateOriginAccess() external override {
    require(controllers[_msgSender()], "Only controllers can call this");
    lastWrite[tx.origin] = block.number;
  }

  function balanceOf(address account) public view virtual override disallowIfStateIsChanging returns (uint256) {
    require(controllers[_msgSender()] || lastWrite[account] < block.number, "hmmmm what doing?");
    return super.balanceOf(account);
  }

  function transfer(address recipient, uint256 amount) public virtual override disallowIfStateIsChanging returns (bool) {
    require(controllers[_msgSender()] || lastWrite[_msgSender()] < block.number, "hmmmm what doing?");
    return super.transfer(recipient, amount);

  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return super.allowance(owner, spender);
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    return super.approve(spender, amount);
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
    return super.decreaseAllowance(spender, subtractedValue);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20Upgradeable, IGold) disallowIfStateIsChanging returns (bool) {
    require(controllers[_msgSender()] || lastWrite[sender] < block.number , "hmmmm what doing?");

    if(controllers[_msgSender()]) {
      _transfer(sender, recipient, amount);
      return true;
    }

    return super.transferFrom(sender, recipient, amount);
  }




}