/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */

pragma solidity 0.8.16;

import "./RWAHubOffChainRedemptions.sol";
import "./KYCRegistryClient.sol";
import "./IPricerWithOracle.sol";

contract OUSGManager is RWAHubOffChainRedemptions, KYCRegistryClient {
  bytes32 public constant REDEMPTION_PROVER_ROLE =
    keccak256("REDEMPTION_PROVER_ROLE");

  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount,
    address _kycRegistry,
    uint256 _kycRequirementGroup
  )
    RWAHubOffChainRedemptions(
      _collateral,
      _rwa,
      managerAdmin,
      pauser,
      _assetSender,
      _feeRecipient,
      _minimumDepositAmount,
      _minimumRedemptionAmount
    )
  {
    _setKYCRegistry(_kycRegistry);
    _setKYCRequirementGroup(_kycRequirementGroup);
  }

  /**
   * @notice Function to enforce KYC/AML requirements that will
   *         be implemented on calls to `requestSubscription` and
   *         `claimRedemption`
   *
   * @param account The account that we would like to check the KYC
   *                status for
   */
  function _checkRestrictions(address account) internal view override {
    // Check Basic KYC requirements for OMMF
    if (!_getKYCStatus(account)) {
      revert KYCCheckFailed();
    }
  }

  /*//////////////////////////////////////////////////////////////
                        KYC Registry Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Update KYC group of the contract for which
   *         accounts are checked against
   *
   * @param _kycRequirementGroup The new KYC requirement group
   */
  function setKYCRequirementGroup(
    uint256 _kycRequirementGroup
  ) external onlyRole(MANAGER_ADMIN) {
    _setKYCRequirementGroup(_kycRequirementGroup);
  }

  /**
   * @notice Function to add a redemption proof to the contract
   *
   * @param txHash           The tx hash (redemption Id) of the redemption
   * @param user             The address of the user who made the redemption
   * @param rwaAmountToBurn  The amount of OMMF burned
   * @param timestamp        The timestamp of the redemption request
   */
  function addRedemptionProof(
    bytes32 txHash,
    address user,
    uint256 rwaAmountToBurn,
    uint256 timestamp
  ) external onlyRole(REDEMPTION_PROVER_ROLE) checkRestrictions(user) {
    if (redemptionIdToRedeemer[txHash].user != address(0)) {
      revert RedemptionProofAlreadyExists();
    }
    if (rwaAmountToBurn == 0) {
      revert RedemptionTooSmall();
    }
    if (user == address(0)) {
      revert RedeemerNull();
    }
    rwa.burnFrom(msg.sender, rwaAmountToBurn);
    redemptionIdToRedeemer[txHash] = Redeemer(user, rwaAmountToBurn, 0);

    emit RedemptionProofAdded(txHash, user, rwaAmountToBurn, timestamp);
  }

  /**
   * @notice Update KYC registry address
   *
   * @param _kycRegistry The new KYC registry address
   */
  function setKYCRegistry(
    address _kycRegistry
  ) external onlyRole(MANAGER_ADMIN) {
    _setKYCRegistry(_kycRegistry);
  }

  function setPriceIdForDeposits(
    bytes32[] calldata depositIds,
    uint256[] calldata priceIds
  ) public virtual override onlyRole(PRICE_ID_SETTER_ROLE) {
    if (!IPricerWithOracle(address(pricer)).isValid(priceIds)) {
      revert InvalidPriceId();
    }
    super.setPriceIdForDeposits(depositIds, priceIds);
  }

  function setPriceIdForRedemptions(
    bytes32[] calldata redemptionIds,
    uint256[] calldata priceIds
  ) public virtual override onlyRole(PRICE_ID_SETTER_ROLE) {
    if (!IPricerWithOracle(address(pricer)).isValid(priceIds)) {
      revert InvalidPriceId();
    }
    super.setPriceIdForRedemptions(redemptionIds, priceIds);
  }

  /**
   * @notice Event emitted when redemption proof has been added
   *
   * @param txHash                Tx hash (redemption id) of the redemption transfer
   * @param user                  Address of the user who made the redemption
   * @param rwaAmountBurned       Amount of OMMF burned
   * @param timestamp             Timestamp of the redemption
   */
  event RedemptionProofAdded(
    bytes32 indexed txHash,
    address indexed user,
    uint256 rwaAmountBurned,
    uint256 timestamp
  );

  error KYCCheckFailed();
  error InvalidPriceId();
}
