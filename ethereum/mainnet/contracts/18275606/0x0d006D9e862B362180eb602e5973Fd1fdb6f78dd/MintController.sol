// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./EIP712.sol";

interface IWPokt {
    function batchMint(address[] calldata recipients, uint256[] calldata amounts, uint256[] calldata nonces) external;

    function mint(address recipient, uint256 amount, uint256 nonce) external;

    function hasRole(bytes32 role, address account) external returns (bool);
}

contract MintController is EIP712 {
    /*//////////////////////////////////////////////////////////////
    // Immutable Storage
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    IWPokt public immutable wPokt;

    /*//////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public validators;
    uint256 public validatorCount;
    uint256 public signerThreshold = 50; // out of 100

    uint256 private _currentMintLimit = 335_000 ether;
    uint256 public lastMint;

    uint256 public maxMintLimit = 335_000 ether;
    uint256 public mintPerSecond = 3.8773 ether;

    /*//////////////////////////////////////////////////////////////
    // Events and Errors
    //////////////////////////////////////////////////////////////*/

    error OverMintLimit();
    error NonAdmin();
    error InvalidSignatureRatio();
    error InvalidSignatures();
    error InvalidRemoveValidator();
    error InvalidAddValidator();
    error NonZero();
    error BelowMinThreshold();
    error InvalidCooldownConfig();

    event MintCooldownSet(uint256 newLimit, uint256 newCooldown);
    event NewValidator(address indexed validator);
    event RemovedValidator(address indexed validator);
    event CurrentMintLimit(uint256 indexed limit, uint256 indexed lastMint);
    event SignerThresholdSet(uint256 indexed ratio);

    // Data object for signing and digest construction
    struct MintData {
        address recipient;
        uint256 amount;
        uint256 nonce;
    }

    constructor(address _wPokt) EIP712("MintController", "1") {
        if (_wPokt == address(0)) {
            revert NonZero();
        }
        wPokt = IWPokt(_wPokt);
    }

    /*//////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Ensure the function is only called by admin.
    /// If caller is not an admin, throws an error message.
    modifier onlyAdmin() {
        if (!wPokt.hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NonAdmin();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
    // Access Control
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds a validator to the list of validators.
    /// @dev Can only be called by admin.
    /// Emits a NewValidator event upon successful addition.
    /// @param validator The address of the validator to add.
    function addValidator(address validator) external onlyAdmin {
        if (validator == address(0)) {
            revert NonZero();
        }
        if (validators[validator] == true) {
            revert InvalidAddValidator();
        }
        validators[validator] = true;
        validatorCount++;
        emit NewValidator(validator);
    }

    /// @notice Removes a validator from the list of validators.
    /// @dev Can only be called by admin.
    /// Emits a RemovedValidator event upon successful removal.
    /// @param validator The address of the validator to remove.
    function removeValidator(address validator) external onlyAdmin {
        if (validatorCount - 1 < signerThreshold) {
            revert BelowMinThreshold();
        }
        if (validator == address(0)) {
            revert NonZero();
        }
        if (validators[validator] == false) {
            revert InvalidRemoveValidator();
        }
        validators[validator] = false;
        validatorCount--;
        emit RemovedValidator(validator);
    }

    /// @notice Sets the signature ratio.
    /// @dev Can only be called by admin.
    /// Emits a SignerThresholdSet event upon successful setting.
    /// @param signatureRatio The new signature ratio to set.
    function setSignerThreshold(uint256 signatureRatio) external onlyAdmin {
        if (signatureRatio > validatorCount || signatureRatio == 0 || validatorCount / 2 > signatureRatio) {
            revert InvalidSignatureRatio();
        }
        signerThreshold = signatureRatio;
        emit SignerThresholdSet(signatureRatio);
    }

    /// @notice Sets the mint limit and mint per second cooldown rate.
    /// @dev Can only be called by admin.
    /// Emits a MintCooldownSet event upon successful setting.
    /// @param newLimit The new mint limit to set.
    /// @param newMintPerSecond The new mint per second cooldown rate to set.
    function setMintCooldown(uint256 newLimit, uint256 newMintPerSecond) external onlyAdmin {
        if (newLimit < mintPerSecond) {
            revert InvalidCooldownConfig();
        }
        maxMintLimit = newLimit;
        mintPerSecond = newMintPerSecond;

        emit MintCooldownSet(newLimit, newMintPerSecond);
    }

    /*//////////////////////////////////////////////////////////////
    // Mutative Public Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint wrapped POKT tokens to a specific address with a signature.
    /// @dev Can be called by anyone
    /// If the amount to mint is more than the current mint limit, transaction is reverted.
    /// @param data The mint data to be verified.
    /// @param signatures The signatures to be verified.
    function mintWrappedPocket(MintData calldata data, bytes[] calldata signatures) external {
        if (_verify(data, signatures) == false) {
            revert InvalidSignatures();
        }

        uint256 remainingMintable = _enforceMintLimit(data.amount);
        wPokt.mint(data.recipient, data.amount, data.nonce);
        emit CurrentMintLimit(remainingMintable, lastMint);
    }

    /*//////////////////////////////////////////////////////////////
    // Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Verifies the mint data signature.
    /// @dev internal function to be called by mintWithSignature.
    /// @param _data The mint data to be verified.
    /// @param _signatures The signatures to be verified.
    /// @return True if the signatures are valid, false otherwise.
    function _verify(MintData calldata _data, bytes[] calldata _signatures) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("MintData(address recipient,uint256 amount,uint256 nonce)"),
                    _data.recipient,
                    _data.amount,
                    _data.nonce
                )
            )
        );

        address lastSigner;
        address currentSigner;

        uint256 validSignatures = 0;
        uint256 signatureLength = _signatures.length;

        for (uint256 i; i < signatureLength;) {
            currentSigner = ECDSA.recover(digest, _signatures[i]);
            if (validators[currentSigner] && currentSigner > lastSigner) {
                validSignatures++;
                lastSigner = currentSigner;
            }
            unchecked {
                ++i;
            }
        }

        return validSignatures > 0 && validSignatures >= signerThreshold;
    }

    /// @dev Updates the mint limit based on the cooldown mechanism.
    /// @param _amount The amount of tokens to mint.
    /// @return The updated mint limit.
    function _enforceMintLimit(uint256 _amount) internal returns (uint256) {
        uint256 timePassed = block.timestamp - lastMint;
        uint256 mintableFromCooldown = timePassed * mintPerSecond;
        uint256 previousMintLimit = _currentMintLimit;
        uint256 maxMintable = maxMintLimit;

        // We enforce that amount is not greater than the maximum mint or the current allowed by cooldown
        if (_amount > mintableFromCooldown + previousMintLimit || _amount > maxMintable) {
            revert OverMintLimit();
        }

        // If the cooldown has fully recovered; we are allowed to mint up to the maximum amount
        if (previousMintLimit + mintableFromCooldown >= maxMintable) {
            _currentMintLimit = maxMintable - _amount;
            lastMint = block.timestamp;
            return maxMintable - _amount;

            // Otherwise the cooldown has not fully recovered; we are allowed to mint up to the recovered amount
        } else {
            uint256 mintable = previousMintLimit + mintableFromCooldown;
            _currentMintLimit = mintable - _amount;
            lastMint = block.timestamp;
            return mintable - _amount;
        }
    }

    /*//////////////////////////////////////////////////////////////
    // View Functions
    //////////////////////////////////////////////////////////////*/
    function currentMintLimit() external view returns (uint256) {
        uint256 mintableFromCooldown = (block.timestamp - lastMint) * mintPerSecond;
        if (mintableFromCooldown + _currentMintLimit > maxMintLimit) {
            return maxMintLimit;
        } else {
            return mintableFromCooldown + _currentMintLimit;
        }
    }

    function lastMintLimit() external view returns (uint256) {
        return _currentMintLimit;
    }
}
