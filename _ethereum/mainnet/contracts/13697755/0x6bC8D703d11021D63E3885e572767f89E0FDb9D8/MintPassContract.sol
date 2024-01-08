// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Built by Satoshi's Closet

// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
// https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155

import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract MintPassContract is ERC1155, ERC1155Supply {
  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  address public owner;
  bool private _paused;
  bool private _whitelist_only;
  
  // shared payout
  struct Shareholder {
    uint share;
    address payable shareholder_address;
  }

  Shareholder[] public shareholders;

  event Payout(address indexed _to, uint _value);
  
  mapping(address => bool) public whitelist;
    
  constructor(string memory _name,
              string memory _symbol,
              string memory _uri,
              address payable[] memory _whitelist,
              uint[] memory _shares,
              address payable[] memory _shareholder_addresses) ERC1155(_uri) {
    for (uint i = 0; i < _whitelist.length; i++) {
      whitelist[_whitelist[i]] = true;
    }

    name = _name;
    symbol = _symbol;
    
    owner = msg.sender;
    _paused = false;
    _whitelist_only = true;

    // there should be at least one shareholder
    assert(_shareholder_addresses.length > 0);

    // the _shares and _shareholder_addresses provided should be the same length
    assert(_shares.length == _shareholder_addresses.length);

    // keep track of the total number of shares
    uint _total_number_of_shares = 0;
    for (uint i = 0; i < _shares.length; i++) {
      _total_number_of_shares += _shares[i];
      Shareholder memory x = Shareholder({share: _shares[i], shareholder_address: _shareholder_addresses[i]});
      shareholders.push(x);
    }

    // there should be exactly 10,000 shares, this amount is used to calculate payouts
    assert(_total_number_of_shares == 10000);
  }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

  modifier whenNotPaused(){
    require(!_paused);
    _;
  }

  modifier whenPaused(){
    require(_paused);
    _;
  }  

  event Mint(address indexed _minter, uint _amount);

  function mint(uint256 amount) public payable whenNotPaused() {
    require(totalSupply(1) + amount <= 300, "Total supply is 300");
    require(msg.value == (0.04 ether * amount), "Insufficient minting fee");

    // during the first seven days, only those in the whitelist can mint once
    if (_whitelist_only) {
      require(whitelist[msg.sender] == true, "Sender not on whitelist. Cannot mint during whitelist period.");
      require(amount == 1, "Mint capped at 1 per whitelist address per transaction.");
      // whitelist[msg.sender] = false;
    } else {
      require(amount == 1, "Mint capped at 1 per address per transaction.");
    }

    emit Mint(msg.sender, amount);
    
    _mint(msg.sender, 1, amount, "");
  }

  // once the royalty contract has a balance, call this to payout to the shareholders
  function payout() public payable onlyOwner whenNotPaused returns (bool) {
    // the balance must be greater than 0
    assert(address(this).balance > 0);

    // get the balance of ETH held by the royalty contract
    uint balance = address(this).balance;
    for (uint i = 0; i < shareholders.length; i++) {

      // 10,000 shares represents 100.00% ownership
      uint amount = balance * shareholders[i].share / 10000;

      // https://solidity-by-example.org/sending-ether/
      // this considered the safest way to send ETH
      (bool success, ) = shareholders[i].shareholder_address.call{value: amount}("");

      // it should not fail
      require(success, "Transfer failed.");

      emit Payout(shareholders[i].shareholder_address, amount);
    }
    return true;
  }
  
  // required by ERC1155Supply
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function pause() public onlyOwner whenNotPaused {
    _paused = true;
  }

  function unpause() public onlyOwner whenPaused {
    _paused = false;
  }

  function is_whitelisted(address _address) public view returns (bool) {
    return whitelist[_address];
  }

  function get_whitelist_only() public view returns (bool) {
    return _whitelist_only;
  }

  function set_whitelist_only() public onlyOwner {
    _whitelist_only = true;
  }

  function unset_whitelist_only() public onlyOwner {
    _whitelist_only = false;
  }  
  // https://solidity-by-example.org/sending-ether/
  // receive is called when msg.data is empty.
  receive() external payable {}

  // https://solidity-by-example.org/sending-ether/
  // fallback function is called when msg.data is not empty.
  fallback() external payable {}  
}
