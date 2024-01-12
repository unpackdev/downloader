//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Notary.sol";
import "./RevokableOwnableDelegatable.sol";

/**
 * @title NotaryServiceDelegatable
 * @author Kames Geraghty
 * @notice Delegatable off-chain Citizenship issuance permissions.
 */
contract NotaryServiceDelegatable is RevokableOwnableDelegatable {
  /// @notice CitizenAlpha instance
  address private immutable _citizenAlpha;

  constructor(address _citizenAlpha_) RevokableOwnableDelegatable("NotaryServiceDelegatable") {
    _citizenAlpha = _citizenAlpha_;
  }

  /**
   * @notice Get Notary instance
   * @return notary address
   */
  function getNotary() external view returns (address notary) {
    return _citizenAlpha;
  }

  /**
   * @notice Issue Citizenship via Notary exeuction
   * @dev Inteneded to be used with Delegatable.eth invoke for third-party execution.
   * @param newCitizen address
   */
  function issue(address newCitizen) external {
    require(owner() == _msgSender(), "NotaryServiceDelegatable:not-authorized");
    Notary(_citizenAlpha).issue(newCitizen);
  }
}
