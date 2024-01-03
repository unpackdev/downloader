// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

import "./ICover.sol";
import "./IERC20.sol";
import "./IProtocolFactory.sol";
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

  address public protocolFactory;

  constructor(address _protocolFactory) {
    require(_protocolFactory != address(0), "CoverRouter: protocolFactory is 0");
    protocolFactory = _protocolFactory;
  }

  /// @notice rollover for sender
  function rollover(address _cover, uint48 _newTimestamp) external override {
    _rolloverAccount(msg.sender, _cover, _newTimestamp, true);
  }

  /// @notice rollover for a different account (from sender)
  function rolloverAccount(address _account, address _cover, uint48 _newTimestamp) public override {
    _rolloverAccount(_account, _cover, _newTimestamp, true);
  }

  /// @notice can only rollover to a future expiry once, expiries are limited and pre-set by Cover Protocol
  function _rolloverAccount(
    address _account,
    address _cover,
    uint48 _newTimestamp,
    bool _isLastStep
  ) internal {
    ICover cover = ICover(_cover);
    _validateCoverLegitimacy(cover);
    uint48 expirationTimestamp = cover.expirationTimestamp();
    require(expirationTimestamp < _newTimestamp && block.timestamp < _newTimestamp, "CoverRouter: invalid expiry");

    IProtocol protocol = IProtocol(cover.owner());

    bool acceptedClaim = cover.claimNonce() != protocol.claimNonce();
    require(!acceptedClaim, "CoverRouter: there is an accepted claim");

    (, uint8 expirationStatus) = protocol.expirationTimestampMap(_newTimestamp);
    require(expirationStatus == 1, "CoverRouter: new timestamp is not active");

    if (block.timestamp < expirationTimestamp) {
      _redeemCollateral(cover, _account);
    } else {
      require(block.timestamp >= uint256(expirationTimestamp).add(protocol.noclaimRedeemDelay()), "CoverRouter: not ready");
      _redeemNoclaim(cover, _account);
    }
    IERC20 collateral = IERC20(cover.collateral());
    uint256 redeemedAmount = collateral.balanceOf(address(this));

    _addCover(protocol, address(collateral), _newTimestamp, redeemedAmount);
    emit RolloverCover(_account, address(protocol));
    if (_isLastStep) {
      _sendCovTokensToAccount(protocol, address(collateral), _newTimestamp, _account);
    }
  }

  /// @notice appove spender contract to spend CoverRouter's tokens
  function _approve(IERC20 _token, address _spender, uint256 _amount) internal {
    if (_token.allowance(address(this), _spender) < _amount) {
      _token.approve(_spender, _amount);
    }
  }

  function _validateCoverLegitimacy(ICover _cover) internal view {
    IProtocol _protocol = IProtocol(_cover.owner());
    address realCoverAddress = IProtocolFactory(protocolFactory).getCoverAddress(_protocol.name(), _cover.expirationTimestamp(), _cover.collateral(), _cover.claimNonce());
    require(address(_cover) == realCoverAddress, "CoverRouter: not legitimate cover");
  }

  function _validateProtocolLegitimacy(IProtocol _protocol) internal view {
    address realProtocolAddress = IProtocolFactory(protocolFactory).getProtocolAddress(_protocol.name());
    require(address(_protocol) == realProtocolAddress, "CoverRouter: not legitimate protocol address");
  }

  function _addCover(
    IProtocol _protocol,
    address _collateral,
    uint48 _timestamp,
    uint256 _amount
  ) internal {
    _approve(IERC20(_collateral), address(_protocol), _amount);
    // safe call to a protocol from Cover Protocol Factory, will revert if anything goes wrong
    _protocol.addCover(_collateral, _timestamp, _amount);
  }

  function _sendCovTokensToAccount(
    IProtocol protocol,
    address _collateral,
    uint48 _timestamp,
    address _account
  ) private {
    ICover newCover = ICover(protocol.coverMap(_collateral, _timestamp));

    IERC20 newClaimCovToken = newCover.claimCovToken();
    IERC20 newNoclaimCovToken = newCover.noclaimCovToken();

    newClaimCovToken.safeTransfer(_account, newClaimCovToken.balanceOf(address(this)));
    newNoclaimCovToken.safeTransfer(_account, newNoclaimCovToken.balanceOf(address(this)));
  }

  function _redeemCollateral(ICover cover, address _account) private {
    // transfer CLAIM and NOCLAIM to contract
    IERC20 claimCovToken = cover.claimCovToken();
    IERC20 noclaimCovToken = cover.noclaimCovToken();
    uint256 claimCovTokenBal = claimCovToken.balanceOf(_account);
    uint256 noclaimCovTokenBal = noclaimCovToken.balanceOf(_account);
    uint256 amount = (claimCovTokenBal > noclaimCovTokenBal) ? noclaimCovTokenBal : claimCovTokenBal;
    require(amount > 0, "CoverRouter: insufficient covTokens");

    claimCovToken.safeTransferFrom(_account, address(this), amount);
    noclaimCovToken.safeTransferFrom(_account, address(this), amount);

    // redeem collateral back to contract with CLAIM and NOCLAIM tokens
    cover.redeemCollateral(amount);
  }

  function _redeemNoclaim(ICover cover, address _account) private {
    // transfer CLAIM and NOCLAIM to contract
    IERC20 noclaimCovToken = cover.noclaimCovToken();
    uint256 amount = noclaimCovToken.balanceOf(_account);
    require(amount > 0, "CoverRouter: insufficient NOCLAIM covTokens");
    noclaimCovToken.safeTransferFrom(_account, address(this), amount);

    // redeem collateral back to contract with NOCLAIM tokens
    cover.redeemNoclaim();
  }
}