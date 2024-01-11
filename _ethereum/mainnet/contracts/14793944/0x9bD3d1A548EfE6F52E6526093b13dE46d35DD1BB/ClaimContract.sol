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
contract ClaimContract is
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

    function initialize(address _distributionRoleAddress, address verifyingContract) public initializer {
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
     * @param tokenIdsHash TokenIds Hashed allowed to claim the ERC1155 NFT token
     * @param quantitiesHash Amount Hashed allowed to claim the ERC1155 NFT token
     * @param deadline timestamp of deadline to claim
     */
    function metaClaimERC1155(
        bytes memory signature,
        address toAddress,
        uint256[] calldata claimableTokenIds,
        uint256[] calldata claimableQuantities,
        string memory tokenIdsHash,
        string memory quantitiesHash,
        uint256 deadline
    ) external {
        require(
            block.timestamp < deadline,
            "VoxoDeus: Expired Claim Permission"
        );
        require(toAddress == _msgSender(), "VoxoDeus: Invalid reception Wallet");
				require(!isClaimed(_msgSender()), "VoxoDeus: Assets have already been claimed");
        bytes memory data = "";

        bytes32 message = createMetaClaimERC1155(toAddress, tokenIdsHash, quantitiesHash);
        address signer = validateMessageSignature(message, signature);

        require(signer != address(0), "VoxoDeus: INVALID_SIGNATURE");
        require(
            hasRole(DISTRIBUTION_ROLE, signer),
            "VoxoDeus: Cannot claim a meta set number that has not been signed by the owner"
        );
        IERC1155Upgradeable token = IERC1155Upgradeable(tokenAddress);
        token.safeBatchTransferFrom(signer, toAddress, claimableTokenIds, claimableQuantities, data);
				ClaimableWallet memory _claimedWallet = ClaimableWallet({
						claimed: true,
						toAddress: toAddress,
						tokenAddress: tokenAddress
					});
				claimedWallets[_msgSender()] = _claimedWallet;
        emit tokenERC1155Claimed(toAddress, claimableTokenIds, claimableQuantities);
    }

    /**
     * @dev Function for Claim NFT ERC721 Token based on payload signed by the Distribution Wallet
     * @dev permitted to claim NFT ERC721 Token based signed by the Distribution Wallet
     * @param signature Signature of the payload
     * @param toAddress Wallet allowed to claim the ERC721 NFT token
     * @param claimableTokenIds Ids allowed to claim the ERC721 NFT token
     * @param tokenIdsHash TokenIds Hashed allowed to claim the ERC721 NFT token
     * @param deadline timestamp of deadline to claim
     */
    function metaClaimERC721(
        bytes memory signature,
        address toAddress,
        uint256[] calldata claimableTokenIds,
        string memory tokenIdsHash,
        uint256 deadline
    ) external {
        require(
            block.timestamp < deadline,
            "VoxoDeus: Expired Claim Permission"
        );
        require(toAddress == _msgSender(), "VoxoDeus: Invalid reception Wallet");
				require(!isClaimed(_msgSender()), "VoxoDeus: Assets have already been claimed");
        bytes memory data = "";

        bytes32 message = createMetaClaimERC721(toAddress, tokenIdsHash);
        address signer = validateMessageSignature(message, signature);

        require(signer != address(0), "VoxoDeus: INVALID_SIGNATURE");
        require(
            hasRole(DISTRIBUTION_ROLE, signer),
            "VoxoDeus: Cannot claim a meta set number that has not been signed by the owner"
        );
        IERC721Upgradeable token = IERC721Upgradeable(tokenAddress);
        for (uint256 i = 0; i < claimableTokenIds.length; i++) {
            token.safeTransferFrom(signer, toAddress, claimableTokenIds[i], data);
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
     * @param toAddress Wallet allowed to claim the ERC1155 NFT token
     * @param tokenIdsHash TokenIds Hashed allowed to claim the ERC1155 NFT token
     * @param quantitiesHash Amount Hashed allowed to claim the ERC1155 NFT token
     */
    function createMetaClaimERC1155(
        address toAddress,
        string memory tokenIdsHash,
        string memory quantitiesHash
    ) internal view returns (bytes32) {
        require(toAddress == _msgSender(), "VoxoDeus: Invalid reception Wallet");

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimAllowance(address to_address,string token_ids,string quantities)"
                        ),
                        toAddress,
                        keccak256(bytes(tokenIdsHash)),
                        keccak256(bytes(quantitiesHash))
                    )
                )
            );
    }

    /**
     * @dev Function for Generate Hashed Message based on EIP-712 payload will be sign by the Distribution Wallet off-chain
     * @dev permitted to claim NFT ERC721 Token validate with signature of the Distribution Wallet
     * @param toAddress Wallet allowed to claim the ERC721 NFT token
     * @param claimableQuantities Amount Hashed allowed to claim the ERC721 NFT token
     */
    function createMetaClaimERC721(address toAddress, string memory claimableQuantities)
        internal
        view
        returns (bytes32)
    {
        require(toAddress == _msgSender(), "VoxoDeus: Invalid reception Wallet");

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimAllowance(address to_address,string token_ids)"
                        ),
                        toAddress,
                        keccak256(bytes(claimableQuantities))
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

		function isClaimed (address toAddress) public view returns (bool) {
			return claimedWallets[toAddress].claimed;
		}
}
