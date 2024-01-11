//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

//     /$$$$$$$  /$$$$$$$$  /$$$$$$        /$$$$$$$   /$$$$$$   /$$$$$$
//    | $$____/ |_____ $$/ /$$__  $$      | $$__  $$ /$$__  $$ /$$__  $$
//    | $$           /$$/ | $$  \__/      | $$  \ $$| $$  \ $$| $$  \ $$
//    | $$$$$$$     /$$/  | $$$$$$$       | $$  | $$| $$$$$$$$| $$  | $$
//    |_____  $$   /$$/   | $$__  $$      | $$  | $$| $$__  $$| $$  | $$
//     /$$  \ $$  /$$/    | $$  \ $$      | $$  | $$| $$  | $$| $$  | $$
//    |  $$$$$$/ /$$/     |  $$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
//     \______/ |__/       \______/       |_______/ |__/  |__/ \______/
//
//    576DAO.com
//    June 2022

contract Dao576Token is Ownable, ERC20Permit, ERC20Votes {
  bool public saleActive;
  bool public teamClaimed;
  address public signerAddress = 0x9f6B54d48AD2175e56a1BA9bFc74cd077213B68D;
  uint32 public tokensPerEther = 1000;
  string public hashKey = '576-dao';

  uint32 public constant MAX_SUPPLY = 12500000;

  uint32 public totalSold;

  mapping(address => uint32) public tokenClaimed;

  constructor() ERC20('576DAO', '576') ERC20Permit('Dao576Token') {
    _mint(msg.sender, MAX_SUPPLY);
  }

  /** User */
  function purchase(uint32 _maxAmount, bytes calldata _signature, uint32 _amount) external payable {
    require(saleActive, 'Sale is not active');
    require(eligibleByWhitelist(msg.sender, _maxAmount, _signature, _amount), "Not eligible"); // eligible to claim
    require(_amount >= tokensPerEther, 'Minimum purchase invalid');
    require(_amount * (1 ether / tokensPerEther) <= msg.value, 'Invalid Ether value');
    require(IERC20(address(this)).balanceOf(address(this)) >= _amount, 'Sold out');

    tokenClaimed[msg.sender] += _amount;
    totalSold += _amount;

    IERC20(address(this)).transfer(msg.sender, _amount);
  }

  /** View */
  function decimals() public view virtual override returns (uint8) {
    return 0;
  }

  function eligibleByWhitelist(address _account, uint32 _maxAmount, bytes memory _signature, uint32 _amount) internal view returns (bool) {
    bytes32 message = keccak256(abi.encodePacked(hashKey, _maxAmount, _account));
    return validSignature(message, _signature) && tokenClaimed[_account] + _amount <= _maxAmount;
  }

  /** Admin */
  function toggleSaleActive() external onlyOwner {
    saleActive = !saleActive;
  }

  function updateTokenRate(uint32 _rate) external onlyOwner {
    tokensPerEther = _rate;
  }

  function updateSigner(address _account) external onlyOwner {
    signerAddress = _account;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, 'Invalid signature length');

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  function validSignature(bytes32 _message, bytes memory _signature) internal view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == signerAddress;
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }
}
