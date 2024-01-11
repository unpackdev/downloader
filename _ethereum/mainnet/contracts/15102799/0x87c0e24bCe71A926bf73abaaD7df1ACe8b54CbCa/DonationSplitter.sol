////////////////////////////////////////////////////////
//                                                    //
//     ____   __   __ _   __  ____  __  __   __ _     //
//    (    \ /  \ (  ( \ / _\(_  _)(  )/  \ (  ( \    //
//     ) D ((  O )/    //    \ )(   )((  O )/    /    //
//    (____/ \__/ \_)__)\_/\_/(__) (__)\__/ \_)__)    //
//    ____  ____  __    __  ____  ____  ____  ____    //
//   / ___)(  _ \(  )  (  )(_  _)(_  _)(  __)(  _ \   //
//   \___ \ ) __// (_/\ )(   )(    )(   ) _)  )   /   //
//   (____/(__)  \____/(__) (__)  (__) (____)(__\_)   //
//                                                    //
//      Built by:    https://cryptoforcharity.io      //
//      Author:      buzzybee.eth                     //
//                                                    //
////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";


contract DonationSplitter is Initializable, OwnableUpgradeable {
  Charity[] private _charities;
  address private _owner;
  address private _weth;
  address[] private _tokens;
  uint32 _ownerCut;

  struct Charity {
    address account;
    uint32 percentage;
  }

  error InvalidInputs();
  function initialize(
    address[] calldata charities,
    uint32[]  calldata percentages,
    address            owner,
    address[] calldata tokens
  ) initializer public {
    if (charities.length != percentages.length) revert InvalidInputs();

    _ownerCut = 100;

    for (uint i = 0; i < charities.length; i++) {
      _charities.push(Charity(charities[i], percentages[i]));
      _ownerCut -= percentages[i];
    }

    if (_ownerCut < 0) revert InvalidInputs();

    _owner = owner;
    _weth = tokens[0];
    _tokens = tokens;

    __Ownable_init();
    transferOwnership(owner);
  }

  receive () external payable {
    for (uint i = 0; i < _charities.length; i++) {
      _transfer(_charities[i].account, msg.value * _charities[i].percentage / 100);
    }
    _transfer(_owner, msg.value * _ownerCut / 100);
  }


  function drain(address[] calldata erc20sToWithdraw) external onlyOwner {
    (bool success,) = _owner.call{value: address(this).balance}("");
    
    if (erc20sToWithdraw.length > 0) {
      for(uint i=0; i<erc20sToWithdraw.length; i++) {
        _transferERC20(erc20sToWithdraw[i], _owner, 0);
      }
    }

    for(uint i=0; i<_tokens.length; i++) {
      _transferERC20(_tokens[i], _owner, 0);
    }
  }

  function withdrawWETH() external onlyOwner {
    _withdrawERC20(_weth);
  }

  function withdrawTokens() external onlyOwner {
    for(uint i=0; i<_tokens.length; i++) {
      _withdrawERC20(_tokens[i]);
    }
  }

  function updateTokens(address[] calldata tokens) external onlyOwner {
    _tokens = tokens;
    _weth = _tokens[0];
  }

  function getTokens() external view returns (address[] memory) {
    return _tokens;
  }

  function _withdrawERC20(address id) private {
    uint bal = IERC20(id).balanceOf(address(this));

    for (uint i = 0; i < _charities.length; i++) {
      _transferERC20(
        id,
        _charities[i].account,
        bal * _charities[i].percentage / 100
      );
    }

    _transferERC20(id, _owner, bal * _ownerCut / 100);
  }

  function _transferERC20(address id, address dest, uint value) private {
    if (value == 0) {
      value = IERC20(id).balanceOf(address(this));
    }

    if (value == 0) {
      return;
    }

    IERC20(id).transferFrom(address(this), dest, value);
  }

  // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
  error TransferFailed();
  function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
  }
}