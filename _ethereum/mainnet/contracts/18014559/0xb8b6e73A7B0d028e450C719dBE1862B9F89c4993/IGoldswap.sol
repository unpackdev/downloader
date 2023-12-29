// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IGoldswap {
    // struct Order {
    //     uint256 nonce; // Unique number per signatory per order
    //     uint256 expiry; // Expiry time (seconds since unix epoch)
    //     address signerWallet; // Party to the swap that sets terms
    //     address signerToken; // ERC20 token address transferred from signer
    //     uint256 signerAmount; // Amount of tokens transferred from signer
    //     address senderWallet; // Party to the swap that accepts terms
    //     address senderToken; // ERC20 token address transferred from sender
    //     uint256 senderAmount; // Amount of tokens transferred from sender
    //     uint8 v; // ECDSA
    //     bytes32 r;
    //     bytes32 s;
    // }

    struct TokenAmount {
        address token; // ERC20 token address 
        uint256 amount; // Amount of tokens
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Logs any swap
    event Swap(
        uint256 nonce,
        address indexed counterparty,
        address tokenTo,
        uint256 tokenToAmount,
        address indexed customer,
        address tokenFrom,
        uint256 tokenFromAmount,
        address indexed referralAddress
    );

    event Cancel(uint256 indexed nonce, address indexed signerWallet);
    event Authorize(address indexed signer, address indexed signerWallet);
    event Revoke(address indexed signer, address indexed signerWallet);
    /// @notice Logs any protocol fee modification
    /// @param oldValue the old protocol fee value
    /// @param newValue the new protocol fee value
    event ProtocolFeeUpdate(uint256 oldValue, uint256 newValue);
    /// @notice Logs any referral fee modification
    /// @param oldValue the old referral fee value
    /// @param newValue the new referral fee value
    event ReferralFeeUpdate(uint256 oldValue, uint256 newValue);
    /// @notice Logs any protocol fee address modification
    /// @param oldAddress the old protocol fee address
    /// @param newAddress the new protocol fee address
    event ProtocolFeeAddressUpdate(address oldAddress, address newAddress);
     /// @notice Logs any fee token address modification
    /// @param oldAddress the old fee token address
    /// @param newAddress the new fee token address
    event FeeTokenAddressUpdate(address oldAddress, address newAddress);
    /// @notice Logs any T&C url modification
    /// @param oldUrl the old url value
    /// @param newUrl the new url value
    event TCUrlUpdate(string oldUrl, string newUrl);

    // error ChainIdChanged();
    // error InvalidFee();
    // error InvalidFeeLight();
    // error InvalidFeeWallet();
    // error InvalidStaking();
    // error OrderExpired();
    // error MaxTooHigh();
    // error NonceAlreadyUsed(uint256);
    // error ScaleTooHigh();
    // error SignatureInvalid();
     error SignatoryInvalid();
    // error SignatoryUnauthorized();
    // error Unauthorized();

    function swap(
        address recipient,
        address referralAddress,
        uint256 nonce,
        uint256 expiry,
        address counterparty,
        TokenAmount calldata to,
        TokenAmount calldata from,
        Signature calldata signature
    ) external;

    function cancel(uint256[] calldata _nonces) external;
    function authorize(address signatory) external;
    function revoke() external;
    /// @notice Returns the next usable nonce for the signer
    /// @param signer address Address of the signer
    function getNextNonce(address signer) external view returns(uint256);

    /// @notice Set the protocol fee percentage in bps
    /// @dev only an admin address can call this function. Emits ProtocolFeeUpdate event
    /// @param value the percentage value * 100. For a 100% fee (not advised), set the protocol fee to 10000
    function setProtocolFee(uint256 value) external;

    /// @notice Set the referral fee percentage in bps
    /// @dev only an admin address can call this function. Emits ReferralFeeUpdate event
    /// @param value the percentage value * 100. For a 100% fee (not advised), set the protocol fee to 10000
    function setReferralFee(uint256 value) external;

    /// @notice Set the protocol fee wallet address
    /// @dev only an admin address address can call this function. Emits ProtocolFeeAddressUpdate event
    /// @param value the protocol fee wallet address
    function setProtocolFeeAddress(address value) external;

    /// @notice Set the fee token address
    /// @dev only an admin address address can call this function. Emits FeeTokenAddressUpdated event
    /// @param value the fee token address
    function setFeeTokenAddress(address value) external;

    /// @notice Set the T&C url
    /// @dev only granted address can call this function. Emits TCUrlUpdated event
    /// @param url the T&C url
    function setTcURL(string memory url) external;
}
