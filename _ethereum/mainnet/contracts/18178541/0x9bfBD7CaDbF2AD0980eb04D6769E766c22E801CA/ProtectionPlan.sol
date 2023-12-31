// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ECDSAUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IProtocolRegistry.sol";
import "./IProtectionPlan.sol";

/**
 * @dev This struct is used to pass the parameters to the panic function
 *
 * @param tokenAddresses address[] array of token addresses
 * @param tokenIds uint256[] array of token ids
 * @param tokenAmounts uint256[] array of token amounts
 * @param tokenTypes string[] array of token types
 * @param approvedWallets address[] array of approved wallets
 * @param approvalIds uint256[] array of approval ids
 * @param backUpWallet address of the backup wallet
 * @param uid string of the user id
 *
 */
struct PanicParams {
    address[] tokenAddresses;
    uint256[] tokenIds;
    uint256[] tokenAmounts;
    string[] tokenTypes;
    address backUpWallet;
}

struct CryptoWillParams {
    address[] _erc721Contracts;
    address[][] _erc721Beneficiaries;
    uint256[][] _erc721TokenIds;
    address[] _erc1155Contracts;
    address[][] _erc1155Beneficiaries;
    uint256[][] _erc1155TokenIds;
    uint256[][] _erc1155Amounts;
    address[] _erc20Contracts;
    address[][] _erc20Beneficiaries;
    uint256[][] _erc20Amounts;
}

