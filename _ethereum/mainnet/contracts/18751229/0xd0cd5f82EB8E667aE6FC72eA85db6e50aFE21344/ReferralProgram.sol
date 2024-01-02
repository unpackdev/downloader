// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IAccessControlUpgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./Errors.sol";

import "./ReferralProgramStorage.sol";
import "./Constants.sol";
import "./IReferralProgram.sol";

contract ReferralProgram is IReferralProgram, ReferralProgramStorage {
    bytes public constant MAGIC_MESSAGE = "Referral link";

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Throws if caller is not granted with _role
     * @param _role The role that is being checked for a function caller
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControlUpgradeable(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function initialize(address _registry) external override initializer {
        _require(
            IERC165Upgradeable(_registry).supportsInterface(type(IAccessControlUpgradeable).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
        __ERC165_init();
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function register(bytes calldata _sig) external override {
        _require(
            referrerOf[msg.sender] == address(0) && !alreadyReferrer[msg.sender],
            Errors.CALLER_ALREADY_REGISTERED.selector
        );
        address parent = ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(MAGIC_MESSAGE), _sig);
        _require(msg.sender != parent, Errors.MISMATCH.selector);

        if (!alreadyReferrer[parent]) {
            alreadyReferrer[parent] = true;
            referrers.push(parent);
        }
        referrerOf[msg.sender] = parent;
        referralsOf[parent].push(msg.sender);
        emit RegisteredUser(msg.sender, parent);
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function setReferrals(
        ReferralProgramUnit[] calldata referralProgramUnits
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        for (uint256 i; i < referralProgramUnits.length; i++) {
            if (referralProgramUnits[i].referrals.length > 0) {
                for (uint256 j; j < referralProgramUnits[i].referrals.length; j++) {
                    if (referrerOf[referralProgramUnits[i].referrals[j]] == address(0)) {
                        referralsOf[referralProgramUnits[i].referrer].push(referralProgramUnits[i].referrals[j]);
                        referrerOf[referralProgramUnits[i].referrals[j]] = referralProgramUnits[i].referrer;
                        emit SetReferralByAdmin(referralProgramUnits[i].referrer, referralProgramUnits[i].referrals[j]);
                    }
                }
            }
            if (
                !alreadyReferrer[referralProgramUnits[i].referrer] &&
                referralsOf[referralProgramUnits[i].referrer].length > 0
            ) {
                alreadyReferrer[referralProgramUnits[i].referrer] = true;
                referrers.push(referralProgramUnits[i].referrer);
                emit SetReferrerByAdmin(referralProgramUnits[i].referrer);
            }
        }
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function getReferralsOf(address _referrer) external view override returns (address[] memory) {
        return referralsOf[_referrer];
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function getReferralsOfLength(address _referrer) external view override returns (uint256) {
        return referralsOf[_referrer].length;
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function getReferrers() external view override returns (address[] memory) {
        return referrers;
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == type(IReferralProgram).interfaceId;
    }
}
