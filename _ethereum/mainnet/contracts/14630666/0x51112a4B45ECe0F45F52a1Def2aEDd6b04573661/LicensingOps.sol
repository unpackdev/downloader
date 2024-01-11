// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./SignatureChecker.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./LicensingTokenI.sol";

/**
 * @title LicensingOps
 * @dev This contract allows minting licenses for other ERC721 collections.
 * Users can pay to mint tokens when not paused.
 */
contract LicensingOps is Pausable, AccessControl, EIP712 {
    using SignatureChecker for address;
    // Wallet who will be the backend signer
    address public signer;

    // Wallet to sign behalf of sellers.
    address public representationSigner;

    // Wallet who will receive the mint fees
    address public receiver;

    // License Token Interface
    LicensingTokenI public licensingToken;

    // List of supported collections
    mapping(address => bool) public licensorContracts;

    // List of already used signatures
    mapping(bytes => bool) private invalidSignatures;

    // Event fired when the payments are made
    event SellerFundsTransferred(address _wallet, uint256 _amount);

    // Event fired when the fee payments are made
    event FeeFundsTransferred(address _wallet, uint256 _amount);

    /**
     * @dev Creates an instance of `LicensingOps`.
     *
     * 'msg.sender' gets the Admin role.
     * 'msg.sender' sets the Signer Wallet that will receive funds.
     * '_licensingTokenAddress' is the address of the License Token smart contract.
     */
    constructor(
        string memory name,
        string memory version,
        address _licensingTokenAddress
    ) EIP712(name, version) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        licensingToken = LicensingTokenI(_licensingTokenAddress);
        signer = msg.sender;
    }

    /**
     * @dev It creates a new License token in a collection.
     * It calls 'safeMint' from the LicenseToken contract.
     * Checks if the collection is supported.
     * Checks if properties match the signatures for seller and admin.
     * Invalidate the used signatures.
     * @param _licenseProps License properties
     */
    function mint(LicenseProps calldata _licenseProps) external payable whenNotPaused {
        require(
            invalidSignatures[_licenseProps.adminSignature] == false,
            "LOPS: Invalid signature"
        );
        invalidSignatures[_licenseProps.adminSignature] = true;

        require(
            licensorContracts[_licenseProps.tokenContractAddress] == true,
            "LOPS: Contract not available"
        );

        require(_licenseProps.approvedFee <= 10000, "LOPS: Fee is too high");

        require(_licenseProps.signatureTimeOut >= block.timestamp, "LOPS: Signature Expired");

        require(
            msg.value >= _licenseProps.licensePrice,
            "LOPS: The value needs to be greater than or equal to the license price"
        );

        verifySignatures(_licenseProps);

        licensingToken.safeMint(
            _licenseProps.approvedBuyer,
            _licenseProps.licenseType,
            block.timestamp + _licenseProps.licenseTerm,
            _licenseProps.exclusive,
            _licenseProps.tokenId,
            _licenseProps.tokenContractAddress,
            _licenseProps.tokenOwnerAddress,
            _licenseProps.databaseId
        );

        payment(_licenseProps.approvedFee, _licenseProps.tokenOwnerAddress);
    }

    /**
     * @dev It verifies if the signatures are valid.
     * Hash the License properties into sellers signature.
     * Create a instance of the collection address to check on-chain ownership.
     * Check if it's a transaction made by the admin or seller.
     * Check if the the token belongs to the correct wallet.
     * Check if admin signature is valid.
     * @param _licenseProps License properties
     */
    function verifySignatures(LicenseProps calldata _licenseProps) internal view {
        bytes32 licenseHash = hashLicenseSignature(
            _licenseProps.licenseType,
            _licenseProps.licenseTerm,
            _licenseProps.licensePrice,
            _licenseProps.exclusive,
            _licenseProps.tokenId,
            _licenseProps.tokenContractAddress,
            _licenseProps.tokenOwnerAddress
        );
        IERC721 licensorContract = IERC721(_licenseProps.tokenContractAddress);

        if (_licenseProps.sellerRepresentation == true) {
            address tokenOwner = licensorContract.ownerOf(_licenseProps.tokenId);
            require(_licenseProps.tokenOwnerAddress == tokenOwner, "LOPS: Token owner mismatch");
            require(
                representationSigner.isValidSignatureNow(
                    licenseHash,
                    _licenseProps.sellerSignature
                ),
                "LOPS: Invalid signature in a private mint"
            );
        } else {
            address tokenOwner = licensorContract.ownerOf(_licenseProps.tokenId);
            require(
                tokenOwner.isValidSignatureNow(licenseHash, _licenseProps.sellerSignature),
                "LOPS: Invalid seller signature"
            );
        }

        require(
            signer.isValidSignatureNow(
                hashAdminSignature(
                    _licenseProps.sellerSignature,
                    _licenseProps.signatureTimeOut,
                    _licenseProps.approvedBuyer,
                    _licenseProps.approvedFee
                ),
                _licenseProps.adminSignature
            ),
            "LOPS: Invalid admin signature"
        );
    }

    /**
     * @dev Split the payment between the receiver and seller.
     * Checks the Fee amount.
     * Calc Receiver Fee for this transaction.
     * Sends the funds to the receiver.
     * Sends the funds to the seller.
     * @param _sellerAddress Seller address
     */
    function payment(uint256 _approvedFee, address _sellerAddress) internal {
        uint256 amount = msg.value;
        bool success = false;

        if (_approvedFee != 0) {
            uint256 finalFee = (amount * _approvedFee) / 10000;
            (success, ) = receiver.call{value: finalFee}("");
            require(success, "LOPS: Fee transfer failed");
            emit FeeFundsTransferred(receiver, finalFee);
            amount = amount - finalFee;
        }

        (success, ) = _sellerAddress.call{value: amount}("");
        require(success, "LOPS: Seller payment failed");
        emit SellerFundsTransferred(_sellerAddress, amount);
    }

    /**
     * @dev Pause the License Ops Contract
            Only the admin role can pause the contract.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unause the License Ops Contract
            Only the admin role can unpause the contract.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Sets new signer address. Only Admin can call this function.
     *
     * @param _signer The account address to sign licenses requests
     */
    function updateSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    /**
     * @dev Sets new representation signer address. Only Admin can call this function.
     *
     * @param _address The account address to sign licenses behalf of users
     */
    function updateRepresentationSigner(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        representationSigner = _address;
    }

    /**
     * @dev Sets new receiver address. Only Admin can call this function.
     *
     * @param _receiver The account address to receive fees at mintings
     */
    function updateReceiver(address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        receiver = _receiver;
    }

    /**
     * @dev Create a hash of the admin signature with expiration time
     *
     * @param _sellerSignature the seller signature
     * @param _signatureTimeOut timestamp to expire this signature
     * @param _approvedBuyer address allowed to use this admin signature
     */
    function hashAdminSignature(
        bytes calldata _sellerSignature,
        uint256 _signatureTimeOut,
        address _approvedBuyer,
        uint256 _approvedFee
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Admin(bytes sellerSignature,uint256 signatureTimeOut,address approvedBuyer,uint256 approvedFee)"
                        ),
                        keccak256(bytes(_sellerSignature)),
                        _signatureTimeOut,
                        _approvedBuyer,
                        _approvedFee
                    )
                )
            );
    }

    /**
     * @dev Create a hash of the seller signature
     *
     * @param _licenseType type of the license
     * @param _licenseTerm timestamp to expire this license
     * @param _licensePrice the price of the license
     * @param _exclusive if the license is exclusive
     * @param _tokenId Licensor token id
     * @param _tokenContractAddress Licensor contract address
     * @param _tokenOwnerAddress License wallet address
     */
    function hashLicenseSignature(
        string calldata _licenseType,
        uint256 _licenseTerm,
        uint256 _licensePrice,
        bool _exclusive,
        uint256 _tokenId,
        address _tokenContractAddress,
        address _tokenOwnerAddress
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "License(string licenseType,uint256 licenseTerm,uint256 licensePrice,bool exclusive,address licensorContractAddress,uint256 licensorTokenId,address licensorWallet)"
                        ),
                        keccak256(bytes(_licenseType)),
                        _licenseTerm,
                        _licensePrice,
                        _exclusive,
                        _tokenContractAddress,
                        _tokenId,
                        _tokenOwnerAddress
                    )
                )
            );
    }

    /**
     * @dev Invalidates the signature of the given hash, only the admin role can call this function
     * If for any reason a signature needs to be invalidated
     */
    function invalidateSignature(bytes calldata _signature) external onlyRole(DEFAULT_ADMIN_ROLE) {
        invalidSignatures[_signature] = true;
    }

    /**
     * @dev Sets if an address is whitelisted or not, only admin can call this function
     * @param _licensorContractAddress Address to update in the whitelist
     * @param _value Use 'True' to whitelist '_licensorContractAddress', 'False' otherwise
     */
    function setLicensorContract(address _licensorContractAddress, bool _value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        licensorContracts[_licensorContractAddress] = _value;
    }

    /// @dev Updates the admin role of this contract
    function setAdminRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
    }
}
