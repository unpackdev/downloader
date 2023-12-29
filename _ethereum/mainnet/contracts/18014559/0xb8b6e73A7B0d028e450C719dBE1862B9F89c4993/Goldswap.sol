// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./AccessControlUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IGoldswap.sol";

contract Goldswap is AccessControlUpgradeable, IGoldswap, EIP712Upgradeable {
    using SafeERC20 for IERC20;

    //bytes32 public constant CUSTOM_ROLE = keccak256("CUSTOM_ROLE");
    mapping(address => uint256) internal nonces;

    // Mapping of signer to authorized signatory
    mapping(address => address) internal authorizations;

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "OrderERC20(uint256 nonce,uint256 expiry,address counterparty,address tokenTo,uint256 tokenToAmount,",
                "address referralAddress,address customer,address tokenFrom,uint256 tokenFromAmount)"
            )
        );

    // Domain name and version for use in EIP712 signatures
    string public constant DOMAIN_NAME = "SWAP_ERC20";
    string public constant DOMAIN_VERSION = "1";
    uint256 public DOMAIN_CHAIN_ID;
    bytes32 public DOMAIN_SEPARATOR;

    uint256 public protocolFee;
    uint256 public referralFee;
    address public protocolFeeAddress;
    address public feeTokenAddress;
    string public tcUrl;

    function initialize(address _feeTokenAddress) public virtual initializer {
        __AccessControl_init();
        __EIP712_init_unchained(DOMAIN_NAME, DOMAIN_VERSION);

        DOMAIN_CHAIN_ID = block.chainid;
        DOMAIN_SEPARATOR = _domainSeparatorV4();

        protocolFeeAddress = msg.sender;
        feeTokenAddress = _feeTokenAddress;
        protocolFee = 0;
        referralFee = 0;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Swap
    /// @param recipient address wallet address of the recipient
    /// @param referralAddress address wallet address of the referrer
    /// @param nonce uint256 nonce sequence number of the swap
    /// @param expiry uint256 date and time of swap expiration
    /// @param counterparty address wallet address of the signer (liquidity provider)
    /// @param to TokenAmount token being bought
    /// @param from TokenAmount token being sold
    /// @param signature Signature ECDSA signature
    function swap(
        address recipient,
        address referralAddress,
        uint256 nonce,
        uint256 expiry,
        address counterparty,
        TokenAmount calldata to,
        TokenAmount calldata from,
        Signature calldata signature
    ) external override {
        // Ensure the order is valid for signer and sender
        _check(
            nonce,
            expiry,
            counterparty,
            to,
            from,
            msg.sender,
            signature,
            referralAddress
        );

        require(
            feeTokenAddress == from.token || feeTokenAddress == to.token,
            "One of the tokens must be the fee token"
        );

        if (feeTokenAddress == from.token) {
            _swapFeeFrom(from, to, referralAddress, counterparty, recipient);
        } else {
            _swapFeeTo(from, to, referralAddress, counterparty, recipient);
        }

        // Emit a Swap event
        emit Swap(
            nonce,
            counterparty,
            to.token,
            to.amount,
            msg.sender,
            from.token,
            from.amount,
            referralAddress
        );
    }

    function _swapFeeFrom(
        TokenAmount calldata from,
        TokenAmount calldata to,
        address referralAddress,
        address counterparty,
        address recipient
    ) internal {
        (address feeWallet, uint256 feePercentage) = _calculateFees(
            referralAddress
        );

        uint256 feeAmount = (from.amount * feePercentage) / 10000;

        // Transfer token from customer to counterparty
        IERC20(from.token).safeTransferFrom(
            msg.sender,
            counterparty,
            from.amount - feeAmount
        );

        // Transfer token from counterparty to recipient
        IERC20(to.token).safeTransferFrom(counterparty, recipient, to.amount);

        if (feeAmount > 0 && feeWallet != address(0))
            // Transfer token from customer to fee address
            IERC20(from.token).safeTransferFrom(
                msg.sender,
                feeWallet,
                feeAmount
            );
    }

    function _swapFeeTo(
        TokenAmount calldata from,
        TokenAmount calldata to,
        address referralAddress,
        address counterparty,
        address recipient
    ) internal {
        (address feeWallet, uint256 feePercentage) = _calculateFees(
            referralAddress
        );
        uint256 feeAmount = (to.amount * feePercentage) / 10000;

        // Transfer token from customer to counterparty
        IERC20(from.token).safeTransferFrom(
            msg.sender,
            counterparty,
            from.amount
        );

        // Transfer token from counterparty to recipient
        IERC20(to.token).safeTransferFrom(
            counterparty,
            recipient,
            to.amount - feeAmount
        );

        if (feeAmount > 0 && feeWallet != address(0))
            // Transfer token from counterparty to fee address
            IERC20(to.token).safeTransferFrom(
                counterparty,
                feeWallet,
                feeAmount
            );
    }

    /// @notice Cancel one or more nonces
    /// @dev Cancelled nonces are marked as used
    /// @dev Emits a Cancel event
    /// @dev Out of gas may occur in arrays of length > 400
    /// @param _nonces uint256[] List of nonces to cancel
    function cancel(uint256[] calldata _nonces) external override {
        for (uint256 i = 0; i < _nonces.length; i++) {
            uint256 nonce = _nonces[i];
            if (_markNonceAsUsed(msg.sender, nonce)) {
                emit Cancel(nonce, msg.sender);
            }
        }
    }

    /// @notice Returns the desired fee wallet and percentage
    /// @param referralAddress address referral address
    function _calculateFees(
        address referralAddress
    ) internal view returns (address, uint256) {
        if (referralAddress == address(0))
            return (protocolFeeAddress, protocolFee);

        return (referralAddress, referralFee);
    }

    /// @notice Authorize a signatory
    /// @param signatory address wallet of the signatory to authorize
    /// @dev Emits an Authorize event
    function authorize(address signatory) external override {
        if (signatory == address(0)) revert SignatoryInvalid();
        authorizations[msg.sender] = signatory;
        emit Authorize(signatory, msg.sender);
    }

    /// @notice Revoke the signatory
    /// @dev Emits a Revoke event
    function revoke() external override {
        address tmp = authorizations[msg.sender];
        delete authorizations[msg.sender];
        emit Revoke(tmp, msg.sender);
    }

    /// @notice Returns true if the nonce has been used
    /// @param client address Client wallet address
    /// @param nonce uint256 Nonce being checked
    function _nonceUsed(
        address client,
        uint256 nonce
    ) internal view returns (bool) {
        return nonces[client] >= nonce;
    }

    /// @notice Returns the next usable nonce for the signer
    /// @param client address Client wallet address
    function getNextNonce(
        address client
    ) external view override returns (uint256) {
        return nonces[client] + 1;
    }

    /// @notice Marks a nonce as used for the given client
    /// @param client address Client wallet address
    /// @param nonce uint256 Nonce to be marked as used
    /// @return bool True if the nonce was not marked as used already
    function _markNonceAsUsed(
        address client,
        uint256 nonce
    ) internal returns (bool) {
        if (_nonceUsed(client, nonce)) return false;

        nonces[client] = nonce;
        return true;
    }

    /// @param nonce uint256 nonce sequence number of the swap
    /// @param expiry uint256 date and time of swap expiration
    /// @param counterparty address wallet address of the signer (liquidity provider)
    /// @param to TokenAmount token being bought
    /// @param from TokenAmount token being sold
    /// @param customer address wallet address of the customer
    /// @param signature Signature ECDSA signature
    /// @param referralAddress address wallet address of the referrer
    function _check(
        uint256 nonce,
        uint256 expiry,
        address counterparty,
        TokenAmount calldata to,
        TokenAmount calldata from,
        address customer,
        Signature calldata signature,
        address referralAddress
    ) internal {
        // Ensure execution on the intended chain
        require(DOMAIN_CHAIN_ID == block.chainid, "_check: invalid chain ID");

        // Ensure the expiry is not passed
        require(expiry >= block.timestamp, "_check: order expired");

        // Recover the signatory from the hash and signature
        (address signatory, ) = ECDSAUpgradeable.tryRecover(
            _getOrderHash(
                nonce,
                expiry,
                counterparty,
                to.token,
                to.amount,
                referralAddress,
                customer,
                from.token,
                from.amount
            ),
            signature.v,
            signature.r,
            signature.s
        );

        // Ensure the signatory is not null
        require(signatory != address(0), "_check: invalid signature");

        // Ensure signatory is authorized to sign
        if (authorizations[counterparty] != address(0)) {
            // If one is set by signer wallet, signatory must be authorized
            require(
                signatory == authorizations[counterparty],
                "_check: signature not presented by delegate"
            );
        } else {
            // Otherwise, signatory must be signer wallet
            require(
                signatory == counterparty,
                "_check: signature not presented by correct counterparty"
            );
        }

        // Ensure the nonce is not yet used and if not mark it used
        require(
            _markNonceAsUsed(customer, nonce),
            "_check: nonce already used"
        );
    }

    /// @notice Hash order parameters
    /// @param nonce uint256
    /// @param expiry uint256
    /// @param counterparty address
    /// @param tokenTo address
    /// @param tokenToAmount uint256
    /// @param referralAddress address
    /// @param customer address
    /// @param tokenFrom address
    /// @param tokenFromAmount uint256
    /// @return bytes32
    function _getOrderHash(
        uint256 nonce,
        uint256 expiry,
        address counterparty,
        address tokenTo,
        uint256 tokenToAmount,
        address referralAddress,
        address customer,
        address tokenFrom,
        uint256 tokenFromAmount
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01", // EIP191: Indicates EIP712
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            ORDER_TYPEHASH,
                            nonce,
                            expiry,
                            counterparty,
                            tokenTo,
                            tokenToAmount,
                            referralAddress,
                            customer,
                            tokenFrom,
                            tokenFromAmount
                        )
                    )
                )
            );
    }

    /// @notice Set the protocol fee percentage in bps
    /// @dev only an admin address can call this function. Emits ProtocolFeeUpdate event
    /// @param value the percentage value * 100. For a 100% fee (not advised), set the protocol fee to 10000
    function setProtocolFee(
        uint256 value
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            value <= 10000 && value >= 0,
            "setProtocolFee: invalid fee percentage"
        );
        uint256 oldProtocolFee = protocolFee;
        protocolFee = value;
        emit ProtocolFeeUpdate(oldProtocolFee, protocolFee);
    }

    /// @notice Set the referral fee percentage in bps
    /// @dev only an admin address can call this function. Emits ReferralFeeUpdate event
    /// @param value the percentage value * 100. For a 100% fee (not advised), set the protocol fee to 10000
    function setReferralFee(
        uint256 value
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            value <= 10000 && value >= 0,
            "setReferralFee: invalid fee percentage"
        );
        uint256 oldReferralFee = referralFee;
        referralFee = value;
        emit ReferralFeeUpdate(oldReferralFee, referralFee);
    }

    /// @notice Set the protocol fee wallet address
    /// @dev only an admin address address can call this function. Emits ProtocolFeeAddressUpdate event
    /// @param value the protocol fee wallet address
    function setProtocolFeeAddress(
        address value
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            value != address(0),
            "setFeeAddress: fee address connot be address zero"
        );
        address oldProtocolFeeAddress = protocolFeeAddress;
        protocolFeeAddress = value;
        emit ProtocolFeeAddressUpdate(
            oldProtocolFeeAddress,
            protocolFeeAddress
        );
    }

    /// @notice Set the fee token address
    /// @dev only an admin address address can call this function. Emits FeeTokenAddressUpdate event
    /// @param value the fee token address
    function setFeeTokenAddress(
        address value
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            value != address(0),
            "setFeeTokenAddress: fee token address connot be address zero"
        );
        address oldFeeTokenAddress = feeTokenAddress;
        feeTokenAddress = value;
        emit FeeTokenAddressUpdate(oldFeeTokenAddress, feeTokenAddress);
    }

    /// @notice Set the T&C url
    /// @dev only granted address can call this function. Emits TCUrlUpdated event
    /// @param url the T&C url
    function setTcURL(
        string memory url
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory oldUrl = tcUrl;
        tcUrl = url;
        emit TCUrlUpdate(oldUrl, tcUrl);
    }
}
