// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./Claimable.sol";


/**
 * @title Claim and Distribution Smart Contract
 * @dev Claim and Distribution Smart Contracts - Smart Contract, to manage the Claim and distribution of NFT tokens
 * @dev based on the ERC1155 and ERC721 standards, through a Claim process based on the payload signature,
 * @dev for verification and validation of the token or tokens assigned to specific users
 * @custom:a The Cypherverse Ltd
 */
contract ClaimContractV4 is
    Initializable,
    Claimable,
    PausableUpgradeable,
    EIP712Upgradeable,
    AccessControlUpgradeable
{
    using StringsUpgradeable for string;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    // Constant for Minter Role
    bytes32 public constant DISTRIBUTION_ROLE = keccak256("DISTRIBUTION_ROLE");
    // Token Contract Address for Distribution
    address private tokenAddress;
    // Struct claimed wallet
    struct ClaimableWallet {
        bool claimed;
        address toAddress;
        address tokenAddress;
    }
    mapping(address => ClaimableWallet) public claimedWallets;
    // Token Address V1
    address private contractAddressV1;
    /**
     * @dev Event for Each NFT ERC1155 Token Claimed by the StakeHolders of VoxoDeus
     * @param voxoUser Address of the Minter/Holder of the NFT ERC1155 Token
     * @param ids Id permit to claim the NFT ERC1155 Token
     * @param amounts Amount permit to claim the NFT ERC1155 Token
     */
    event tokenERC1155Claimed(
        address voxoUser,
        uint256[] ids,
        uint256[] amounts
    );
    /**
     * @dev Event for Each NFT ERC721 Token Claimed by the StakeHolders of VoxoDeus
     * @param voxoUser Address of the Minter/Holder of the NFT ERC721 Token
     * @param ids Id permit to claim the NFT ERC721 Token
     */
    event tokenERC721Claimed(address voxoUser, uint256[] ids);

    function initialize(
        address _distributionRoleAddress,
        address verifyingContract
    ) public initializer {
        __Ownable_init();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DISTRIBUTION_ROLE, _distributionRoleAddress);
        __EIP712_init("TheCypherverse", "1.0.0", verifyingContract);
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
     * @dev Set the address of the Token Contract for Distribution
     * @param _tokenAddress Address of the Token Contract
     */
    function setTokenContractAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    /**
     * @dev Get Token Contract Address
     * @return tokenAddress address Address of the Token Contract
     */
    function getTokenContractAddress() public view returns (address) {
        return tokenAddress;
    }

    /**
     * @dev Function for Claim NFT ERC1155 Token based on payload signed by the Distribution Wallet
     * @dev permitted to claim NFT ERC1155 Token based signed by the Distribution Wallet
     * @param signature Signature of the payload
     * @param toAddress Wallet allowed to claim the ERC1155 NFT token
     * @param claimableTokenIds Ids allowed to claim the ERC1155 NFT token
     * @param claimableQuantities Amount allowed to claim the ERC1155 NFT token
     * @param deadline timestamp of deadline to claim
     * @param _collectionName Name of Collection the ERC1155 token
     */
    function metaClaimERC1155(
        bytes memory signature,
        address toAddress,
        uint256[] calldata claimableTokenIds,
        uint256[] calldata claimableQuantities,
        uint256 deadline,
        string memory _collectionName
    ) external whenNotPaused {
        require(
            block.timestamp < deadline,
            "VoxoDeus: Expired Claim Permission"
        );
        require(
            toAddress == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );
        require(
            !isClaimed(_msgSender()),
            "VoxoDeus: Assets have already been claimed"
        );
        bytes memory data = "";

        bytes32 message = createMetaClaimERC1155(
            toAddress,
            _hashArray(claimableTokenIds),
            _hashArray(claimableQuantities),
            tokenAddress,
            _collectionName
        );
        address signer = validateMessageSignature(message, signature);

        require(signer != address(0), "VoxoDeus: INVALID_SIGNATURE");
        require(
            hasRole(DISTRIBUTION_ROLE, signer),
            "VoxoDeus: Cannot claim a meta set number that has not been signed by the owner"
        );
        IERC1155Upgradeable token = IERC1155Upgradeable(tokenAddress);
        token.safeBatchTransferFrom(
            signer,
            toAddress,
            claimableTokenIds,
            claimableQuantities,
            data
        );
        ClaimableWallet memory _claimedWallet = ClaimableWallet({
            claimed: true,
            toAddress: toAddress,
            tokenAddress: tokenAddress
        });
        claimedWallets[_msgSender()] = _claimedWallet;
        emit tokenERC1155Claimed(
            toAddress,
            claimableTokenIds,
            claimableQuantities
        );
    }

    /**
     * @dev Function for Claim NFT ERC721 Token based on payload signed by the Distribution Wallet
     * @dev permitted to claim NFT ERC721 Token based signed by the Distribution Wallet
     * @param signature Signature of the payload
     * @param toAddress Wallet allowed to claim the ERC721 NFT token
     * @param claimableTokenIds Ids allowed to claim the ERC721 NFT token
     * @param deadline timestamp of deadline to claim
     * @param _collectionName Name of Collection the ERC1155 token
     */
    function metaClaimERC721(
        bytes memory signature,
        address toAddress,
        uint256[] calldata claimableTokenIds,
        uint256 deadline,
        string memory _collectionName
    ) external whenNotPaused {
        require(
            block.timestamp < deadline,
            "VoxoDeus: Expired Claim Permission"
        );
        require(
            toAddress == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );
        require(
            !isClaimed(_msgSender()),
            "VoxoDeus: Assets have already been claimed"
        );
        bytes memory data = "";

        bytes32 message = createMetaClaimERC721(
            toAddress,
            _hashArray(claimableTokenIds),
            tokenAddress,
            _collectionName
        );
        address signer = validateMessageSignature(message, signature);

        require(signer != address(0), "VoxoDeus: INVALID_SIGNATURE");
        require(
            hasRole(DISTRIBUTION_ROLE, signer),
            "VoxoDeus: Cannot claim a meta set number that has not been signed by the owner"
        );
        IERC721Upgradeable token = IERC721Upgradeable(tokenAddress);
        for (uint256 i = 0; i < claimableTokenIds.length; i++) {
            token.safeTransferFrom(
                signer,
                toAddress,
                claimableTokenIds[i],
                data
            );
        }
        ClaimableWallet memory _claimedWallet = ClaimableWallet({
            claimed: true,
            toAddress: toAddress,
            tokenAddress: tokenAddress
        });
        claimedWallets[_msgSender()] = _claimedWallet;
        emit tokenERC721Claimed(toAddress, claimableTokenIds);
    }

    /**
     * @dev Function for Generate Hashed Message based on EIP-712 payload will be sign by the Distribution Wallet off-chain
     * @dev permitted to claim NFT ERC1155 Token validate with signature of the Distribution Wallet
     * @param to_address Wallet allowed to claim the ERC1155 NFT token
     * @param token_ids TokenIds Hashed allowed to claim the ERC1155 NFT token
     * @param quantities Amount Hashed allowed to claim the ERC1155 NFT token
     * @param token_address Token Address permit to claim the NFT ERC1155 Token
     * @param collection_name index of collection name permit to claim the NFT ERC1155 Token
     */
    function createMetaClaimERC1155(
        address to_address,
        string memory token_ids,
        string memory quantities,
        address token_address,
        string memory collection_name
    ) public view returns (bytes32) {
        require(
            to_address == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimAllowance(address to_address,string token_ids,string quantities,address token_address,string collection_name)"
                        ),
                        to_address,
                        keccak256(bytes(token_ids)),
                        keccak256(bytes(quantities)),
                        token_address,
                        keccak256(bytes(collection_name))
                    )
                )
            );
    }

    /**
     * @dev Function for Generate Hashed Message based on EIP-712 payload will be sign by the Distribution Wallet off-chain
     * @dev permitted to claim NFT ERC721 Token validate with signature of the Distribution Wallet
     * @param toAddress Wallet allowed to claim the ERC721 NFT token
     * @param token_ids Amount Hashed allowed to claim the ERC721 NFT token
     * @param token_address Token Address permit to claim the NFT ERC1155 Token
     * @param collection_name Collection Name permit to claim the NFT ERC1155 Token
     */
    function createMetaClaimERC721(
        address toAddress,
        string memory token_ids,
        address token_address,
        string memory collection_name
    ) public view returns (bytes32) {
        require(
            toAddress == _msgSender(),
            "VoxoDeus: Invalid Account - Claimant can only claim to their own account"
        );

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimAllowance(address to_address,string token_ids,address token_address,string collection_name)"
                        ),
                        toAddress,
                        keccak256(bytes(token_ids)),
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
     * @return whether if the signature is valid
     */
    function validateMessageSignature(bytes32 message, bytes memory signature)
        public
        pure
        returns (address)
    {
        return ECDSAUpgradeable.recover(message, signature);
    }

   function isClaimed(address toAddress) public view returns (bool) {
        return claimedWallets[toAddress].claimed;
    }

    /**
     * @dev Method for Encode, Concatenate and Hash the Array of Unit256
     * @param _array Array of Unit256
     * @return bytes32 hash keccak256 of array of unit256 concatenate
     */
    function _hashArray(uint256[] memory _array)
        public
        pure
        returns (string memory)
    {
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
     @dev Method for convert bytes32 to String
     @param _bytes32 bytes32 like keccak256 hash
     @return string memory, result of the convertion
     */
    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        bytes memory bytesArray = new bytes(32);
        for (uint i = 0; i < 32; i++) {
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
