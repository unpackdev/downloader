// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./IPayments.sol";
import "./MarketConfig.sol";

library MarketUtils {
  using SafeERC20 for IERC20;

  /// @notice Checks to see if the currenccy address is eth or an approved erc20 token.
  /// @param _currencyAddress Address of currency (Zero address if eth).
  function checkIfCurrencyIsApproved(MarketConfig.Config storage _config, address _currencyAddress) internal view {
    require(
      _currencyAddress == address(0) || _config.approvedTokenRegistry.isApprovedToken(_currencyAddress),
      "Not approved currency"
    );
  }

  /// @notice Checks to see if the msg sender owns the token.
  /// @param _originContract Contract address of the token being checked.
  /// @param _tokenId Token Id of the asset.
  function senderMustBeTokenOwner(address _originContract, uint256 _tokenId) internal view {
    IERC721 erc721 = IERC721(_originContract);
    require(erc721.ownerOf(_tokenId) == msg.sender, "sender must be the token owner");
  }

  /// @notice Checks to see if the owner of the token has the marketplace approved.
  /// @param _addr Being checked if they've approved for all
  /// @param _originContract Contract address of the token being checked.
  function addressMustHaveMarketplaceApprovedForNFT(address _addr, address _originContract) internal view {
    IERC721 erc721 = IERC721(_originContract);
    require(erc721.isApprovedForAll(_addr, address(this)), "owner must have approved contract");
  }

  /// @notice Verifies that the splits supplied are valid.
  /// @dev A valid split has the same number of splits and ratios.
  /// @dev There can only be a max of 5 parties split with.
  /// @dev Total of the ratios should be 100 which is relative.
  /// @param _splitAddrs The addresses the amount is being split with.
  /// @param _splitRatios The ratios each address in _splits is getting.
  function checkSplits(address payable[] calldata _splitAddrs, uint8[] calldata _splitRatios) internal pure {
    require(_splitAddrs.length > 0, "checkSplits::Must have at least 1 split");
    require(_splitAddrs.length <= 5, "checkSplits::Split exceeded max size");
    require(_splitAddrs.length == _splitRatios.length, "checkSplits::Splits and ratios must be equal");
    uint256 totalRatio = 0;

    for (uint256 i = 0; i < _splitRatios.length; i++) {
      totalRatio += _splitRatios[i];
    }

    require(totalRatio == 100, "checkSplits::Total must be equal to 100");
  }

  /// @notice Checks to see if the sender has approved the marketplace to move tokens.
  /// @dev This is for offers/buys/bids and the allowance of erc20 tokens.
  /// @dev Returns on zero address because no allowance is needed for eth.
  /// @param _currency The address of the currency being checked.
  /// @param _amount The total amount being checked.
  function senderMustHaveMarketplaceApproved(address _currency, uint256 _amount) internal view {
    if (_currency == address(0)) {
      return;
    }

    IERC20 erc20 = IERC20(_currency);

    require(erc20.allowance(msg.sender, address(this)) >= _amount, "sender needs to approve marketplace for currency");
  }

  /// @notice Checks the user has the correct amount and transfers to the marketplace.
  /// @dev If the currency used is eth (zero address) the msg value is checked.
  /// @dev If eth isnt used and eth is sent we revert the txn.
  /// @dev We need to check this contracts balance before and after the transfer to ensure no fee.
  /// @param _currencyAddress Currency address being checked and transfered.
  /// @param _amount Total amount of currency.
  function checkAmountAndTransfer(address _currencyAddress, uint256 _amount) internal {
    if (_currencyAddress == address(0)) {
      require(msg.value == _amount, "not enough eth sent");
      return;
    }

    require(msg.value == 0, "msg.value should be 0 when not using eth");

    IERC20 erc20 = IERC20(_currencyAddress);
    uint256 balanceBefore = erc20.balanceOf(address(this));

    erc20.safeTransferFrom(msg.sender, address(this), _amount);

    uint256 balanceAfter = erc20.balanceOf(address(this));

    require(balanceAfter - balanceBefore == _amount, "not enough tokens transfered");
  }

  /// @notice Refunds an address the designated amount.
  /// @dev Return if amount being refunded is zero.
  /// @dev Forwards to payment contract if eth is being refunded.
  /// @param _currencyAddress Address of currency being refunded.
  /// @param _amount Amount being refunded.
  /// @param _marketplaceFee Marketplace Fee (percentage) paid by _recipient.
  /// @param _recipient Address amount is being refunded to.
  function refund(
    MarketConfig.Config storage _config,
    address _currencyAddress,
    uint256 _amount,
    uint256 _marketplaceFee,
    address _recipient
  ) internal {
    if (_amount == 0) {
      return;
    }

    uint256 requiredAmount = _amount + ((_amount * _marketplaceFee) / 100);

    if (_currencyAddress == address(0)) {
      (bool success, bytes memory data) = address(_config.payments).call{value: requiredAmount}(
        abi.encodeWithSignature("refund(address,uint256)", _recipient, requiredAmount)
      );

      require(success, string(data));
      return;
    }

    IERC20 erc20 = IERC20(_currencyAddress);
    erc20.safeTransfer(_recipient, requiredAmount);
  }

  /// @notice Sends a payout to all the necessary parties.
  /// @dev Note that _splitAddrs and _splitRatios are not checked for validity. Make sure supplied values are correct by using _checkSplits. 
  /// @dev Sends payments to the network, royalty if applicable, and splits for the rest.
  /// @dev Forwards payments to the payment contract if payout is happening in eth.
  /// @dev Total amount of ratios should be 100 and is relative to the total ratio left.
  /// @param _originContract Contract address of asset triggering a payout.
  /// @param _tokenId Token Id of the asset.
  /// @param _currencyAddress Address of currency being paid out.
  /// @param _amount Total amount to be paid out.
  /// @param _seller Address of the person selling the asset.
  /// @param _splitAddrs Addresses that funds need to be split against.
  /// @param _splitRatios Ratios for split pertaining to each address.
  function payout(
    MarketConfig.Config storage _config,
    address _originContract,
    uint256 _tokenId,
    address _currencyAddress,
    uint256 _amount,
    address _seller,
    address payable[] memory _splitAddrs,
    uint8[] memory _splitRatios
  ) internal {
    require(_splitAddrs.length == _splitRatios.length, "Number of split addresses and ratios must be equal.");

    /*
        The overall flow for payouts is:
            1. Payout marketplace fee
            2. Primary/Secondary Payouts
                a. Primary -> If space sale, query space operator registry for platform comission and payout
                              Else query marketplace setting for primary sale comission and payout
                b. Secondary -> Query global royalty registry for recipients and amounts and payout
            3. Calculate the amount for each _splitAddr based on remaining amount and payout
         */

    uint256 remainingAmount = _amount;

    // Marketplace fee
    uint256 marketplaceFee = _config.marketplaceSettings.calculateMarketplaceFee(_amount);

    address payable[] memory mktFeeRecip = new address payable[](2);
    mktFeeRecip[0] = payable(_config.networkBeneficiary);
    mktFeeRecip[1] = payable(_config.stakingRegistry.getRewardAccumulatorAddressForUser(_seller));
    mktFeeRecip[1] = mktFeeRecip[1] == address(0) ? payable(_config.networkBeneficiary) : mktFeeRecip[1];
    uint256[] memory mktFee = new uint256[](2);
    mktFee[0] = _config.stakingSettings.calculateMarketplacePayoutFee(_amount);
    mktFee[1] = _config.stakingSettings.calculateStakingFee(_amount);

    performPayouts(_config, _currencyAddress, marketplaceFee, mktFeeRecip, mktFee);

    if (!_config.marketplaceSettings.hasERC721TokenSold(_originContract, _tokenId)) {
      uint256[] memory platformFee = new uint256[](1);
      address payable[] memory platformRecip = new address payable[](1);
      platformRecip[0] = mktFeeRecip[0];

      if (_config.spaceOperatorRegistry.isApprovedSpaceOperator(_seller)) {
        uint256 platformCommission = _config.spaceOperatorRegistry.getPlatformCommission(_seller);

        remainingAmount = remainingAmount - ((_amount * platformCommission) / 100);

        platformFee[0] = (_amount * platformCommission) / 100;

        performPayouts(_config, _currencyAddress, platformFee[0], platformRecip, platformFee);
      } else {
        uint256 platformCommission = _config.marketplaceSettings.getERC721ContractPrimarySaleFeePercentage(
          _originContract
        );

        remainingAmount = remainingAmount - ((_amount * platformCommission) / 100);

        platformFee[0] = (_amount * platformCommission) / 100;

        performPayouts(_config, _currencyAddress, platformFee[0], platformRecip, platformFee);
      }
    } else {
      (address payable[] memory receivers, uint256[] memory royalties) = _config.royaltyEngine.getRoyalty(
        _originContract,
        _tokenId,
        _amount
      );

      uint256 totalRoyalties = 0;

      for (uint256 i = 0; i < royalties.length; i++) {
        totalRoyalties += royalties[i];
      }

      remainingAmount -= totalRoyalties;
      performPayouts(_config, _currencyAddress, totalRoyalties, receivers, royalties);
    }

    uint256[] memory remainingAmts = new uint256[](_splitAddrs.length);

    uint256 totalSplit = 0;

    for (uint256 i = 0; i < _splitAddrs.length; i++) {
      remainingAmts[i] = (remainingAmount * _splitRatios[i]) / 100;
      totalSplit += (remainingAmount * _splitRatios[i]) / 100;
    }
    performPayouts(_config, _currencyAddress, totalSplit, _splitAddrs, remainingAmts);
  }

  function performPayouts(
    MarketConfig.Config storage _config,
    address _currencyAddress,
    uint256 _amount,
    address payable[] memory _recipients,
    uint256[] memory _amounts
  ) internal {
    if (_currencyAddress == address(0)) {
      (bool success, bytes memory data) = address(_config.payments).call{value: _amount}(
        abi.encodeWithSelector(IPayments.payout.selector, _recipients, _amounts)
      );

      require(success, string(data));
    } else {
      IERC20 erc20 = IERC20(_currencyAddress);

      for (uint256 i = 0; i < _recipients.length; i++) {
        erc20.safeTransfer(_recipients[i], _amounts[i]);
      }
    }
  }
}
