// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IERC777.sol";
import "./IERC1820Registry.sol";
import "./IERC777Recipient.sol";
import "./SafeMath.sol";
import "./Administered.sol";

struct payout {
  uint32 timestamp;
  uint256 amount;
}

interface MintableToken is IERC777 {  
    function mint(
      address account,
      uint256 amount,
      bytes memory userData,
      bytes memory operatorData
    ) external;  
}

contract Staking is IERC777Recipient, Administered {
  using SafeMath for uint256;

  IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

  MintableToken private _token;
  
  bool private _isClosed;

  uint32 private _period;
  uint8 private _interest;

  mapping(address => payout[]) private _payouts;

  event Accepted(address from, uint256 amount, uint32 payAt);
  event Requested(address by, address to, uint256 amount);

  constructor (address token, uint8 interest, uint32 period) 
    //public 
    Administered(msg.sender)
  {
    _token = MintableToken(token);
    _interest = interest;
    _period = period;

    _isClosed = false;

    _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));        
  }

  function isClosed() public view returns (bool) {
    return _isClosed;
  }

  function close() public onlyAdmin {
    require(!_isClosed, "Already closed.");
    _isClosed = true;
  }

  function assignOperator(address operator) public onlyAdmin {
    _token.authorizeOperator(operator);
  }

  function tokensReceived(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
  ) external override {
    require(msg.sender == address(_token), "Staking: Invalid token");
    require(!_isClosed, "Staking is closed");

    uint256 increase = amount.mul(_interest).div(100);
    uint32 payAt = uint32(block.timestamp) + _period;
    uint256 total = amount.add(increase);
    _payouts[from].push(payout({
      timestamp: payAt,
      amount: total
    }));
    
    _token.mint(address(this), increase, "", "");
    emit Accepted(from, total, payAt);
  }

  function request() public {
    requestOf(msg.sender);
  }

  function requestOf(address bidder) public {

    require(_payouts[bidder].length > 0, "Staking: no scheduled payouts for address");

    bool isAnyPayoutAvailable = false;
    uint16 n = uint16(_payouts[bidder].length);
    uint256 amountToSend = 0;
    for (uint16 i = n; i-- > 0; ) {
      if(block.timestamp > _payouts[bidder][i].timestamp) {
        isAnyPayoutAvailable = true;
        amountToSend = amountToSend.add(_payouts[bidder][i].amount);
        if(_payouts[bidder].length > 1) {
          n = uint16(_payouts[bidder].length) - 1;
          _payouts[bidder][i].amount = _payouts[bidder][n].amount;
          _payouts[bidder][i].timestamp = _payouts[bidder][n].timestamp;
        }
        _payouts[bidder].pop();
      }
    }

    if(isAnyPayoutAvailable) {
      _token.send(bidder, amountToSend, "");
      emit Requested(msg.sender, bidder, amountToSend);
    } else {
      revert("Staking: no available payout");
    }
  }    

  function payoutsOf(address bidder) public view returns (payout[] memory) {
    return _payouts[bidder];
  }  

}