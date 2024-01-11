// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721A.sol";
import "./Claimable.sol";

interface IERC721Aextends is IERC721A {
    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function safeMint(address to, uint256 quantity) external;
}

/**
 * @title Claim and Distribution Smart Contract
 * @dev Offer claim and distribution flows based on the ERC1155 and ERC721 standards.
 * @dev A payload signature is used to validate claimed tokens.
 * @custom:a The Cypherverse Ltd
 */
contract ClaimContractV3 is
    Initializable,
    Claimable,
    PausableUpgradeable,
    EIP712Upgradeable,
    AccessControlUpgradeable
{
    using AddressUpgradeable for address;
		using StringsUpgradeable for string;
    // Constant for Minter Role
    bytes32 public constant DISTRIBUTION_ROLE = keccak256("DISTRIBUTION_ROLE");
    // VoxoDeus Contract Address in Ethereum
    address public VOXODEUS_CONTRACT_ADDRESS;
    /**
     * @dev Mapping types are declared as mapping(_KeyType => _ValueType). Here _KeyType
     * @dev can be almost any type except for a mapping, a dynamically sized array, a contract
     * @dev an enum and a struct.
     */
    /**
     * @dev Mapping Unit256 -> String for collection name
     * @dev 0 - tsbvoxoentity
     * @dev 1 - herocards
     * @dev 2 - ...
     */
    mapping(uint256 => string) public collection;
    // Mapping per collection name and wallet to store the blocklist of users that have claimed their NFT allowance
    mapping(uint256 => mapping(address => bool)) public blocklistPerWallet;
    // Mapping per collection name and token ids store the blocklist of used qualifying tokens
    mapping(uint256 => mapping(uint256 => bool)) public blocklistPerVoxo;
    // Index collection
    uint256 public collectionLength;
    /**
     * @dev Event emitted for each ERC1155 token claimed by a VoxoDeus user
     * @param toAddress Address of the claimant
     * @param tokenIds Identifiers of the ERC1155 token the VoxoUser is allowed to claim
     * @param tokenQuantities Quantity of each ERC1155 token the VoxoUser is allowed to claim
     * @param qualifyingTokensIds which tokenIds are being used to qualify for the claimableTokens
     * @param tokenAddress Address of the ERC1155 token
     * @param collection Name of the ERC1155 token
     */
    event ClaimedPerVoxoERC1155(
        address indexed toAddress,
        uint256[] tokenIds,
        uint256[] tokenQuantities,
        uint256[] qualifyingTokensIds,
        address tokenAddress,
        string collection
    );
    /**
     * @dev Event emitted for each ERC1155 token claimed
     * @param toAddress Address of the claimant
     * @param tokenIds Identifiers of the ERC1155 token the VoxoUser is allowed to claim
     * @param tokenQuantities Quantity of each ERC1155 token the VoxoUser is allowed to claim
     * @param tokenAddress Address of the ERC1155 token
     * @param collection Name of the ERC1155 token
     */
    event ClaimedERC1155(
        address indexed toAddress,
        uint256[] tokenIds,
        uint256[] tokenQuantities,
        address tokenAddress,
        string collection
    );
    /**
     * @dev  Event emitted for each ERC721 token claimed by a VoxoDeus user
     * @param toAddress Address of the claimant
     * @param tokenIds Identifiers of the ERC721 token the VoxoUser is allowed to claim
     * @param qualifyingTokensIds which tokenIds are being used to qualify for the claimableTokens
     * @param tokenAddress Address of the ERC721 token
     * @param collection Name of the ERC721 token
     */
    event ClaimedPerVoxoERC721(
        address indexed toAddress,
        uint256[] tokenIds,
        uint256[] qualifyingTokensIds,
        address tokenAddress,
        string collection
    );
    /**
     * @dev Event emitted for each ERC721 token claimed
     * @param toAddress Address of the claimant
     * @param tokenIds Identifiers of the ERC721 token the VoxoUser is allowed to claim
     * @param tokenAddress Address of the ERC721 token
     * @param collection Name of the ERC721 token
     */
    event ClaimedERC721(
        address indexed toAddress,
        uint256[] tokenIds,
        address tokenAddress,
        string collection
    );

    function initialize(
        address _distributionRoleAddress,
        address _verifyingContract,
        address _voxoSmartContract
    ) public initializer {
        __Ownable_init();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DISTRIBUTION_ROLE, _distributionRoleAddress);
        __EIP712_init("TheCypherverse", "1.0.0", _verifyingContract);
        VOXODEUS_CONTRACT_ADDRESS = _voxoSmartContract;
        // Create a mapping for the known collections
        setCollection("tsbvoxoentity");
        setCollection("herocards");
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC20.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC20Pausable}.
     */
    function pause(bool status) public onlyOwner {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Function for Claim NFT ERC1155 Token based on payload signed, and filter Collection and Wallet
     * @dev permitted to claim NFT ERC1155 Token based signed by the Distribution Wallet
     * @dev Explanation of this method:
     * @dev Claimants qualify by virtue of their claimableTokenIds & claimableQuantities allowances.
     * @dev Replay protection is offered by adding the claimant's address to the blocklist.
     * @dev They can thus only make a single claim, and must claim their full allowance at once.
     * @param signature Signature of the payload
     * @param toAddress Wallet allowed to claim the ERC1155 NFT token
     * @param claimableTokenIds Ids allowed to claim the ERC1155 NFT token
     * @param claimableQuantities Amount allowed to claim the ERC1155 NFT token
     * @param deadline timestamp of deadline to claim
     * @param tokenAddress Token Address permit to claim the NFT ERC1155 Token
		 * @param _collectionName Name of Collection the ERC1155 token
     */
    function claimERC1155(
        bytes memory signature,
        address toAddress,
        uint256[] calldata claimableTokenIds,
        uint256[] calldata claimableQuantities,
        uint256 deadline,
        address tokenAddress,
        string memory _collectionName
    ) external whenNotPaused {
        uint256 collectionName = getIndexCollection(_collectionName);
				require(tokenAddress.isContract(), "VoxoDeus: Invalid Token Address");
        require(
            block.timestamp < deadline,
            "VoxoDeus: Expired Claim Permission"
        );
        require(
            toAddress == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );
        require(
            !madePriorClaim(collectionName, _msgSender()),
            "VoxoDeus: Account has a prior claim for this collection - only 1 permitted"
        );
        uint256[] memory qt;
        bytes32 message = createClaimMessageERC1155(
            toAddress,
            _hashArray(claimableTokenIds),
            _hashArray(claimableQuantities),
            _hashArray(qt),
            tokenAddress,
            collection[collectionName]
        );
        address signer = validateMessageSignature(message, signature);

        require(signer != address(0), "VoxoDeus: INVALID_SIGNATURE");
        require(
            hasRole(DISTRIBUTION_ROLE, signer),
            "VoxoDeus: Mismatch between requested and permitted tokens"
        );
        IERC1155Upgradeable token = IERC1155Upgradeable(tokenAddress);
        token.safeBatchTransferFrom(
            signer,
            toAddress,
            claimableTokenIds,
            claimableQuantities,
            ""
        );
        blocklistPerWallet[collectionName][_msgSender()] = true;
        emit ClaimedERC1155(
            toAddress,
            claimableTokenIds,
            claimableQuantities,
            tokenAddress,
            collection[collectionName]
        );
    }

    /**
     * @dev Claim ERC1155 Tokens based on a another set of qualifying tokens
     * @dev Explanation of this method:
     * @dev Claimants qualify by virtue of their VoxoDeus ownership. Replay protection is offered by
     * @dev adding VoxoDeus tokenIds to a blocklist. The corresponding claimableTokenId can thus
     * @dev only be claimed once for a VoxoDeus tokenID, but a user may spread their allowance
     * @dev across several claims, as long as they have at least one VoxoDeus Id not previously
     * @dev claimed for per claim.
     * @param signature Signature of the payload
     * @param toAddress Wallet allowed to claim the ERC1155 NFT token
     * @param claimableTokenIds Ids allowed to claim the ERC1155 NFT token
     * @param claimableQuantities Amount allowed to claim the ERC1155 NFT token
     * @param qualifyingTokensIds which tokenIds are being used to qualify for the, i.e. which Voxo Ids are used to qualify for the claimableTokens
     * @param deadline timestamp of deadline to claim
     * @param tokenAddress Token Address permit to claim the NFT ERC1155 Token
		 * @param _collectionName Name of Collection the ERC1155 token
     */
    function claimPerVoxoERC1155(
        bytes memory signature,
        address toAddress,
        uint256[] calldata claimableTokenIds,
        uint256[] calldata claimableQuantities,
        uint256[] calldata qualifyingTokensIds,
        uint256 deadline,
        address tokenAddress,
        string memory _collectionName
    ) external whenNotPaused {
				require(tokenAddress.isContract(), "VoxoDeus: Invalid Token Address");
        require(
            block.timestamp < deadline,
            "VoxoDeus: Expired Claim Permission"
        );
        require(
            toAddress == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );
        require(
            !hasPriorClaim(
                getIndexCollection(_collectionName),
                qualifyingTokensIds
            ),
            "VoxoDeus: At least one qualifying token has already been used in a prior claim"
        );
        // Check if wallet has ownership of the qualifying Voxos
        if ((qualifyingTokensIds.length > 0) && (qualifyingTokensIds[0] != 0)) {
            require(
                voxoOwnership(qualifyingTokensIds, voxoTokenHoldings(toAddress)),
                "VoxoDeus: At least one qualifying token is not currently owned by the claimant"
            );
        }

        bytes32 message = createClaimMessageERC1155(
            toAddress,
            _hashArray(claimableTokenIds),
            _hashArray(claimableQuantities),
            _hashArray(qualifyingTokensIds),
            tokenAddress,
            collection[getIndexCollection(_collectionName)]
        );
        address signer = validateMessageSignature(message, signature);

        require(signer != address(0), "VoxoDeus: INVALID_SIGNATURE");
        require(
            hasRole(DISTRIBUTION_ROLE, signer),
            "VoxoDeus: Mismatch between requested and permitted tokens"
        );
        IERC1155Upgradeable token = IERC1155Upgradeable(tokenAddress);
        token.safeBatchTransferFrom(
            signer,
            toAddress,
            claimableTokenIds,
            claimableQuantities,
            ""
        );
        // Helper to add list of tokenIds used to claim
        addBlocklistPerVoxo(
            qualifyingTokensIds,
            getIndexCollection(_collectionName)
        );
        emit ClaimedPerVoxoERC1155(
            toAddress,
            claimableTokenIds,
            claimableQuantities,
            qualifyingTokensIds,
            tokenAddress,
            collection[getIndexCollection(_collectionName)]
        );
    }

    /**
     * @dev Function for Claim NFT ERC721 Token based on payload signed, and filter Collection and Wallet
     * @dev permitted to claim NFT ERC721 Token based signed by the Distribution Wallet
     * @param signature Signature of the payload
     * @param toAddress Wallet allowed to claim the ERC721 NFT token
     * @param claimableTokenIds Ids allowed to claim the ERC721 NFT token
     * @param deadline timestamp of deadline to claim
     * @param tokenAddress Token Address permit to claim the NFT ERC721 Token
		 * @param _collectionName Name of Collection the ERC721 token
     */
    function claimERC721(
        bytes memory signature,
        address toAddress,
        uint256[] calldata claimableTokenIds,
        uint256 deadline,
        address tokenAddress,
        string memory _collectionName
    ) external whenNotPaused {
        uint256 collectionName = getIndexCollection(_collectionName);
				require(tokenAddress.isContract(), "VoxoDeus: Invalid Token Address");
        require(
            block.timestamp < deadline,
            "VoxoDeus: Expired Claim Permission"
        );
        require(
            toAddress == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );
        require(
            !madePriorClaim(collectionName, _msgSender()),
            "VoxoDeus: Account has a prior claim for this collection - only 1 permitted"
        );
        uint256[] memory qt;
        bytes32 message = createClaimMessageERC721(
            toAddress,
            _hashArray(claimableTokenIds),
            _hashArray(qt),
            tokenAddress,
            collection[collectionName]
        );
        address signer = validateMessageSignature(message, signature);

        require(signer != address(0), "VoxoDeus: INVALID_SIGNATURE");
        require(
            hasRole(DISTRIBUTION_ROLE, signer),
            "VoxoDeus: Mismatch between requested and permitted tokens"
        );
        IERC721Upgradeable token = IERC721Upgradeable(tokenAddress);
        for (uint256 i = 0; i < claimableTokenIds.length; i++) {
            token.safeTransferFrom(signer, toAddress, claimableTokenIds[i], "");
        }
        blocklistPerWallet[collectionName][_msgSender()] = true;
        emit ClaimedERC721(
            toAddress,
            claimableTokenIds,
            tokenAddress,
            collection[collectionName]
        );
    }

    /**
     * @dev Function for Claim NFT ERC721 Token based on payload signed, and filter Collection and VoxoId
     * @dev permitted to claim NFT ERC721 Token based signed by the Distribution Wallet
     * @param signature Signature of the payload
     * @param toAddress Wallet allowed to claim the ERC721 NFT token
     * @param claimableTokenIds Ids allowed to claim the ERC721 NFT token
     * @param qualifyingTokensIds which tokenIds are being used to qualify for the, i.e. which Voxo Ids are used to qualify for the claimableTokens
     * @param deadline timestamp of deadline to claim
     * @param tokenAddress Token Address permit to claim the NFT ERC721 Token
	    * @param _collectionName Name of Collection the ERC721 token
     */
    function claimPerVoxoERC721(
        bytes memory signature,
        address toAddress,
        uint256[] calldata claimableTokenIds,
        uint256[] calldata qualifyingTokensIds,
        uint256 deadline,
        address tokenAddress,
        string memory _collectionName
    ) external whenNotPaused {
        uint256 collectionName = getIndexCollection(_collectionName);
				require(tokenAddress.isContract(), "VoxoDeus: Invalid Token Address");
        require(
            block.timestamp < deadline,
            "VoxoDeus: Expired Claim Permission"
        );
        require(
            toAddress == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );
        require(
            !hasPriorClaim(collectionName, qualifyingTokensIds),
            "VoxoDeus: At least one qualifying token has already been used in a prior claim"
        );
        // Check if the wallet have the ownership of the Voxo Token Ids, in case send a valid array of Voxo TokenIds
        if ((qualifyingTokensIds.length > 0) && (qualifyingTokensIds[0] != 0)) {
            require(
                voxoOwnership(qualifyingTokensIds, voxoTokenHoldings(toAddress)),
                "VoxoDeus: At least one qualifying token is not currently owned by the claimant"
            );
        }

        bytes32 message = createClaimMessageERC721(
            toAddress,
            _hashArray(claimableTokenIds),
            _hashArray(qualifyingTokensIds),
            tokenAddress,
            collection[collectionName]
        );
        address signer = validateMessageSignature(message, signature);

        require(signer != address(0), "VoxoDeus: INVALID_SIGNATURE");
        require(
            hasRole(DISTRIBUTION_ROLE, signer),
            "VoxoDeus: Mismatch between requested and permitted tokens"
        );
        IERC721Upgradeable token = IERC721Upgradeable(tokenAddress);
        for (uint256 i = 0; i < claimableTokenIds.length; i++) {
            token.safeTransferFrom(signer, toAddress, claimableTokenIds[i], "");
        }
        addBlocklistPerVoxo(qualifyingTokensIds, collectionName);
        emit ClaimedPerVoxoERC721(
            toAddress,
            claimableTokenIds,
            qualifyingTokensIds,
            tokenAddress,
            collection[collectionName]
        );
    }

    /** Special Case of Herocards */
    /**
     * @dev Function for Claim/Mint NFT ERC721 Token based on payload signed, and filter Collection and VoxoId
     * @dev permitted to Mint NFT ERC721 Token based signed by the Distribution Wallet, and Amount Specified
     * @param signature Signature of the payload
     * @param toAddress Wallet allowed to claim the ERC721 NFT token
     * @param quantityTokens Ids allowed to claim the ERC721 NFT token
     * @param qualifyingTokensIds which tokenIds are being used to qualify for the, i.e. which Voxo Ids are used to qualify for the define quantityTokens
     * @param deadline timestamp of deadline to claim
     * @param tokenAddress Token Address permit to claim the NFT ERC721 Token
		 * @param _collectionName Name of Collection the ERC721 token
     */
    function claimMintERC721(
        bytes memory signature,
        address toAddress,
        uint256 quantityTokens,
        uint256[] calldata qualifyingTokensIds,
        uint256 deadline,
        address tokenAddress,
        string memory _collectionName
    ) external whenNotPaused {
        uint256 collectionName = getIndexCollection(_collectionName);
				require(tokenAddress.isContract(), "VoxoDeus: Invalid Token Address");
        require(
            block.timestamp < deadline,
            "VoxoDeus: Expired Claim Permission"
        );
        require(
            toAddress == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );

        require(
            !hasPriorClaim(collectionName, qualifyingTokensIds),
            "VoxoDeus: At least one qualifying token has already been used in a prior claim"
        );

        // Check if the wallet have the ownership of the Voxo Token Ids, in case send a valid array of tokenIds
        if ((qualifyingTokensIds.length > 0) && (qualifyingTokensIds[0] != 0)) {
            require(
                voxoOwnership(qualifyingTokensIds, voxoTokenHoldings(toAddress)),
                "VoxoDeus: At least one qualifying token is not currently owned by the claimant"
            );
        }

        bytes32 message = createClaimMintMessageERC721(
            toAddress,
            quantityTokens,
            _hashArray(qualifyingTokensIds),
            tokenAddress,
            collection[collectionName]
        );
        address signer = validateMessageSignature(message, signature);

        require(signer != address(0), "VoxoDeus: INVALID_SIGNATURE");
        require(
            hasRole(DISTRIBUTION_ROLE, signer),
            "VoxoDeus: Mismatch between requested and permitted tokens"
        );
        IERC721Aextends token = IERC721Aextends(tokenAddress);
        uint256[] memory beforeTokenIds = tokenHoldings(
            toAddress,
            tokenAddress
        );
        token.safeMint(toAddress, quantityTokens);
        addBlocklistPerVoxo(
            qualifyingTokensIds,
            collectionName
        );
        emit ClaimedPerVoxoERC721(
            toAddress,
            onlyMintedTokens(
                tokenHoldings(toAddress, tokenAddress),
                beforeTokenIds
            ),
            qualifyingTokensIds,
            tokenAddress,
            collection[collectionName]
        );
    }

    /**
     * @dev Generate Hashed Message based on EIP-712 payload which is signed off-chain by the Distribution account
     * @param to_address Account allowed to claim
     * @param token_ids Hash of claimable token Ids
     * @param quantities Hash of claimable quantities
     * @param qualifying_token_ids Hash of qualifying token ids used in the claim
     * @param token_address Token address the claim is for
     * @param collection_name index of collection name the claim is for
     */
    function createClaimMessageERC1155(
        address to_address,
        string memory token_ids,
        string memory quantities,
        string memory qualifying_token_ids,
        address token_address,
        string memory collection_name
    ) internal view returns (bytes32) {
        require(
            to_address == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimAllowance(address to_address,string token_ids,string quantities,string qualifying_token_ids,address token_address,string collection_name)"
                        ),
                        to_address,
                        keccak256(bytes(token_ids)),
                        keccak256(bytes(quantities)),
                        keccak256(bytes(qualifying_token_ids)),
                        token_address,
                        keccak256(bytes(collection_name))
                    )
                )
            );
    }

    /**
     * @dev Function for Generate Hashed Message based on EIP-712 payload will be sign by the Distribution Wallet off-chain
     * @dev permitted to claim NFT ERC721 Token validate with signature of the Distribution Wallet
     * @param to_address Account allowed to claim
     * @param token_ids Hash of claimable token Ids
     * @param qualifying_token_ids Hash of qualifying token ids used in the claim
     * @param token_address Token address the claim is for
     * @param collection_name index of collection name the claim is for
     */
    function createClaimMessageERC721(
        address to_address,
        string memory token_ids,
        string memory qualifying_token_ids,
        address token_address,
        string memory collection_name
    ) internal view returns (bytes32) {
        require(
            to_address == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimAllowance(address to_address,string token_ids,string qualifying_token_ids,address token_address,string collection_name)"
                        ),
                        to_address,
                        keccak256(bytes(token_ids)),
                        keccak256(bytes(qualifying_token_ids)),
                        token_address,
                        keccak256(bytes(collection_name))
                    )
                )
            );
    }

    /**
     * @dev Function for Generate Hashed Message based on EIP-712 payload will be sign by the Distribution Wallet off-chain
     * @dev permitted to claim NFT ERC721 Token validate with signature of the Distribution Wallet
     * @param to_address Account allowed to claim
     * @param quantity Amount Hashed allowed to claim the ERC721 NFT token
     * @param qualifying_token_ids Hash of qualifying token ids used in the claim
     * @param token_address Token address the claim is for
     * @param collection_name index of collection name the claim is for
     */
    function createClaimMintMessageERC721(
        address to_address,
        uint256 quantity,
        string memory qualifying_token_ids,
        address token_address,
        string memory collection_name
    ) internal view returns (bytes32) {
        require(
            to_address == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimAllowance(address to_address,uint256 quantity,string qualifying_token_ids,address token_address,string collection_name)"
                        ),
                        to_address,
                        quantity,
                        qualifying_token_ids,
                        token_address,
                        keccak256(bytes(collection_name))
                    )
                )
            );
    }

    /**
     * @notice Valid a EIP712 signature
     * @param message          - hash of the message constructed according to EIP712
     * @param signature        - signature of the message
     * @return whether the signature is valid
     */
    function validateMessageSignature(bytes32 message, bytes memory signature)
        public
        pure
        returns (address)
    {
        return ECDSAUpgradeable.recover(message, signature);
    }

    function madePriorClaim(uint256 collectionName, address toAddress)
        public
        view
        returns (bool)
    {
        return blocklistPerWallet[collectionName][toAddress];
    }

    /**
     * @dev Check if any of the provided Voxo Ids were previously used in a successful claim.
     * @param collectionName Name of the collection the VoxoDeus tokenIds qualify the claimant for
     * @param _voxoTokenIds VoxoDeus tokenIds to check
     * @return bool true if any VoxoDeus was used in a previous claim, false if none were
     */
    function hasPriorClaim(
        uint256 collectionName,
        uint256[] calldata _voxoTokenIds
    ) public view returns (bool) {
        for (uint256 i = 0; i < _voxoTokenIds.length; i++) {
            if (blocklistPerVoxo[collectionName][_voxoTokenIds[i]]) {
                return true;
            }
        }
        return false;
    }

    function addBlocklistPerVoxo(
        uint256[] memory qualifyingTokenIds,
        uint256 _collection
    ) internal {
        for (uint256 i = 0; i < qualifyingTokenIds.length; i++) {
            blocklistPerVoxo[_collection][qualifyingTokenIds[i]] = true;
        }
    }

    /**
     * @dev Verify is the address has ownership of one or several Voxos
     * @param _owner address to own the tokens
     * @return tokenIds Array of tokens who the _owner address is the owner
     */
    function voxoTokenHoldings(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        IERC721EnumerableUpgradeable token = IERC721EnumerableUpgradeable(
            VOXODEUS_CONTRACT_ADDRESS
        );
        uint256 ownerTokenCount = token.balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = token.tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /**
     * @dev Overloading previous method to Verify if the address is owner of one or several Token of NFT smart Contract, passed in the args
     * @param _owner address to owner of the tokens
     * @return tokenIds Array of token Ids of Yield Keys who the _owner address is the owner
     */
    function tokenHoldings(address _owner, address _token)
        public
        view
        returns (uint256[] memory)
    {
        IERC721EnumerableUpgradeable token = IERC721EnumerableUpgradeable(
            _token
        );
        uint256 ownerTokenCount = token.balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = token.tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /**
     * @dev Verify that each of the tokenIds used in a claim are currently held by the claimant
     * @param qualifyingTokenIds tokenIds used to make a claim
     * @param ownedTokenIds tokenIds currently owned by the claiment
     * @return true if all qualifyingTokenIds are currently ownerd by the claimant
     */
    function voxoOwnership(
        uint256[] memory qualifyingTokenIds,
        uint256[] memory ownedTokenIds
    ) public pure returns (bool) {
        // Simply get (start from) the first number from the tokenToClaim array
        for (uint256 ii = 0; ii < qualifyingTokenIds.length; ii++) {
            // and check it against the numbers (in tokenHold),
            for (uint256 jj = 0; jj < ownedTokenIds.length; jj++) {
                // If you find it
                if (qualifyingTokenIds[ii] == ownedTokenIds[jj]) {
                    // break and pass to the second number in the ownedTokenIds array
                    break;
                    // if you do not find it
                } else {
                    // and you were checking the fourth (last) number of the ownedTokenIds array
                    // (meaning you have checked them all)
                    // break and return false
                    if (jj == ownedTokenIds.length - 1) return false;
                    // otherwise check the next number in the ownedTokenIds array
                    continue;
                }
            }
        }
        // When you finished looping through all the qualifyingTokenIds numbers,
        // and any number of the qualifyingTokenIds array maps to some numbers in the ownedTokenIds array,
        // you can return true.
        return true;
    }

    function setCollection(uint256 index, string memory collectionName)
        public
        onlyOwner
    {
        collection[index] = collectionName;
    }

    /**
     * @dev Method for Encode, Concatenate and Hash the Array of Unit256
     * @param _array Array of Unit256
     * @return bytes32 hash keccak256 of array of unit256 concatenate
     */
    function _hashArray(uint256[] memory _array)
        internal
        pure
        returns (string memory)
    {
        if (_array.length == 0) {
						return "";
				}
        bytes memory stringConcat;
        for (uint256 i = 0; i < _array.length; i++) {
            stringConcat = bytes.concat(
                bytes(stringConcat),
                bytes(getSliceArray(_array[i]))
            );
        }
        return bytes32ToString(keccak256(stringConcat));
    }

    /**
     * @dev Method for get Slice of Array of Unit256
     * @param _array element of Array Unit256
     * @return string memory Slice of String with the last 4 bytes or minus
     */
    function getSliceArray(uint256 _array)
        internal
        pure
        returns (string memory)
    {
        bytes memory _slice = bytes(StringsUpgradeable.toString(_array));
        uint256 x;
        if (_slice.length > 3) {
            x = 3;
        } else {
            x = _slice.length - 1;
        }
        return getSlice((_slice.length - x), (_slice.length), _slice);
    }

    /**
     * @dev Method for get Slice of Array of Unit256
     * @param begin index to start the slice
     * @param end index to end the slice
     * @param text string to getting the slice
     * @return string memory Slice of String with the last element indicated by the begin and end index
     */
    function getSlice(
        uint256 begin,
        uint256 end,
        bytes memory text
    ) internal pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint256 i = 0; i <= end - begin; i++) {
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);
    }

    /**
     * @dev Subtract tokenIds held prior to minting the current batch from the total owned
     * @param _arrayBefore Array of Unit256
     * @param _arrayAfter Array of Unit256
     * @return _arrayDiff bytes32 hash keccak256 of array of unit256 concatenate
     */
    function onlyMintedTokens(
        uint256[] memory _arrayAfter,
        uint256[] memory _arrayBefore
    ) internal pure returns (uint256[] memory _arrayDiff) {
        require(
            _arrayAfter.length > 0,
            "Array of token ids after minting is empty"
        );
        _arrayDiff = _arrayAfter;
        if (_arrayBefore.length == 0) {
            return _arrayDiff;
        }
        for (uint256 i = 0; i < _arrayBefore.length; i++) {
            for (uint256 j = 0; j < _arrayAfter.length; j++) {
                if (_arrayBefore[i] == _arrayAfter[j]) {
                    _arrayDiff[j] = _arrayDiff[_arrayDiff.length - 1];
                    delete _arrayDiff[_arrayDiff.length - 1];
                }
            }
        }
    }

    /**
     * @dev Method to get the index of a Collection
     * @param _collectionName string of collection name
     */
    function getIndexCollection(string memory _collectionName)
        internal
        view
        returns (uint256)
    {
        string memory empty = "";
        require(
            !stringComp(bytes(empty), bytes(_collectionName)),
            "VoxoDeus: Collection name is empty"
        );
        for (uint256 i = 0; i < collectionLength; i++) {
            string memory a = collection[i];
            if (stringComp(bytes(a), bytes(_collectionName))) {
                return i;
            }
        }
        revert("VoxoDeus: Collection not found");
    }

    /**
     * @dev Get all registered Collection names
     * @return array of string memory with the all elements of the collection mapping
     */
    function getAllCollection() public view returns (string[] memory) {
        string[] memory collections = new string[](collectionLength);
        for (uint256 i = 0; i < collectionLength; i++) {
            collections[i] = collection[i];
        }
        return collections;
    }

    /**
     * @dev Method for Setting a New Collection Name (Only by the Owner)
     * @param _collectionName string of new collection name, and use collectionLength for create a new index in the mapping
     */
    function setCollection(string memory _collectionName) public onlyOwner {
        string memory empty = "";
        require(
            !stringComp(bytes(empty), bytes(_collectionName)),
            "VoxoDeus: Collection name is empty"
        );
        for (uint256 i = 0; i < collectionLength; i++) {
            string memory a = collection[i];
            require(
                !stringComp(bytes(a), bytes(_collectionName)),
                "VoxoDeus: Collection already exists"
            );
        }
        collectionLength++;
        collection[collectionLength - 1] = _collectionName;
    }

    /**
     * @dev Method for String comparing
     * @param a bytes memory bytes to convert in hex as string
     * @param b bytes memory bytes to convert in hex as string
     * @return boolean, true if is equal, and false if not
     */
    function stringComp(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    /**
     @dev Method for convert bytes32 to String
     @param _bytes32 bytes32 like keccak256 hash
     @return string memory, result of the convertion
     */
    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return iToHex(bytesArray);
    }

    /**
     * @dev Method for convert bytes to hex as String
     * @param buffer bytes memory bytes to convert in hex as string
     * @return string memory hex as string
     */
    function iToHex(bytes memory buffer) public pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }
        return string(abi.encodePacked("0x", converted));
    }
}
