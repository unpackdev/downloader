// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./TIC.sol";
import "./ITIC.sol";
import "./SafeMath.sol";
import "./FixedPoint.sol";
import "./HitchensUnorderedKeySet.sol";
import "./IERC20.sol";
import "./IDerivative.sol";
import "./IFinder.sol";

library SynthereumTICHelper {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
  using SynthereumTICHelper for SynthereumTIC.Storage;

  function initialize(
    SynthereumTIC.Storage storage self,
    IDerivative _derivative,
    ISynthereumFinder _finder,
    uint8 _version,
    address _liquidityProvider,
    address _validator,
    FixedPoint.Unsigned memory _startingCollateralization
  ) public {
    self.derivative = _derivative;
    self.finder = _finder;
    self.version = _version;
    self.liquidityProvider = _liquidityProvider;
    self.validator = _validator;
    self.startingCollateralization = _startingCollateralization;
    self.collateralToken = IERC20(
      address(self.derivative.collateralCurrency())
    );
  }

  function mintRequest(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) public returns (bytes32) {
    bytes32 mintID =
      keccak256(
        abi.encodePacked(
          msg.sender,
          collateralAmount.rawValue,
          numTokens.rawValue,
          now
        )
      );

    SynthereumTICInterface.MintRequest memory mint =
      SynthereumTICInterface.MintRequest(
        mintID,
        now,
        msg.sender,
        collateralAmount,
        numTokens
      );

    self.mintRequestSet.insert(mintID);
    self.mintRequests[mintID] = mint;

    return mintID;
  }

  function approveMint(SynthereumTIC.Storage storage self, bytes32 mintID)
    public
  {
    FixedPoint.Unsigned memory globalCollateralization =
      self.getGlobalCollateralizationRatio();

    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    require(self.mintRequestSet.exists(mintID), 'Mint request does not exist');
    SynthereumTICInterface.MintRequest memory mint = self.mintRequests[mintID];

    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        mint.collateralAmount,
        mint.numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    self.mintRequestSet.remove(mintID);
    delete self.mintRequests[mintID];

    FixedPoint.Unsigned memory feeTotal =
      mint.collateralAmount.mul(self.fee.feePercentage);

    self.pullCollateral(mint.sender, mint.collateralAmount.add(feeTotal));

    self.mintSynTokens(
      mint.numTokens.mulCeil(targetCollateralization),
      mint.numTokens
    );

    self.transferSynTokens(mint.sender, mint.numTokens);

    self.sendFee(feeTotal);
  }

  function rejectMint(SynthereumTIC.Storage storage self, bytes32 mintID)
    public
  {
    require(self.mintRequestSet.exists(mintID), 'Mint request does not exist');
    self.mintRequestSet.remove(mintID);
    delete self.mintRequests[mintID];
  }

  function deposit(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) public {
    self.pullCollateral(msg.sender, collateralAmount);
  }

  function withdraw(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) public {
    require(
      self.collateralToken.transfer(msg.sender, collateralAmount.rawValue)
    );
  }

  function exchangeMint(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) public {
    FixedPoint.Unsigned memory globalCollateralization =
      self.getGlobalCollateralizationRatio();

    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        collateralAmount,
        numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    require(self.pullCollateral(msg.sender, collateralAmount));

    self.mintSynTokens(numTokens.mulCeil(targetCollateralization), numTokens);

    self.transferSynTokens(msg.sender, numTokens);
  }

  function depositIntoDerivative(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) public {
    IDerivative derivative = self.derivative;
    self.collateralToken.approve(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.deposit(collateralAmount);
  }

  function withdrawRequest(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) public {
    self.derivative.requestWithdrawal(collateralAmount);
  }

  function withdrawPassedRequest(SynthereumTIC.Storage storage self) public {
    uint256 prevBalance = self.collateralToken.balanceOf(address(this));

    self.derivative.withdrawPassedRequest();

    FixedPoint.Unsigned memory amountWithdrawn =
      FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this)).sub(prevBalance)
      );
    require(amountWithdrawn.isGreaterThan(0), 'No tokens were redeemed');
    require(
      self.collateralToken.transfer(msg.sender, amountWithdrawn.rawValue)
    );
  }

  function redeemRequest(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) public returns (bytes32) {
    bytes32 redeemID =
      keccak256(
        abi.encodePacked(
          msg.sender,
          collateralAmount.rawValue,
          numTokens.rawValue,
          now
        )
      );

    SynthereumTICInterface.RedeemRequest memory redeem =
      SynthereumTICInterface.RedeemRequest(
        redeemID,
        now,
        msg.sender,
        collateralAmount,
        numTokens
      );

    self.redeemRequestSet.insert(redeemID);
    self.redeemRequests[redeemID] = redeem;

    return redeemID;
  }

  function approveRedeem(SynthereumTIC.Storage storage self, bytes32 redeemID)
    public
  {
    require(
      self.redeemRequestSet.exists(redeemID),
      'Redeem request does not exist'
    );
    SynthereumTICInterface.RedeemRequest memory redeem =
      self.redeemRequests[redeemID];

    require(redeem.numTokens.isGreaterThan(0));

    IERC20 tokenCurrency = self.derivative.tokenCurrency();
    require(
      tokenCurrency.balanceOf(redeem.sender) >= redeem.numTokens.rawValue
    );

    self.redeemRequestSet.remove(redeemID);
    delete self.redeemRequests[redeemID];

    require(
      tokenCurrency.transferFrom(
        redeem.sender,
        address(this),
        redeem.numTokens.rawValue
      ),
      'Token transfer failed'
    );

    require(
      tokenCurrency.approve(
        address(self.derivative),
        redeem.numTokens.rawValue
      ),
      'Token approve failed'
    );

    uint256 prevBalance = self.collateralToken.balanceOf(address(this));

    self.derivative.redeem(redeem.numTokens);

    FixedPoint.Unsigned memory amountWithdrawn =
      FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this)).sub(prevBalance)
      );

    require(amountWithdrawn.isGreaterThan(redeem.collateralAmount));

    FixedPoint.Unsigned memory feeTotal =
      redeem.collateralAmount.mul(self.fee.feePercentage);

    self.collateralToken.transfer(
      redeem.sender,
      redeem.collateralAmount.sub(feeTotal).rawValue
    );

    self.sendFee(feeTotal);
  }

  function rejectRedeem(SynthereumTIC.Storage storage self, bytes32 redeemID)
    public
  {
    require(
      self.redeemRequestSet.exists(redeemID),
      'Mint request does not exist'
    );
    self.redeemRequestSet.remove(redeemID);
    delete self.redeemRequests[redeemID];
  }

  function emergencyShutdown(SynthereumTIC.Storage storage self) external {
    self.derivative.emergencyShutdown();
  }

  function settleEmergencyShutdown(SynthereumTIC.Storage storage self) public {
    IERC20 tokenCurrency = self.derivative.tokenCurrency();

    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));

    require(
      numTokens.isGreaterThan(0) || msg.sender == self.liquidityProvider,
      'Account has nothing to settle'
    );

    if (numTokens.isGreaterThan(0)) {
      require(
        tokenCurrency.transferFrom(
          msg.sender,
          address(this),
          numTokens.rawValue
        ),
        'Token transfer failed'
      );

      require(
        tokenCurrency.approve(address(self.derivative), numTokens.rawValue),
        'Token approve failed'
      );
    }

    uint256 prevBalance = self.collateralToken.balanceOf(address(this));

    self.derivative.settleEmergencyShutdown();

    FixedPoint.Unsigned memory amountWithdrawn =
      FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this)).sub(prevBalance)
      );

    require(amountWithdrawn.isGreaterThan(0), 'No collateral was withdrawn');

    FixedPoint.Unsigned memory totalToRedeem;

    if (msg.sender == self.liquidityProvider) {
      totalToRedeem = FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this))
      );
    } else {
      totalToRedeem = numTokens.mul(self.derivative.emergencyShutdownPrice());
      require(
        amountWithdrawn.isGreaterThanOrEqual(totalToRedeem),
        'Insufficient collateral withdrawn to redeem tokens'
      );
    }

    require(self.collateralToken.transfer(msg.sender, totalToRedeem.rawValue));
  }

  function exchangeRequest(
    SynthereumTIC.Storage storage self,
    SynthereumTICInterface destTIC,
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory destNumTokens
  ) public returns (bytes32) {
    bytes32 exchangeID =
      keccak256(
        abi.encodePacked(
          msg.sender,
          address(destTIC),
          numTokens.rawValue,
          destNumTokens.rawValue,
          now
        )
      );

    SynthereumTICInterface.ExchangeRequest memory exchange =
      SynthereumTICInterface.ExchangeRequest(
        exchangeID,
        now,
        msg.sender,
        destTIC,
        numTokens,
        collateralAmount,
        destNumTokens
      );

    self.exchangeRequestSet.insert(exchangeID);
    self.exchangeRequests[exchangeID] = exchange;

    return exchangeID;
  }

  function approveExchange(
    SynthereumTIC.Storage storage self,
    bytes32 exchangeID
  ) public {
    require(
      self.exchangeRequestSet.exists(exchangeID),
      'Exchange request does not exist'
    );
    SynthereumTICInterface.ExchangeRequest memory exchange =
      self.exchangeRequests[exchangeID];

    self.exchangeRequestSet.remove(exchangeID);
    delete self.exchangeRequests[exchangeID];

    uint256 prevBalance = self.collateralToken.balanceOf(address(this));

    self.redeemForCollateral(exchange.sender, exchange.numTokens);

    FixedPoint.Unsigned memory amountWithdrawn =
      FixedPoint.Unsigned(
        self.collateralToken.balanceOf(address(this)).sub(prevBalance)
      );

    require(
      amountWithdrawn.isGreaterThan(exchange.collateralAmount),
      'No tokens were redeemed'
    );

    FixedPoint.Unsigned memory feeTotal =
      exchange.collateralAmount.mul(self.fee.feePercentage);

    self.sendFee(feeTotal);

    FixedPoint.Unsigned memory destinationCollateral =
      amountWithdrawn.sub(feeTotal);

    require(
      self.collateralToken.approve(
        address(exchange.destTIC),
        destinationCollateral.rawValue
      )
    );

    exchange.destTIC.exchangeMint(
      destinationCollateral.rawValue,
      exchange.destNumTokens.rawValue
    );

    require(
      exchange.destTIC.derivative().tokenCurrency().transfer(
        exchange.sender,
        exchange.destNumTokens.rawValue
      )
    );
  }

  function rejectExchange(
    SynthereumTIC.Storage storage self,
    bytes32 exchangeID
  ) public {
    require(
      self.exchangeRequestSet.exists(exchangeID),
      'Exchange request does not exist'
    );
    self.exchangeRequestSet.remove(exchangeID);
    delete self.exchangeRequests[exchangeID];
  }

  function setFeePercentage(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory _feePercentage
  ) public {
    self.fee.feePercentage = _feePercentage;
  }

  function setFeeRecipients(
    SynthereumTIC.Storage storage self,
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) public {
    require(
      _feeRecipients.length == _feeProportions.length,
      'Fee recipients and fee proportions do not match'
    );

    uint256 totalActualFeeProportions;

    for (uint256 i = 0; i < _feeProportions.length; i++) {
      totalActualFeeProportions += _feeProportions[i];
    }

    self.fee.feeRecipients = _feeRecipients;
    self.fee.feeProportions = _feeProportions;
    self.totalFeeProportions = totalActualFeeProportions;
  }

  function getMintRequests(SynthereumTIC.Storage storage self)
    public
    view
    returns (SynthereumTICInterface.MintRequest[] memory)
  {
    SynthereumTICInterface.MintRequest[] memory mintRequests =
      new SynthereumTICInterface.MintRequest[](self.mintRequestSet.count());

    for (uint256 i = 0; i < self.mintRequestSet.count(); i++) {
      mintRequests[i] = self.mintRequests[self.mintRequestSet.keyAtIndex(i)];
    }

    return mintRequests;
  }

  function getRedeemRequests(SynthereumTIC.Storage storage self)
    public
    view
    returns (SynthereumTICInterface.RedeemRequest[] memory)
  {
    SynthereumTICInterface.RedeemRequest[] memory redeemRequests =
      new SynthereumTICInterface.RedeemRequest[](self.redeemRequestSet.count());

    for (uint256 i = 0; i < self.redeemRequestSet.count(); i++) {
      redeemRequests[i] = self.redeemRequests[
        self.redeemRequestSet.keyAtIndex(i)
      ];
    }

    return redeemRequests;
  }

  function getExchangeRequests(SynthereumTIC.Storage storage self)
    public
    view
    returns (SynthereumTICInterface.ExchangeRequest[] memory)
  {
    SynthereumTICInterface.ExchangeRequest[] memory exchangeRequests =
      new SynthereumTICInterface.ExchangeRequest[](
        self.exchangeRequestSet.count()
      );

    for (uint256 i = 0; i < self.exchangeRequestSet.count(); i++) {
      exchangeRequests[i] = self.exchangeRequests[
        self.exchangeRequestSet.keyAtIndex(i)
      ];
    }

    return exchangeRequests;
  }

  function pullCollateral(
    SynthereumTIC.Storage storage self,
    address from,
    FixedPoint.Unsigned memory numTokens
  ) internal returns (bool) {
    return
      self.collateralToken.transferFrom(
        from,
        address(this),
        numTokens.rawValue
      );
  }

  function mintSynTokens(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    require(
      self.collateralToken.approve(
        address(self.derivative),
        collateralAmount.rawValue
      )
    );
    self.derivative.create(collateralAmount, numTokens);
  }

  function transferSynTokens(
    SynthereumTIC.Storage storage self,
    address recipient,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    require(
      self.derivative.tokenCurrency().transfer(recipient, numTokens.rawValue)
    );
  }

  function sendFee(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory _feeAmount
  ) internal {
    for (uint256 i = 0; i < self.fee.feeRecipients.length; i++) {
      require(
        self.collateralToken.transfer(
          self.fee.feeRecipients[i],
          _feeAmount
            .mul(self.fee.feeProportions[i])
            .div(self.totalFeeProportions)
            .rawValue
        )
      );
    }
  }

  function redeemForCollateral(
    SynthereumTIC.Storage storage self,
    address tokenHolder,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    require(numTokens.isGreaterThan(0));

    IERC20 tokenCurrency = self.derivative.tokenCurrency();
    require(tokenCurrency.balanceOf(tokenHolder) >= numTokens.rawValue);

    require(
      tokenCurrency.transferFrom(
        tokenHolder,
        address(this),
        numTokens.rawValue
      ),
      'Token transfer failed'
    );

    require(
      tokenCurrency.approve(address(self.derivative), numTokens.rawValue),
      'Token approve failed'
    );

    self.derivative.redeem(numTokens);
  }

  function getGlobalCollateralizationRatio(SynthereumTIC.Storage storage self)
    internal
    view
    returns (FixedPoint.Unsigned memory)
  {
    FixedPoint.Unsigned memory totalTokensOutstanding =
      self.derivative.globalPositionData().totalTokensOutstanding;

    if (totalTokensOutstanding.isGreaterThan(0)) {
      return
        self.derivative.totalPositionCollateral().div(totalTokensOutstanding);
    } else {
      return FixedPoint.fromUnscaledUint(0);
    }
  }

  function checkCollateralizationRatio(
    SynthereumTIC.Storage storage self,
    FixedPoint.Unsigned memory globalCollateralization,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal view returns (bool) {
    FixedPoint.Unsigned memory newCollateralization =
      collateralAmount
        .add(FixedPoint.Unsigned(self.collateralToken.balanceOf(address(this))))
        .div(numTokens);

    return newCollateralization.isGreaterThanOrEqual(globalCollateralization);
  }
}
