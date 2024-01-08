// SPDX-License-Identifier: BUSL-1.1
import "./Ownable.sol";
import "./ISelfServiceAccessControls.sol";
import "./NativeMetaTransaction.sol";

contract SelfServiceAccessControls is 
Ownable, 
ISelfServiceAccessControls,
NativeMetaTransaction("SelfServiceAccessControls")
{

  function _msgSender()
  internal
  view
  override(Context, NativeMetaTransaction)
  returns (address payable sender) {
    return NativeMetaTransaction._msgSender();
  }

  // Simple map to only allow certain artist create editions at first
  mapping(address => bool) public allowedArtists;

  // When true any existing NR artist can mint their own editions
  bool public openToAllArtist = false;

  /**
   * @dev Controls is the contract is open to all
   * @dev Only callable from owner
   */
  function setOpenToAllArtist(bool _openToAllArtist) onlyOwner public {
    openToAllArtist = _openToAllArtist;
  }

  /**
   * @dev Controls who can call this contract
   * @dev Only callable from owner
   */
  function setAllowedArtist(address _artist, bool _allowed) onlyOwner public {
    allowedArtists[_artist] = _allowed;
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function isEnabledForAccount(address account) public override view returns (bool) {
    if (openToAllArtist) {
      return true;
    }
    return allowedArtists[account];
  }

  /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyOwner public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    payable(_withdrawalAccount).transfer(address(this).balance);
  }
}
