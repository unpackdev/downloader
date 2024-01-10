// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


/// ----------------------------------------------------------------------------
/// Errors
/// ----------------------------------------------------------------------------

error NotAdmin();
error TooFewAdmins();

abstract contract Adminlist {

  /// ------------------------------------------------------------------------
  /// Events
  /// ------------------------------------------------------------------------

  event AdminAddressAdded(address addr);
  event AdminAddressRemoved(address addr);

  /// ------------------------------------------------------------------------
  /// Variables
  /// ------------------------------------------------------------------------

  address[] public adminlist;

  /// ------------------------------------------------------------------------
  /// Modifiers
  /// ------------------------------------------------------------------------

  modifier onlyAdmin()
  {
    if(!onList(msg.sender)) revert NotAdmin();
    _;
  }

  /// ------------------------------------------------------------------------
  /// Functions
  /// ------------------------------------------------------------------------

  function onList(address _addr)
    public
    view
    returns (bool)
  {
    bool found = false;
    uint256 length = adminlist.length;
    for(uint256 i = 0; i < length; i = uncheckedInc(i) )
    {
      if(adminlist[i] == _addr) {
        found = true;
      }
    }
    return found;
  }

  function addAddressToAdminlist(address _addr) 
    public 
    onlyAdmin
    returns(bool success) 
  {
    if (!onList(_addr)) {
      adminlist.push(_addr);
      emit AdminAddressAdded(_addr);
      success = true; 
    }
  }

  function removeAddressFromAdminlist(address _addr) 
    public 
    onlyAdmin
    returns(bool success) 
  {
    if (onList(_addr)) {
      
      // do the compact array shuffle
      uint256 length =  adminlist.length;
      if(length <= 1) revert TooFewAdmins();
      for(uint256 i = 0; i < length; i = uncheckedInc(i))
      {
        if(adminlist[i] == _addr)
        {
          adminlist[i] = adminlist[length-1];
          adminlist.pop();
          break;
        }
      }
      emit AdminAddressRemoved(_addr);
      success = true;
    }
  }

  function _setupAdmin(address _addr) 
    internal 
    virtual 
  {
    adminlist.push(_addr);
    emit AdminAddressAdded(_addr);
  }

  /// ------------------------------------------------------------------------
  /// Utility
  /// ------------------------------------------------------------------------

  // https://gist.github.com/hrkrshnn/ee8fabd532058307229d65dcd5836ddc#the-increment-in-for-loop-post-condition-can-be-made-unchecked
  function uncheckedInc(uint256 _i)
    private
    pure 
  returns (uint256) {
    unchecked {
      return _i + 1;
    }
  }
}