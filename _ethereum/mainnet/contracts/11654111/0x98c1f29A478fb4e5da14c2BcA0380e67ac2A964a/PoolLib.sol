// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IPool.sol";
import "./IPoolStorage.sol";
import "./FixedPoint.sol";
import "./IERC20.sol";
import "./IDerivative.sol";
import "./IRole.sol";
import "./IFinder.sol";
import "./IPoolRegistry.sol";
import "./Constants.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

library SynthereumPoolLib {
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolLib for ISynthereumPoolStorage.Storage;
  using SynthereumPoolLib for IDerivative;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  event Mint(
    address indexed account,
    address indexed pool,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid
  );

  event Redeem(
    address indexed account,
    address indexed pool,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid
  );

  event Exchange(
    address indexed account,
    address indexed sourcePool,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid
  );

  event Settlement(
    address indexed account,
    address indexed pool,
    uint256 numTokens,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  event AddDerivative(address indexed pool, address indexed derivative);
  event RemoveDerivative(address indexed pool, address indexed derivative);

  modifier checkDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  ) {
    require(self.derivatives.contains(address(derivative)), 'Wrong derivative');
    _;
  }

  modifier checkIsSenderContract(ISynthereumPoolStorage.Storage storage self) {
    if (!self.isContractAllowed) {
      require(tx.origin == msg.sender, 'Account must be an EOA');
    }
    _;
  }

  function initialize(
    ISynthereumPoolStorage.Storage storage self,
    uint8 _version,
    ISynthereumFinder _finder,
    IDerivative _derivative,
    FixedPoint.Unsigned memory _startingCollateralization,
    bool _isContractAllowed
  ) external {
    self.derivatives.add(address(_derivative));
    emit AddDerivative(address(this), address(_derivative));
    self.version = _version;
    self.finder = _finder;
    self.startingCollateralization = _startingCollateralization;
    self.isContractAllowed = _isContractAllowed;
    self.collateralToken = getDerivativeCollateral(_derivative);
    self.syntheticToken = _derivative.tokenCurrency();
  }

  function addDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.collateralToken == getDerivativeCollateral(derivative),
      'Wrong collateral of the new derivative'
    );
    require(
      self.syntheticToken == derivative.tokenCurrency(),
      'Wrong synthetic token'
    );
    require(
      self.derivatives.add(address(derivative)),
      'Derivative has already been included'
    );
    emit AddDerivative(address(this), address(derivative));
  }

  function removeDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.derivatives.remove(address(derivative)),
      'Derivative not included'
    );
    emit RemoveDerivative(address(this), address(derivative));
  }

  function mint(
    ISynthereumPoolStorage.Storage storage self,
    ISynthereumPool.MintParameters memory mintMetaTx,
    ISynthereumPool.SignatureVerificationParams
      memory signatureVerificationParams
  ) external checkIsSenderContract(self) returns (uint256 feePaid) {
    bytes32 digest =
      generateMintDigest(
        mintMetaTx,
        signatureVerificationParams.domain_separator,
        signatureVerificationParams.typeHash
      );
    checkSignature(
      signatureVerificationParams.validator_role,
      digest,
      signatureVerificationParams.signature
    );
    self.checkMetaTxParams(
      mintMetaTx.sender,
      mintMetaTx.derivativeAddr,
      mintMetaTx.feePercentage,
      mintMetaTx.nonce,
      mintMetaTx.expiration
    );

    FixedPoint.Unsigned memory collateralAmount =
      FixedPoint.Unsigned(mintMetaTx.collateralAmount);
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(mintMetaTx.numTokens);
    IDerivative derivative = IDerivative(mintMetaTx.derivativeAddr);
    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

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

    FixedPoint.Unsigned memory feeTotal =
      collateralAmount.mul(self.fee.feePercentage);

    self.pullCollateral(mintMetaTx.sender, collateralAmount.add(feeTotal));

    self.mintSynTokens(
      derivative,
      numTokens.mulCeil(targetCollateralization),
      numTokens
    );

    self.transferSynTokens(mintMetaTx.sender, numTokens);

    self.sendFee(feeTotal);

    feePaid = feeTotal.rawValue;

    emit Mint(
      mintMetaTx.sender,
      address(this),
      collateralAmount.add(feeTotal).rawValue,
      numTokens.rawValue,
      feePaid
    );
  }

  function redeem(
    ISynthereumPoolStorage.Storage storage self,
    ISynthereumPool.RedeemParameters memory redeemMetaTx,
    ISynthereumPool.SignatureVerificationParams
      memory signatureVerificationParams
  ) external checkIsSenderContract(self) returns (uint256 feePaid) {
    bytes32 digest =
      generateRedeemDigest(
        redeemMetaTx,
        signatureVerificationParams.domain_separator,
        signatureVerificationParams.typeHash
      );
    checkSignature(
      signatureVerificationParams.validator_role,
      digest,
      signatureVerificationParams.signature
    );
    self.checkMetaTxParams(
      redeemMetaTx.sender,
      redeemMetaTx.derivativeAddr,
      redeemMetaTx.feePercentage,
      redeemMetaTx.nonce,
      redeemMetaTx.expiration
    );
    FixedPoint.Unsigned memory collateralAmount =
      FixedPoint.Unsigned(redeemMetaTx.collateralAmount);
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(redeemMetaTx.numTokens);
    IDerivative derivative = IDerivative(redeemMetaTx.derivativeAddr);

    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(redeemMetaTx.sender, derivative, numTokens);
    require(
      amountWithdrawn.isGreaterThan(collateralAmount),
      'Collateral amount bigger than collateral in the derivative'
    );

    FixedPoint.Unsigned memory feeTotal =
      collateralAmount.mul(self.fee.feePercentage);

    uint256 netReceivedCollateral = (collateralAmount.sub(feeTotal)).rawValue;

    self.collateralToken.safeTransfer(
      redeemMetaTx.sender,
      netReceivedCollateral
    );

    self.sendFee(feeTotal);

    feePaid = feeTotal.rawValue;

    emit Redeem(
      redeemMetaTx.sender,
      address(this),
      numTokens.rawValue,
      netReceivedCollateral,
      feePaid
    );
  }

  function exchange(
    ISynthereumPoolStorage.Storage storage self,
    ISynthereumPool.ExchangeParameters memory exchangeMetaTx,
    ISynthereumPool.SignatureVerificationParams
      memory signatureVerificationParams
  ) external checkIsSenderContract(self) returns (uint256 feePaid) {
    {
      bytes32 digest =
        generateExchangeDigest(
          exchangeMetaTx,
          signatureVerificationParams.domain_separator,
          signatureVerificationParams.typeHash
        );
      checkSignature(
        signatureVerificationParams.validator_role,
        digest,
        signatureVerificationParams.signature
      );
    }
    self.checkMetaTxParams(
      exchangeMetaTx.sender,
      exchangeMetaTx.derivativeAddr,
      exchangeMetaTx.feePercentage,
      exchangeMetaTx.nonce,
      exchangeMetaTx.expiration
    );
    FixedPoint.Unsigned memory collateralAmount =
      FixedPoint.Unsigned(exchangeMetaTx.collateralAmount);
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(exchangeMetaTx.numTokens);
    IDerivative derivative = IDerivative(exchangeMetaTx.derivativeAddr);
    IDerivative destDerivative = IDerivative(exchangeMetaTx.destDerivativeAddr);

    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(exchangeMetaTx.sender, derivative, numTokens);
    self.checkPool(
      ISynthereumPool(exchangeMetaTx.destPoolAddr),
      destDerivative
    );
    require(
      amountWithdrawn.isGreaterThan(collateralAmount),
      'Collateral amount bigger than collateral in the derivative'
    );

    FixedPoint.Unsigned memory feeTotal =
      collateralAmount.mul(self.fee.feePercentage);

    self.sendFee(feeTotal);

    FixedPoint.Unsigned memory destinationCollateral =
      amountWithdrawn.sub(feeTotal);

    self.collateralToken.safeApprove(
      exchangeMetaTx.destPoolAddr,
      destinationCollateral.rawValue
    );

    ISynthereumPool(exchangeMetaTx.destPoolAddr).exchangeMint(
      derivative,
      destDerivative,
      destinationCollateral.rawValue,
      exchangeMetaTx.destNumTokens
    );

    destDerivative.tokenCurrency().safeTransfer(
      exchangeMetaTx.sender,
      exchangeMetaTx.destNumTokens
    );

    feePaid = feeTotal.rawValue;

    emit Exchange(
      exchangeMetaTx.sender,
      address(this),
      exchangeMetaTx.destPoolAddr,
      numTokens.rawValue,
      exchangeMetaTx.destNumTokens,
      feePaid
    );
  }

  function exchangeMint(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative srcDerivative,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external {
    self.checkPool(ISynthereumPool(msg.sender), srcDerivative);
    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

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

    self.pullCollateral(msg.sender, collateralAmount);

    self.mintSynTokens(
      derivative,
      numTokens.mulCeil(targetCollateralization),
      numTokens
    );

    self.transferSynTokens(msg.sender, numTokens);
  }

  function withdrawFromPool(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) external {
    self.collateralToken.safeTransfer(msg.sender, collateralAmount.rawValue);
  }

  function depositIntoDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.deposit(collateralAmount);
  }

  function slowWithdrawRequest(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    derivative.requestWithdrawal(collateralAmount);
  }

  function slowWithdrawPassedRequest(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdrawPassedRequest();
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  function fastWithdraw(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdraw(collateralAmount);
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  function emergencyShutdown(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative
  ) external checkDerivative(self, derivative) {
    derivative.emergencyShutdown();
  }

  function settleEmergencyShutdown(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    bytes32 liquidity_provider_role
  ) external returns (uint256 amountSettled) {
    IERC20 tokenCurrency = self.syntheticToken;

    IERC20 collateralToken = self.collateralToken;

    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));

    bool isLiquidityProvider =
      IRole(address(this)).hasRole(liquidity_provider_role, msg.sender);

    require(
      numTokens.isGreaterThan(0) || isLiquidityProvider,
      'Account has nothing to settle'
    );

    if (numTokens.isGreaterThan(0)) {
      tokenCurrency.safeTransferFrom(
        msg.sender,
        address(this),
        numTokens.rawValue
      );

      tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);
    }

    derivative.settleEmergencyShutdown();

    FixedPoint.Unsigned memory totalToRedeem;

    if (isLiquidityProvider) {
      totalToRedeem = FixedPoint.Unsigned(
        collateralToken.balanceOf(address(this))
      );
    } else {
      FixedPoint.Unsigned memory dueCollateral =
        numTokens.mul(derivative.emergencyShutdownPrice());

      totalToRedeem = FixedPoint.min(
        dueCollateral,
        FixedPoint.Unsigned(collateralToken.balanceOf(address(this)))
      );
    }
    amountSettled = totalToRedeem.rawValue;

    collateralToken.safeTransfer(msg.sender, amountSettled);

    emit Settlement(
      msg.sender,
      address(this),
      numTokens.rawValue,
      amountSettled
    );
  }

  function setFeePercentage(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory _feePercentage
  ) external {
    require(
      _feePercentage.rawValue < 10**(18),
      'Fee Percentage must be less than 100%'
    );
    self.fee.feePercentage = _feePercentage;
    emit SetFeePercentage(_feePercentage.rawValue);
  }

  function setFeeRecipients(
    ISynthereumPoolStorage.Storage storage self,
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external {
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
    emit SetFeeRecipients(_feeRecipients, _feeProportions);
  }

  function setStartingCollateralization(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory startingCollateralRatio
  ) external {
    self.startingCollateralization = startingCollateralRatio;
  }

  function addRoleInDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPool.DerivativeRoles derivativeRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (derivativeRole == ISynthereumPool.DerivativeRoles.ADMIN) {
      derivative.addAdmin(addressToAdd);
    } else {
      ISynthereumPool pool = ISynthereumPool(addressToAdd);
      IERC20 collateralToken = self.collateralToken;
      require(
        collateralToken == pool.collateralToken(),
        'Collateral tokens do not match'
      );
      require(
        self.syntheticToken == pool.syntheticToken(),
        'Synthetic tokens do not match'
      );
      ISynthereumFinder finder = self.finder;
      require(finder == pool.synthereumFinder(), 'Finders do not match');
      ISynthereumPoolRegistry poolRegister =
        ISynthereumPoolRegistry(
          finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
        );
      poolRegister.isPoolDeployed(
        pool.syntheticTokenSymbol(),
        collateralToken,
        pool.version(),
        address(pool)
      );
      if (derivativeRole == ISynthereumPool.DerivativeRoles.POOL) {
        derivative.addPool(addressToAdd);
      } else if (
        derivativeRole == ISynthereumPool.DerivativeRoles.ADMIN_AND_POOL
      ) {
        derivative.addAdminAndPool(addressToAdd);
      }
    }
  }

  function renounceRoleInDerivative(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPool.DerivativeRoles derivativeRole
  ) external checkDerivative(self, derivative) {
    if (derivativeRole == ISynthereumPool.DerivativeRoles.ADMIN) {
      derivative.renounceAdmin();
    } else if (derivativeRole == ISynthereumPool.DerivativeRoles.POOL) {
      derivative.renouncePool();
    } else if (
      derivativeRole == ISynthereumPool.DerivativeRoles.ADMIN_AND_POOL
    ) {
      derivative.renounceAdminAndPool();
    }
  }

  function addRoleInSynthToken(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPool.SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (synthTokenRole == ISynthereumPool.SynthTokenRoles.ADMIN) {
      derivative.addSyntheticTokenAdmin(addressToAdd);
    } else {
      require(
        self.syntheticToken == IDerivative(addressToAdd).tokenCurrency(),
        'Synthetic tokens do not match'
      );
      if (synthTokenRole == ISynthereumPool.SynthTokenRoles.MINTER) {
        derivative.addSyntheticTokenMinter(addressToAdd);
      } else if (synthTokenRole == ISynthereumPool.SynthTokenRoles.BURNER) {
        derivative.addSyntheticTokenBurner(addressToAdd);
      } else if (
        synthTokenRole ==
        ISynthereumPool.SynthTokenRoles.ADMIN_AND_MINTER_AND_BURNER
      ) {
        derivative.addSyntheticTokenAdminAndMinterAndBurner(addressToAdd);
      }
    }
  }

  function renounceRoleInSynthToken(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPool.SynthTokenRoles synthTokenRole
  ) external checkDerivative(self, derivative) {
    if (synthTokenRole == ISynthereumPool.SynthTokenRoles.ADMIN) {
      derivative.renounceSyntheticTokenAdmin();
    } else if (synthTokenRole == ISynthereumPool.SynthTokenRoles.MINTER) {
      derivative.renounceSyntheticTokenMinter();
    } else if (synthTokenRole == ISynthereumPool.SynthTokenRoles.BURNER) {
      derivative.renounceSyntheticTokenBurner();
    } else if (
      synthTokenRole ==
      ISynthereumPool.SynthTokenRoles.ADMIN_AND_MINTER_AND_BURNER
    ) {
      derivative.renounceSyntheticTokenAdminAndMinterAndBurner();
    }
  }

  function setIsContractAllowed(
    ISynthereumPoolStorage.Storage storage self,
    bool isContractAllowed
  ) external {
    require(
      self.isContractAllowed != isContractAllowed,
      'Contract flag already set'
    );
    self.isContractAllowed = isContractAllowed;
  }

  function checkMetaTxParams(
    ISynthereumPoolStorage.Storage storage self,
    address sender,
    address derivativeAddr,
    uint256 feePercentage,
    uint256 nonce,
    uint256 expiration
  ) internal checkDerivative(self, IDerivative(derivativeAddr)) {
    require(sender == msg.sender, 'Wrong user account');
    require(now <= expiration, 'Meta-signature expired');
    require(
      feePercentage == self.fee.feePercentage.rawValue,
      'Wrong fee percentage'
    );
    require(nonce == self.nonces[sender]++, 'Invalid nonce');
  }

  function pullCollateral(
    ISynthereumPoolStorage.Storage storage self,
    address from,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeTransferFrom(
      from,
      address(this),
      numTokens.rawValue
    );
  }

  function mintSynTokens(
    ISynthereumPoolStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.create(collateralAmount, numTokens);
  }

  function transferSynTokens(
    ISynthereumPoolStorage.Storage storage self,
    address recipient,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.syntheticToken.safeTransfer(recipient, numTokens.rawValue);
  }

  function redeemForCollateral(
    address tokenHolder,
    IDerivative derivative,
    FixedPoint.Unsigned memory numTokens
  ) internal returns (FixedPoint.Unsigned memory amountWithdrawn) {
    require(numTokens.isGreaterThan(0), 'Number of tokens to redeem is 0');

    IERC20 tokenCurrency = derivative.positionManagerData().tokenCurrency;
    require(
      tokenCurrency.balanceOf(tokenHolder) >= numTokens.rawValue,
      'Token balance less than token to redeem'
    );

    tokenCurrency.safeTransferFrom(
      tokenHolder,
      address(this),
      numTokens.rawValue
    );

    tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);

    amountWithdrawn = derivative.redeem(numTokens);
  }

  function liquidateWithdrawal(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    address recipient
  ) internal returns (uint256 amountWithdrawn) {
    amountWithdrawn = collateralAmount.rawValue;
    self.collateralToken.safeTransfer(recipient, amountWithdrawn);
  }

  function sendFee(
    ISynthereumPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory _feeAmount
  ) internal {
    for (uint256 i = 0; i < self.fee.feeRecipients.length; i++) {
      self.collateralToken.safeTransfer(
        self.fee.feeRecipients[i],
        _feeAmount
          .mul(self.fee.feeProportions[i])
          .div(self.totalFeeProportions)
          .rawValue
      );
    }
  }

  function getDerivativeCollateral(IDerivative derivative)
    internal
    view
    returns (IERC20 collateral)
  {
    collateral = derivative.collateralCurrency();
  }

  function getGlobalCollateralizationRatio(IDerivative derivative)
    internal
    view
    returns (FixedPoint.Unsigned memory)
  {
    FixedPoint.Unsigned memory totalTokensOutstanding =
      derivative.globalPositionData().totalTokensOutstanding;
    if (totalTokensOutstanding.isGreaterThan(0)) {
      return derivative.totalPositionCollateral().div(totalTokensOutstanding);
    } else {
      return FixedPoint.fromUnscaledUint(0);
    }
  }

  function checkCollateralizationRatio(
    ISynthereumPoolStorage.Storage storage self,
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

  function checkPool(
    ISynthereumPoolStorage.Storage storage self,
    ISynthereumPool poolToCheck,
    IDerivative derivativeToCheck
  ) internal view {
    require(
      poolToCheck.isDerivativeAdmitted(derivativeToCheck),
      'Wrong derivative'
    );

    IERC20 collateralToken = self.collateralToken;
    require(
      collateralToken == poolToCheck.collateralToken(),
      'Collateral tokens do not match'
    );
    ISynthereumFinder finder = self.finder;
    require(finder == poolToCheck.synthereumFinder(), 'Finders do not match');
    ISynthereumPoolRegistry poolRegister =
      ISynthereumPoolRegistry(
        finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
      );
    require(
      poolRegister.isPoolDeployed(
        poolToCheck.syntheticTokenSymbol(),
        collateralToken,
        poolToCheck.version(),
        address(poolToCheck)
      ),
      'Destination pool not registred'
    );
  }

  function generateMintDigest(
    ISynthereumPool.MintParameters memory mintMetaTx,
    bytes32 domain_separator,
    bytes32 typeHash
  ) internal pure returns (bytes32 digest) {
    digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        domain_separator,
        keccak256(
          abi.encode(
            typeHash,
            mintMetaTx.sender,
            mintMetaTx.derivativeAddr,
            mintMetaTx.collateralAmount,
            mintMetaTx.numTokens,
            mintMetaTx.feePercentage,
            mintMetaTx.nonce,
            mintMetaTx.expiration
          )
        )
      )
    );
  }

  function generateRedeemDigest(
    ISynthereumPool.RedeemParameters memory redeemMetaTx,
    bytes32 domain_separator,
    bytes32 typeHash
  ) internal pure returns (bytes32 digest) {
    digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        domain_separator,
        keccak256(
          abi.encode(
            typeHash,
            redeemMetaTx.sender,
            redeemMetaTx.derivativeAddr,
            redeemMetaTx.collateralAmount,
            redeemMetaTx.numTokens,
            redeemMetaTx.feePercentage,
            redeemMetaTx.nonce,
            redeemMetaTx.expiration
          )
        )
      )
    );
  }

  function generateExchangeDigest(
    ISynthereumPool.ExchangeParameters memory exchangeMetaTx,
    bytes32 domain_separator,
    bytes32 typeHash
  ) internal pure returns (bytes32 digest) {
    digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        domain_separator,
        keccak256(
          abi.encode(
            typeHash,
            exchangeMetaTx.sender,
            exchangeMetaTx.derivativeAddr,
            exchangeMetaTx.destPoolAddr,
            exchangeMetaTx.destDerivativeAddr,
            exchangeMetaTx.numTokens,
            exchangeMetaTx.collateralAmount,
            exchangeMetaTx.destNumTokens,
            exchangeMetaTx.feePercentage,
            exchangeMetaTx.nonce,
            exchangeMetaTx.expiration
          )
        )
      )
    );
  }

  function checkSignature(
    bytes32 validator_role,
    bytes32 digest,
    ISynthereumPool.Signature memory signature
  ) internal view {
    address signatureAddr =
      ecrecover(digest, signature.v, signature.r, signature.s);
    require(
      IRole(address(this)).hasRole(validator_role, signatureAddr),
      'Invalid meta-signature'
    );
  }
}
