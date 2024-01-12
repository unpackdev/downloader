// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";

/// @title A multi-send contract for ERC-20 tokens and ETH.
/// @author Bitwave
/// @author Pat White
/// @author Inish Crisson
/// @notice Now with support for fallback functions. 
/// @notice This is intended to be deployed by a factory contract, hence why "owner" has been paramaterised. 
contract BitwaveMultiSend is ReentrancyGuard {
  
  address public owner;

  // A uint to produce a unique ID for each transaction.
  uint32 public paymentCount;
  uint8 public bwChainId;

  constructor(address _owner, uint8 _bwChainId) {
    owner = _owner;
    bwChainId = _bwChainId;
  }

  modifier restrictedToOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        _;
  }

  event multiSendPaymentExecuted(bytes id);

/// @notice Sends Eth to an array of addresses according to the values in a uint array.
/// @param _to An array of addresses to be paid.
/// @param _value An array of values to be paid to "_to" addresses.
/// @return _success A bool to indicate transaction success.
  function sendEth(address payable [] memory _to, uint256[] memory _value) public restrictedToOwner nonReentrant payable returns (bool _success) {
        // input validation
        require(_to.length == _value.length);
        require(_to.length <= 255);

        // count values for refunding sender
        uint256 beforeValue = msg.value;
        uint256 afterValue = 0;

        // Generate a unique ID for this transaction.
        emit multiSendPaymentExecuted(abi.encodePacked(address(this), paymentCount++, uint8(_value.length), bwChainId));

        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            afterValue = afterValue + (_value[i]);
            (bool sent, ) = _to[i].call{value: _value[i]}("");
            require(sent, "Failed to send Ether");
        }

        // send back remaining value to sender
        uint256 remainingValue = beforeValue - afterValue;
        if (remainingValue > 0) {
            (bool sent, ) = owner.call{value: remainingValue}("");
            require(sent, "Failed to send Ether");
        }
        return true;
  }

/// @notice Sends *ONE TYPE OF* ERC-20 token to an array of addresses according to the values in a uint array.
/// @param _tokenAddress The ERC-20 token address.
/// @param _to An array of addresses to be paid.
/// @param _value An array of values to be paid to "_to" addresses.
/// @return _success A bool to indicate transaction success.
  function sendErc20(address _tokenAddress, address[] memory _to, uint256[] memory _value) public restrictedToOwner nonReentrant returns (bool _success) {
      // input validation
      require(_to.length == _value.length);
      require(_to.length <= 255);

      // use the erc20 abi
      IERC20 token = IERC20(_tokenAddress);

      // Generate a unique ID for this transaction.
      emit multiSendPaymentExecuted(abi.encodePacked(address(this), paymentCount++, uint8(_value.length), bwChainId));

      // loop through to addresses and send value
      for (uint8 i = 0; i < _to.length; i++) {
          assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
      }
      return true;
  }
}