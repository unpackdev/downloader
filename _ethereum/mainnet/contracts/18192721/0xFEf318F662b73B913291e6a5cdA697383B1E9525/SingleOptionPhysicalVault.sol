// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import "./TokenIdUtil.sol";

// abstracts
import "./PhysicalOptionsVault.sol";
import "./SingleOptionPhysicalVaultStorage.sol";

import "./types.sol";

import "./errors.sol";
import "./types.sol";
import "./constants.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in VaultStorage.
 * SingleProductVault should not inherit from any other contract aside from OptionVault, VaultStorage
 */
contract SingleOptionPhysicalVault is PhysicalOptionsVault, SingleOptionPhysicalVaultStorage {
    using TokenIdUtil for uint256;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event GoldenTokenSet(uint256 goldenToken, uint256 newGoldenToken);

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _registrar is the address of the registrar contract
     * @param _share is the erc1155 contract that issues shares
     * @param _marginEngine is the margin engine used for Grappa (options protocol)
     */
    constructor(address _registrar, address _share, address _marginEngine)
        PhysicalOptionsVault(_registrar, _share, _marginEngine)
    {}

    /**
     * @notice Initializes the OptionsVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _auction is the address that settles the option contract
     * @param _goldenToken is the token to reference for characteristics
     */
    function initialize(InitParams calldata _initParams, address _auction, uint256 _goldenToken, Collateral calldata _premium)
        external
        initializer
    {
        (, uint40 productId,,, uint64 exerciseWindow_) = _goldenToken.parseTokenId();

        __PhysicalOptionsVault_init(_initParams, _auction, exerciseWindow_, _premium);

        if (productId == 0) revert SOPV_BadProductId();

        goldenToken = _goldenToken;
    }

    function _setExerciseWindow(uint256 _exerciseWindow) internal virtual override {
        super._setExerciseWindow(_exerciseWindow);

        uint256 _goldenToken = goldenToken;

        // set the last 64 bits of tokenId which is the exercise window to the new value
        unchecked {
            goldenToken = ((goldenToken >> 64) << 64) + _exerciseWindow;
        }

        emit GoldenTokenSet(_goldenToken, goldenToken);
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    // Commenting out for space
    // function setGoldenToken(uint256 _goldenToken) external {
    //     _onlyOwner();

    //     (, uint40 productId,,,) = _goldenToken.parseTokenId();

    //     if (productId == 0) revert SOPV_BadProductId();

    //     emit GoldenTokenSet(goldenToken, _goldenToken);

    //     goldenToken = _goldenToken;
    // }

    function verifyOptions(uint256[] calldata _options) external view override {
        uint256 currentRoundExpiry = expiry[vaultState.round];

        // initRounds set value to 1, so 0 or 1 are seed values
        if (currentRoundExpiry <= PLACEHOLDER_UINT) revert SOPV_BadExpiry();

        (TokenType tokenType, uint40 productId,,,) = goldenToken.parseTokenId();

        for (uint256 i; i < _options.length;) {
            (TokenType tokenType_, uint40 productId_, uint64 expiry,, uint64 exerciseWindow_) =
                TokenIdUtil.parseTokenId(_options[i]);

            if (tokenType_ != tokenType) revert SOPV_TokenTypeMismatch();

            if (productId_ != productId) revert SOPV_ProductIdMismatch();

            // expirations need to match
            if (currentRoundExpiry != expiry) revert SOPV_ExpiryMismatch();

            if (exerciseWindow_ != exerciseWindow) revert SOPV_ExerciseWindowMismatch();

            unchecked {
                ++i;
            }
        }
    }
}
