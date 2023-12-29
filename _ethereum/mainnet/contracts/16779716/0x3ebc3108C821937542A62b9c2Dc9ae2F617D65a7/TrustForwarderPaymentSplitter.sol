// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./PaymentSplitter.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Context.sol";

contract TrustForwarderPaymentSplitter is PaymentSplitter, AccessControl {

  bytes32 public constant TRUSTEE_ROLE = keccak256("TRUSTEE_ROLE");

  constructor(
    address[] memory _payees,
    uint256[] memory _shares
  )
    payable
    PaymentSplitter(_payees, _shares)
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    for(uint256 i = 0; i < _payees.length; i++) {
      _setupRole(TRUSTEE_ROLE, _payees[i]);
    }
  }

  function release(
    address payable _account
  )
    public
    override
    onlyRole(TRUSTEE_ROLE)
  {
    super.release(_account);
  }

  function release(
    IERC20 _token,
    address _account
  )
    public
    override
    onlyRole(TRUSTEE_ROLE)
  {
    super.release(_token, _account);
  }
}
