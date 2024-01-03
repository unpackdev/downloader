// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

import "./ICover.sol";
import "./IERC20.sol";
import "./IProtocol.sol";
import "./IRollover.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @title Rollover zap for Cover Protocol that auto redeems and rollover the coverage to the next cover, it does not sell or buy tokens for sender
 * @author crypto-pumpkin@github
 */
contract Rollover is IRollover {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /// @notice rollover for sender
  function rollover(address _cover, uint48 _newTimestamp) external override {
    rolloverAccount(_cover, _newTimestamp, msg.sender);
  }

  /// @notice rollover for a different account (from sender)
  function rolloverAccount(
    address _cover,
    uint48 _newTimestamp,
    address _account
  ) public override {
    ICover cover = ICover(_cover);
    uint48 expirationTimestamp = cover.expirationTimestamp();
    require(expirationTimestamp != _newTimestamp && block.timestamp < _newTimestamp, "Rollover: invalid expiry");

    IProtocol protocol = IProtocol(cover.owner());
    bool acceptedClaim = cover.claimNonce() != protocol.claimNonce();
    require(!acceptedClaim, "Rollover: there is an accepted claim");

    (, uint8 expirationStatus) = protocol.expirationTimestampMap(_newTimestamp);
    require(expirationStatus == 1, "Rollover: new timestamp is not active");

    if (block.timestamp < expirationTimestamp) {
      _rolloverBeforeExpire(protocol, cover, _newTimestamp, _account);
    } else {
      require(block.timestamp >= uint256(expirationTimestamp).add(protocol.noclaimRedeemDelay()), "Rollover: not ready");
      _rolloverAfterExpire(protocol, cover, _newTimestamp, _account);
    }
  }

  function _rolloverBeforeExpire(
    IProtocol protocol,
    ICover cover,
    uint48 _newTimestamp,
    address _account
  ) internal {
    // transfer CLAIM and NOCLAIM to contract
    IERC20 claimCovToken = cover.claimCovToken();
    IERC20 noclaimCovToken = cover.noclaimCovToken();
    uint256 claimCovTokenBal = claimCovToken.balanceOf(_account);
    uint256 noclaimCovTokenBal = noclaimCovToken.balanceOf(_account);
    uint256 amount = (claimCovTokenBal > noclaimCovTokenBal) ? noclaimCovTokenBal : claimCovTokenBal;
    require(amount > 0, "Rollover: insufficient covTokens");

    claimCovToken.safeTransferFrom(_account, address(this), amount);
    noclaimCovToken.safeTransferFrom(_account, address(this), amount);

    // redeem collateral back to contract with CLAIM and NOCLAIM tokens
    IERC20 collateral = IERC20(cover.collateral());
    cover.redeemCollateral(amount);
    uint256 redeemedAmount = collateral.balanceOf(address(this));

    _approve(collateral, address(protocol), redeemedAmount);
    protocol.addCover(address(collateral), _newTimestamp, redeemedAmount);
    _sendCovTokensToAccount(protocol, address(collateral), _newTimestamp, _account);
  }

  function _rolloverAfterExpire(
    IProtocol protocol,
    ICover cover,
    uint48 _newTimestamp,
    address _account
  ) internal {
    // transfer CLAIM and NOCLAIM to contract
    IERC20 noclaimCovToken = cover.noclaimCovToken();
    uint256 amount = noclaimCovToken.balanceOf(_account);
    noclaimCovToken.safeTransferFrom(_account, address(this), amount);

    // redeem collateral back to contract with NOCLAIM tokens
    IERC20 collateral = IERC20(cover.collateral());
    cover.redeemNoclaim();
    uint256 redeemedAmount = collateral.balanceOf(address(this));

    _approve(collateral, address(protocol), redeemedAmount);
    protocol.addCover(address(collateral), _newTimestamp, redeemedAmount);
    _sendCovTokensToAccount(protocol, address(collateral), _newTimestamp, _account);
  }

  function _approve(IERC20 _token, address _spender, uint256 _amount) internal {
    if (_token.allowance(address(this), _spender) < _amount) {
      _token.approve(_spender, uint256(-1));
    }
  }

  function _sendCovTokensToAccount(
    IProtocol protocol,
    address _collateral,
    uint48 _timestamp,
    address _account
  ) internal {
    ICover newCover = ICover(protocol.coverMap(_collateral, _timestamp));

    IERC20 newClaimCovToken = newCover.claimCovToken();
    IERC20 newNoclaimCovToken = newCover.noclaimCovToken();

    newClaimCovToken.safeTransfer(_account, newClaimCovToken.balanceOf(address(this)));
    newNoclaimCovToken.safeTransfer(_account, newNoclaimCovToken.balanceOf(address(this)));
  }
}