contract ProtectionPlan is IProtectionPlan, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // @notice address for string member address
    address public member;

    // @notice variable to store ipfsHash of Member
    string public ipfsHash;

    // @notice variable to store related wallets
    mapping(address => bool) public relatedWallets;

    // @notice keep track of burned nonces
    mapping(address => mapping(uint256 => bool)) private _nonces;

    IProtocolRegistry public protocolRegistry;

    // @notice to store beneficiaries of Member
    mapping(address => bool) public beneficiaries;

    // contract => token id => beneficiary
    mapping(address => mapping(uint256 => address)) public erc721Registry;
    // contract => token id => beneficiary => amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) public erc1155Registry;
    // contract => beneficiary => amount
    mapping(address => mapping(address => uint256)) public erc20Registry;

    bool public inheritable;

    /**
     * @notice Event for Querying Approvals
     *
     * @param approvedWallet address of the wallet owning the asset
     * @param tokenId uint256 tokenId of asset being backed up
     * @param tokenAddress address contract of the asset being protectd
     * @param tokenType string i.e. ERC20 | ERC1155 | ERC721
     * @param tokensAllocated uint256 number of tokens to be protected
     * @param success whether the transfer was successful or not
     * @param claimedWallet address of receipient of assets
     *
     * @dev We ommited the backupWallets array and the dateApproved fields here
     * is that ok?
     */
    event PanicApprovalsEvent(
        address approvedWallet,
        uint256 tokenId,
        address tokenAddress,
        string tokenType,
        uint256 tokensAllocated,
        bool success,
        address claimedWallet,
        uint256 datePanicked
    );

    /**
     * @notice this event is emitted when a related wallet is added
     * @param member wallet address of member
     * @param relatedWallet wallet address of related wallet
     * @param approved whether the member is related or not
     */
    event RelatedWalletEvent(address member, address relatedWallet, bool approved);

    event BeneficiaryEvent(address member, address beneficiaryAddress, bool isBeneficiary);

    event InheritableERC721Set(address member, address erc721Contract, address beneficiary, uint256 tokenId);

    event InheritableERC1155Set(
        address member, address erc1155Contract, address beneficiary, uint256 tokenId, uint256 amount
    );

    event InheritableERC20Set(address member, address erc20Contract, address beneficiary, uint256 amount);



    /**
     * @notice Event for CryptoWill 
     *
     * @param tokenId uint256 tokenId of asset being backed up
     * @param tokenAddress address contract of the asset being protectd
     * @param tokenType string i.e. ERC20 | ERC1155 | ERC721
     * @param tokensAllocated uint256 number of tokens to be protected
     * @param success whether the transfer was successful or not
     * @param inheritedWallet address of receipient of assets
     *
     */
    event CryptoWillInheritEvent(
        uint256 tokenId,
        address tokenAddress,
        string tokenType,
        uint256 tokensAllocated,
        bool success,
        address inheritedWallet,
        uint256 dateInherited
    );

    event MemberInheritable(
        address member,
        bool inheritable
    );

    /**
     * @notice This initializer sets up the constructor and initial relayer address
     * @param _member parameter to pass in the member on initializing
     */
    function initialize(address _member, address _protocolDirectoryAddr) public initializer {
        require(_member != address(0), "Error: Member cannot be 0x");
        require(_protocolDirectoryAddr != address(0), "Error: Registry cannot be 0x");
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
        member = _member;
        protocolRegistry = IProtocolRegistry(_protocolDirectoryAddr);
        inheritable = false;
    }

    // @notice Modifier to limit access to onlyRelayer
    modifier onlyRelayer() {
        require(msg.sender == protocolRegistry.getRelayerAddress(), "Error: Only relayer can invoke");
        _;
    }

    // @notice Modifier to limit access to onlyMember invoked by member
    modifier onlyMember() {
        require(msg.sender == member, "Error: Only member can invoke");
        _;
    }

    /**
     * @notice This modifier limits access to only related wallets, owner of the contract to execute functions
     */
    modifier onlyAuthorizedUsers() {
        bool found = false;
        // Check in relatedWallets

        if (relatedWallets[msg.sender] == true) {
            found = true;
        }

        // If not found in relatedWallets, check in member
        if (!found) {
            if (msg.sender == member) {
                found = true;
            }
        }

        // If not found in either, revert the transaction
        if (!found) {
            revert UserNotAuthorized();
        }
        _;
    }

    /**
     * @notice Validates whether a message has been signed by correct signer
     */
    modifier isValidSignature(uint256 _nonce, uint256 _deadline, bytes memory _signature) {
        address signer = protocolRegistry.getSignerAddress();
        if (signer == address(0)) revert SignerAddressZero();
        bytes32 messageHash = keccak256(abi.encode(msg.sender, _nonce, _deadline)).toEthSignedMessageHash();
        if (!SignatureCheckerUpgradeable.isValidSignatureNow(signer, messageHash, _signature)) {
            revert InvalidSignature();
        }
        if (_nonces[msg.sender][_nonce]) revert NonceAlreadyUsed();
        if (block.timestamp > _deadline) revert DeadlineExceeded();
        _nonces[msg.sender][_nonce] = true;
        _;
    }

    /**
     * @notice Modifier to limit access to only beneficiaries
     */
    modifier onlyBeneficiary() {
        require(beneficiaries[msg.sender], "Error: Only beneficiaries can invoke this function");
        _;
    }

    /**
     * @notice setRelatedWallets sets related wallets of a user
     * @param _wallets contains related wallets or users wallets that can be backups or normal wallets
     * @param _approvals contains whether the wallet is related or not
     * @param _nonce unique nonce for transaction
     * @param _deadline the transaction deadline
     * @param _signature used to validate the transaction
     */
    function setRelatedWallets(
        address[] calldata _wallets,
        bool[] calldata _approvals,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    ) external onlyMember isValidSignature(_nonce, _deadline, _signature) {
        if (_wallets.length != _approvals.length) {
            revert WalletsApprovalsLengthMismatch();
        }
        for (uint256 i = 0; i < _wallets.length;) {
            relatedWallets[_wallets[i]] = _approvals[i];
            emit RelatedWalletEvent(member, _wallets[i], _approvals[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Allows to update member IPFS CID information onChain to a unique UID passed.
     * @dev setIPFSHash
     * @param _ipfsHash ipfs Hash of the new user information
     * @param _nonce unique nonce for transaction
     * @param _deadline the transaction deadline
     * @param _signature used to validate the transaction
     *
     */
    function setIPFSHash(string calldata _ipfsHash, uint256 _nonce, uint256 _deadline, bytes memory _signature)
        public
        onlyMember
        isValidSignature(_nonce, _deadline, _signature)
    {
        ipfsHash = _ipfsHash;
    }

    /**
     * @notice Panic used by related wallets to transfer assets from the policy holder.
     * @param params panic params struct
     */
    function panic(PanicParams calldata params) public onlyAuthorizedUsers {
        if (bytes(ipfsHash).length == 0) {
            revert IPFSDoesNotExist();
        }

        //check if approvals exist for the token
        for (uint256 i = 0; i < params.tokenAddresses.length; i++) {
            bool success = false;
            if (keccak256(abi.encodePacked((params.tokenTypes[i]))) == keccak256(abi.encodePacked(("ERC20")))) {
                success = _transferERC20(params.tokenAddresses[i], params.backUpWallet, 0);
            } else if (keccak256(abi.encodePacked((params.tokenTypes[i]))) == keccak256(abi.encodePacked(("ERC721")))) {
                success = _transferERC721(params.tokenAddresses[i], params.backUpWallet, params.tokenIds[i]);
            } else if (keccak256(abi.encodePacked((params.tokenTypes[i]))) == keccak256(abi.encodePacked(("ERC1155"))))
            {
                success = _transfer1155(params.tokenAddresses[i], params.backUpWallet, params.tokenIds[i], 0);
            } else {
                success = false;
            }
            emit PanicApprovalsEvent(
                member,
                params.tokenIds[i],
                params.tokenAddresses[i],
                params.tokenTypes[i],
                params.tokenAmounts[i],
                success,
                params.backUpWallet,
                block.timestamp
            );
        }
    }

    /**
     * @notice - Sets beneficiaries for the member with signature validation
     * @param _beneficiaryWallets - beneficiary wallets of the user that needs to be set as beneficiaries
     * @param _isBeneficiary - booleans to control if the user is a beneficiary or not
     * @param _nonce unique nonce for transaction
     * @param _deadline the transaction deadline
     * @param _signature used to validate the transaction
     */
    function setBeneficiaries(
        address[] calldata _beneficiaryWallets,
        bool[] calldata _isBeneficiary,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    ) external isValidSignature(_nonce, _deadline, _signature) {
        if (_beneficiaryWallets.length != _isBeneficiary.length) {
            revert BeneficiaryWalletsLengthMismatch();
        }
        for (uint256 i = 0; i < _beneficiaryWallets.length;) {
            beneficiaries[_beneficiaryWallets[i]] = _isBeneficiary[i];
            emit BeneficiaryEvent(member, _beneficiaryWallets[i], _isBeneficiary[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Add beneficiaries for ERC721 tokens
     * @dev address(0) as a beneficiary is equivalent to removal
     * @param _contract the ERC721 contract
     * @param _tokenIds the tokens of the ERC721 contract
     * @param _beneficiaries the beneficiaries for the tokens
     */
    function _setInheritableERC721(address _contract, uint256[] calldata _tokenIds, address[] calldata _beneficiaries)
        internal
    {
        if (_tokenIds.length != _beneficiaries.length) {
            revert BeneficiaryWalletsLengthMismatch();
        }
        for (uint256 i = 0; i < _tokenIds.length;) {
            if (!IERC721(_contract).isApprovedForAll(member, address(this))) {
                revert WillNotApproved();
            }
            if (IERC721(_contract).ownerOf(_tokenIds[i]) != member) {
                revert InvalidAssetOwner();
            }
            if (!beneficiaries[_beneficiaries[i]]) revert InvalidBeneficiary();
            erc721Registry[_contract][_tokenIds[i]] = _beneficiaries[i];
            emit InheritableERC721Set(member, _contract, _beneficiaries[i], _tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Add beneficiaries for ERC1155 tokens
     * @dev address(0) as a beneficiary is equivalent to removal
     * @param _contract the ERC1155 contract
     * @param _tokenIds the tokens of the ERC1155 contract
     * @param _beneficiaries the beneficiaries for the tokens
     * @param _amounts the amount of tokens for a beneficiary to inherit
     */
    function _setInheritableERC1155(
        address _contract,
        uint256[] calldata _tokenIds,
        address[] calldata _beneficiaries,
        uint256[] calldata _amounts
    ) internal {
        if (_tokenIds.length != _beneficiaries.length || _tokenIds.length != _amounts.length) {
            revert BeneficiaryWalletsLengthMismatch();
        }
        for (uint256 i = 0; i < _tokenIds.length;) {
            if (!IERC1155(_contract).isApprovedForAll(member, address(this))) {
                revert WillNotApproved();
            }
            if (IERC1155(_contract).balanceOf(member, _tokenIds[i]) == 0) {
                revert InvalidAssetOwner();
            }
            if (!beneficiaries[_beneficiaries[i]]) revert InvalidBeneficiary();
            erc1155Registry[_contract][_tokenIds[i]][_beneficiaries[i]] = _amounts[i];
            emit InheritableERC1155Set(member, _contract, _beneficiaries[i], _tokenIds[i], _amounts[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Add beneficiaries for ERC20 tokens
     * @dev address(0) as a beneficiary is equivalent to removal
     * @param _contract the ERC20 contract
     * @param _beneficiaries the beneficiaries for the tokens
     * @param _amounts the amount of tokens for a beneficiary to inherit
     */
    function _setInheritableERC20(address _contract, address[] calldata _beneficiaries, uint256[] calldata _amounts)
        internal
    {
        if (_beneficiaries.length != _amounts.length) {
            revert BeneficiaryWalletsLengthMismatch();
        }
        uint256 allowance = IERC20(_contract).allowance(member, address(this));
        uint256 inheritedAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length;) {
            inheritedAmount += _amounts[i];
            if (inheritedAmount > allowance) revert InsufficientAllowance();
            if (IERC20(_contract).balanceOf(member) < inheritedAmount) {
                revert InvalidAssetOwner();
            }
            if (!beneficiaries[_beneficiaries[i]]) revert InvalidBeneficiary();
            erc20Registry[_contract][_beneficiaries[i]] = _amounts[i];
            emit InheritableERC20Set(member, _contract, _beneficiaries[i], _amounts[i]);
            unchecked {
                i++;
            }
        }
    }

    function setInheritableRegistryAndSetIPFSHash(CryptoWillParams calldata _cryptoWillParams,string calldata _ipfsHash, uint256 _nonce, uint256 _deadline, bytes memory _signature ) external onlyMember {
        setIPFSHash(_ipfsHash, _nonce, _deadline, _signature);
        setInheritableRegistry(_cryptoWillParams);
    }

    /**
     * @notice Set multiple inheritable assets
     * @param _cryptoWillParams structure of cryptoWill data
     */
    function setInheritableRegistry(CryptoWillParams calldata _cryptoWillParams) public onlyMember {
        uint256 i = 0;
        for (i; i < _cryptoWillParams._erc721Contracts.length;) {
            _setInheritableERC721(
                _cryptoWillParams._erc721Contracts[i],
                _cryptoWillParams._erc721TokenIds[i],
                _cryptoWillParams._erc721Beneficiaries[i]
            );
            unchecked {
                i++;
            }
        }
        i = 0;
        for (i; i < _cryptoWillParams._erc1155Contracts.length;) {
            _setInheritableERC1155(
                _cryptoWillParams._erc1155Contracts[i],
                _cryptoWillParams._erc1155TokenIds[i],
                _cryptoWillParams._erc1155Beneficiaries[i],
                _cryptoWillParams._erc1155Amounts[i]
            );
            unchecked {
                i++;
            }
        }
        i = 0;
        for (i; i < _cryptoWillParams._erc20Contracts.length;) {
            _setInheritableERC20(
                _cryptoWillParams._erc20Contracts[i],
                _cryptoWillParams._erc20Beneficiaries[i],
                _cryptoWillParams._erc20Amounts[i]
            );
            unchecked {
                i++;
            }
        }
    }

    function inherit(CryptoWillParams calldata _cryptoWillParams) public onlyBeneficiary {
        require(inheritable == true, "Error: Cryptowill not active");

        // Transfer ERC721 tokens
        for (uint256 i = 0; i < _cryptoWillParams._erc721Contracts.length;) {
            address contractAddress = _cryptoWillParams._erc721Contracts[i];
            uint256[] calldata tokenIds = _cryptoWillParams._erc721TokenIds[i];
            address[] calldata _beneficiaries = _cryptoWillParams._erc721Beneficiaries[i];

            for (uint256 j = 0; j < tokenIds.length;) {
                bool success = false;
                uint256 tokenId = tokenIds[j];
                address beneficiary = _beneficiaries[j];

                if (beneficiaries[beneficiary] == false) {
                    revert InvalidBeneficiary();
                }

                if (erc721Registry[contractAddress][tokenId] == beneficiary) {
                    success = _transferERC721(contractAddress, beneficiary, tokenId);
                }
                 emit CryptoWillInheritEvent(tokenId, contractAddress, "ERC721", 1, success, beneficiary, block.timestamp);
                unchecked {
                    j++;
                }
               
            }
            unchecked {
                i++;
            }
        }

        // Transfer ERC1155 tokens
        for (uint256 i = 0; i < _cryptoWillParams._erc1155Contracts.length;) {
            address contractAddress = _cryptoWillParams._erc1155Contracts[i];
            uint256[] calldata tokenIds = _cryptoWillParams._erc1155TokenIds[i];
            address[] calldata _beneficiaries = _cryptoWillParams._erc1155Beneficiaries[i];
            uint256[] calldata amounts = _cryptoWillParams._erc1155Amounts[i];

            for (uint256 j = 0; j < tokenIds.length;) {
                bool success = false;
                uint256 tokenId = tokenIds[j];
                address beneficiary = _beneficiaries[j];
                uint256 amount = amounts[j];

                if (beneficiaries[beneficiary] == false) {
                    revert InvalidBeneficiary();
                }

                if (erc1155Registry[contractAddress][tokenId][beneficiary] >= amount) {
                    success = _transfer1155(contractAddress, beneficiary, tokenId, amount);
                }
               emit CryptoWillInheritEvent(tokenId, contractAddress, "ERC1155", amount, success, beneficiary, block.timestamp);
                unchecked {
                    j++;
                }

            }
            unchecked {
                i++;
            }
        }

        // Transfer ERC20 tokens
        for (uint256 i = 0; i < _cryptoWillParams._erc20Contracts.length;) {
            address contractAddress = _cryptoWillParams._erc20Contracts[i];
            address[] calldata _beneficiaries = _cryptoWillParams._erc20Beneficiaries[i];
            uint256[] calldata amounts = _cryptoWillParams._erc20Amounts[i];

            for (uint256 j = 0; j < _beneficiaries.length;) {
                bool success = false;
                address beneficiary = _beneficiaries[j];
                uint256 amount = amounts[j];

                if (beneficiaries[beneficiary] == false) {
                    revert InvalidBeneficiary();
                }

                if (erc20Registry[contractAddress][beneficiary] >= amount) {
                    success = _transferERC20(contractAddress, beneficiary, amount);
                }
                 emit CryptoWillInheritEvent(0, contractAddress, "ERC20", amount, success, beneficiary, block.timestamp);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Get the beneficiary for an ERC721
     * @param _contract the ERC721 contract
     * @param _tokenId the ERC721 token
     * @return the beneficiary address
     */
    function getERC721Beneficiary(address _contract, uint256 _tokenId) public view returns (address) {
        return erc721Registry[_contract][_tokenId];
    }

    /**
     * @notice Get the token amount for a beneficiary of an ERC1155
     * @param _contract the ERC1155 contract
     * @param _tokenId the ERC1155 token
     * @param _beneficiary the beneficiary address
     * @return the amount of the ERC1155 token for the beneficiary
     */
    function getERC1155BeneficiaryAmount(address _contract, uint256 _tokenId, address _beneficiary)
        public
        view
        returns (uint256)
    {
        return erc1155Registry[_contract][_tokenId][_beneficiary];
    }

    /**
     * @notice Get the token amount for a beneficiary of an ERC20
     * @param _contract the ERC20 contract
     * @param _beneficiary the beneficiary address
     * @return the amount of the ERC20 token for the beneficiary
     */
    function getERC20BeneficiaryAmount(address _contract, address _beneficiary) public view returns (uint256) {
        return erc20Registry[_contract][_beneficiary];
    }

    /**
     * @dev transfers an amount of ERC20 to a recipient and the webacy vault
     *      if the amount param is zero, it attempts to transfer the entire balance
     * @param contractAddress the ERC20 contract
     * @param recipient the transfer to address
     * @param amount the tokens to transfer, if zero then this will transfer the balanceOf instead
     */
    function _transferERC20(address contractAddress, address recipient, uint256 amount) private returns (bool) {
        IERC20 erc20 = IERC20(contractAddress);

        uint256 tokenBalance = erc20.balanceOf(member);
        uint256 allowance = erc20.allowance(member, address(this));

        if (tokenBalance > 0) {
            uint256 transferAmount;
            if (amount > 0 && amount <= tokenBalance && amount <= allowance) {
                transferAmount = amount;
            } else if (tokenBalance <= allowance) {
                transferAmount = tokenBalance;
            } else {
                transferAmount = allowance;
            }

            uint256 webacyFees = transferAmount / 100;
            if (webacyFees > 0) {
                (bool uSuccess,) = address(erc20).call(
                    abi.encodeWithSignature(
                        "transferFrom(address,address,uint256)", member, recipient, transferAmount - webacyFees
                    )
                );
                bool wSuccess;
                if (uSuccess) {
                    (wSuccess,) = address(erc20).call(
                        abi.encodeWithSignature(
                            "transferFrom(address,address,uint256)",
                            member,
                            protocolRegistry.getVaultAddress(),
                            webacyFees
                        )
                    );
                }
                return uSuccess && wSuccess;
            } else {
                (bool success,) = address(erc20).call(
                    abi.encodeWithSignature("transferFrom(address,address,uint256)", member, recipient, transferAmount)
                );
                return success;
            }
        }
        return false;
    }

    /**
     * @dev transfers an amount of ERC20 to a recipient and the webacy vault
     *      if the amount param is zero, it attempts to transfer the entire balance
     * @param contractAddress the ERC20 contract
     * @param recipient the transfer to address
     * @param tokenId the token to transfer
     */
    function _transferERC721(address contractAddress, address recipient, uint256 tokenId) private returns (bool) {
        (bool success,) = contractAddress.call(
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", member, recipient, tokenId)
        );
        return success;
    }

    /**
     * @dev transfers an amount of ERC20 to a recipient and the webacy vault
     *      if the amount param is zero, it attempts to transfer the entire balance of the tokenId
     * @param contractAddress the ERC20 contract
     * @param recipient the transfer to address
     * @param tokenId the token to transfer balance from
     * @param amount the amount to transfer for the tokenId, if zero then this will transfer the balanceOf instead
     */
    function _transfer1155(address contractAddress, address recipient, uint256 tokenId, uint256 amount)
        private
        returns (bool)
    {
        IERC1155 erc1155 = IERC1155(contractAddress);

        uint256 balance = erc1155.balanceOf(member, tokenId);
        uint256 transferAmount;
        if (balance > 0) {
            if (amount > 0 && amount <= balance) {
                transferAmount = amount;
            } else {
                transferAmount = balance;
            }

            (bool success,) = contractAddress.call(
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    member,
                    recipient,
                    tokenId,
                    transferAmount,
                    bytes("")
                )
            );
            return success;
        }
        return false;
    }


    function setInheritableStatus(bool _status) external onlyRelayer {
        inheritable = _status;
        emit MemberInheritable(member, inheritable);
    }
}
