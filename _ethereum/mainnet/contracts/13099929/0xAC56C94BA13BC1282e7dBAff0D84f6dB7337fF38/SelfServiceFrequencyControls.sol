// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Whitelist.sol";
import "./ISelfServiceFrequencyControls.sol";
import "./NativeMetaTransaction.sol";

contract SelfServiceFrequencyControls is 
ISelfServiceFrequencyControls, 
Whitelist,
NativeMetaTransaction("SelfServiceFrequencyControls")
{

  function _msgSender()
  internal
  view
  override(Context, NativeMetaTransaction)
  returns (address payable sender) {
    return NativeMetaTransaction._msgSender();
  }

  using SafeMath for uint256;

  // frozen out for..
  uint256 public freezeWindow = 1 days;

  // When the current time period started
  mapping(address => uint256) public frozenTil;

  // Frequency override list for users - you can temporaily add in address which disables the 24hr check
  mapping(address => bool) public frequencyOverride;

  constructor() public {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    super.addAddressToWhitelist(_msgSender());
  }

  function canCreateNewEdition(address artist) external override view returns (bool) {
    if (frequencyOverride[artist]) {
      return true;
    }
    return (block.timestamp >= frozenTil[artist]);
  }

  function recordSuccessfulMint(address artist, uint256 totalAvailable, uint256 priceInWei) external override onlyIfWhitelisted(_msgSender()) returns (bool) {
    frozenTil[artist] = block.timestamp.add(freezeWindow);
    return true;
  }

  function setFrequencyOverride(address artist, bool value) external onlyIfWhitelisted(_msgSender()) {
    frequencyOverride[artist] = value;
  }

  /**
   * @dev Sets freeze window
   * @dev Only callable from owner
   */
  function setFreezeWindow(uint256 _freezeWindow) onlyIfWhitelisted(_msgSender()) public {
    freezeWindow = _freezeWindow;
  }

  /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyIfWhitelisted(_msgSender()) public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    payable(_withdrawalAccount).transfer(address(this).balance);
  }
}
