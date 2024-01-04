// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";
import "./IERC20.sol";
import "./IDerivative.sol";
import "./IDeployer.sol";
import "./IFinder.sol";
import "./IPoolDeployment.sol";

interface ISynthereumPool is ISynthereumPoolDeployment {
  struct Fee {
    FixedPoint.Unsigned feePercentage;
    address[] feeRecipients;
    uint32[] feeProportions;
  }

  struct Roles {
    address admin;
    address maintainer;
    address liquidityProvider;
    address validator;
  }

  struct MintParameters {
    address sender;
    address derivativeAddr;
    uint256 collateralAmount;
    uint256 numTokens;
    uint256 feePercentage;
    uint256 nonce;
    uint256 expiration;
  }

  struct RedeemParameters {
    address sender;
    address derivativeAddr;
    uint256 collateralAmount;
    uint256 numTokens;
    uint256 feePercentage;
    uint256 nonce;
    uint256 expiration;
  }

  struct ExchangeParameters {
    address sender;
    address derivativeAddr;
    address destPoolAddr;
    address destDerivativeAddr;
    uint256 numTokens;
    uint256 collateralAmount;
    uint256 destNumTokens;
    uint256 feePercentage;
    uint256 nonce;
    uint256 expiration;
  }

  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct SignatureVerificationParams {
    bytes32 domain_separator;
    bytes32 typeHash;
    ISynthereumPool.Signature signature;
    bytes32 validator_role;
  }

  enum DerivativeRoles {ADMIN, POOL, ADMIN_AND_POOL}

  enum SynthTokenRoles {ADMIN, MINTER, BURNER, ADMIN_AND_MINTER_AND_BURNER}

  function addDerivative(IDerivative derivative) external;

  function removeDerivative(IDerivative derivative) external;

  function mint(MintParameters memory mintMetaTx, Signature memory signature)
    external
    returns (uint256 feePaid);

  function redeem(
    RedeemParameters memory redeemMetaTx,
    Signature memory signature
  ) external returns (uint256 feePaid);

  function exchange(
    ExchangeParameters memory exchangeMetaTx,
    Signature memory signature
  ) external returns (uint256 feePaid);

  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external;

  function withdrawFromPool(uint256 collateralAmount) external;

  function depositIntoDerivative(
    IDerivative derivative,
    uint256 collateralAmount
  ) external;

  function slowWithdrawRequest(IDerivative derivative, uint256 collateralAmount)
    external;

  function slowWithdrawPassedRequest(IDerivative derivative)
    external
    returns (uint256 amountWithdrawn);

  function fastWithdraw(IDerivative derivative, uint256 collateralAmount)
    external
    returns (uint256 amountWithdrawn);

  function emergencyShutdown(IDerivative derivative) external;

  function settleEmergencyShutdown(IDerivative derivative)
    external
    returns (uint256 amountSettled);

  function setFee(Fee memory _fee) external;

  function setFeePercentage(uint256 _feePercentage) external;

  function setFeeRecipients(
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) external;

  function setStartingCollateralization(uint256 startingCollateralRatio)
    external;

  function addRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole,
    address addressToAdd
  ) external;

  function renounceRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole
  ) external;

  function addRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external;

  function renounceRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole
  ) external;

  function setIsContractAllowed(bool isContractAllowed) external;

  function getAllDerivatives() external view returns (IDerivative[] memory);

  function isDerivativeAdmitted(IDerivative derivative)
    external
    view
    returns (bool isAdmitted);

  function getStartingCollateralization()
    external
    view
    returns (uint256 startingCollateralRatio);

  function isContractAllowed() external view returns (bool isAllowed);

  function getFeeInfo() external view returns (Fee memory fee);

  function getUserNonce(address user) external view returns (uint256 nonce);

  function calculateFee(uint256 collateralAmount)
    external
    view
    returns (uint256 fee);
}
