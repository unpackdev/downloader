// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title An interface for a bridge contract
/// @dev Declares default methods of a bridge contract
interface IBridge {

    /**
     * In case if tokens were transfered from chainA to chainB
     * chainA is the source chain
     * chainB is the target chain
     * If case if then tokens were transfered back from chainB to chainA
     * chainA is still the source chain
     * chainB is still the target chain
     * (in comments below)
     */

    /// @notice structure that passed to the contract during it's operations with tokens on a source chain
    /// @param amount The amount of tokens to lock
    /// @param token Token address (address(0) if native)
    /// @param tokenId Token ID in case of operations with ERC721 or ERC1155, must be set to 0 otherwise
    /// @param receiver Receiver address
    /// @param targetChain The name of the target chain
    /// @param stargateAmountForOneUsd Stargate tokens (ST) amount for one USD (set to 0 if not needed)
    /// @param transferedTokensAmountForOneUsd TT tokens amount for one USD (set to 0 if not needed)
    /// @param payFeesWithST true if user choose to pay fees with stargate tokens (false if not needed)
    /// @param nonce Prevent replay attacks
    /// @param v Last byte of the signed PERMIT_DIGEST
    /// @param r First 32 bytes of the signed PERMIT_DIGEST
    /// @param v 32-64 bytes of the signed PERMIT_DIGEST
    struct sourceBridgeParams {
        uint256 amount;
        address token;
        uint256 tokenId;
        string receiver;
        string targetChain;
        uint256 stargateAmountForOneUsd;
        uint256 transferedTokensAmountForOneUsd;
        bool payFeesWithST;
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    /// @notice structure that passed to the contract during it's operations with tokens on a target chain
    /// @param amount The amount of tokens to lock
    /// @param token Token address (address(0) if native)
    /// @param tokenId Token ID in case of operations with ERC721 or ERC1155, must be set to 0 otherwise
    /// @param nonce Prevent replay attacks
    /// @param v Last byte of the signed PERMIT_DIGEST
    /// @param r First 32 bytes of the signed PERMIT_DIGEST
    /// @param v 32-64 bytes of the signed PERMIT_DIGEST
    struct targetBridgeParams {
        uint256 amount;
        address token;
        uint256 tokenId;
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice asset types 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    enum Assets {
        Native,
        ERC20,
        ERC721,
        ERC1155
    }

    /// @notice Locks tokens if the user is permitted to lock
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param params BridgeParams structure (see definition in IBridge.sol)
    /// @return True if tokens were locked successfully
    function lockWithPermit(Assets assetType, sourceBridgeParams calldata params)
        external payable returns(bool);

    /// @notice Burn tokens if the user is permitted to burn
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param params BridgeParams structure (see definition in IBridge.sol)
    /// @return True if tokens were burned successfully
    function burnWithPermit(Assets assetType, sourceBridgeParams calldata params)
        external returns(bool);
    
    /// @notice Mint tokens if the user is permitted to mint
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param params BridgeParams structure (see definition in IBridge.sol)
    /// @return True if tokens were minted successfully
    function mintWithPermit(Assets assetType, targetBridgeParams calldata params)
        external returns(bool);
    
    /// @notice Unlocks tokens if the user is permitted to unlock
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param params BridgeParams structure (see definition in IBridge.sol)
    /// @return True if tokens were unlocked successfully
    function unlockWithPermit(Assets assetType, targetBridgeParams calldata params)
        external returns(bool);

    /// @notice Indicates that tokens were locked in the source chain
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param sender The sender of the locking transaction
    /// @param receiver The receiver of wrapped tokens
    /// @param amount The amount of tokens to lock
    /// @param token The address of token to lock
    /// @param tokenId The ID of token to lock (0 if fungible tokens)
    /// @param targetChain The name of the target chain
    event Lock(
        Assets assetType,
        address indexed sender,
        string receiver,
        uint256 amount,
        address indexed token,
        uint256 indexed tokenId,
        string targetChain
    );
    /// @notice Indicates that tokens were burnt in the target chain
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param sender The sender of the burning transaction
    /// @param receiver The receiver of the unlocked tokens
    /// @param amount The amount of tokens to burn
    /// @param token The address of token to burn
    /// @param tokenId The ID of token to burn (0 if fungible tokens)
    /// @param targetChain The name of the target chain
    event Burn(
        Assets assetType,
        address indexed sender,
        string receiver,
        uint256 amount,
        address indexed token,
        uint256 indexed tokenId,
        string targetChain
    );
    /// @notice Indicates that tokens were minted by permitted user
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param sender The sender of the minting transaction
    /// @param receiver The receiver of tokens
    /// @param amount The amount of tokens to mint
    /// @param token The address of token to mint
    /// @param tokenId The ID of token to mint (0 if fungible tokens)
    /// @param targetChain The name of the target chain
    event Mint(
        Assets assetType,
        address indexed sender,
        address receiver,
        uint256 amount,
        address indexed token,
        uint256 indexed tokenId,
        string targetChain
    );
    /// @notice Indicates that tokens were unlocked in the source chain
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param sender The sender of the unlocking transaction
    /// @param receiver The receiver of the unlocked tokens
    /// @param amount The amount of tokens to unlock
    /// @param token The address of the token to unlock
    /// @param tokenId The ID of the token to unlock(0 if fungible tokens)
    /// @param targetChain The name of the target chain
    event Unlock(
        Assets assetType,
        address indexed sender,
        address receiver,
        uint256 amount,
        address indexed token,
        uint256 indexed tokenId,
        string targetChain
    );
    /// @notice Indicates that token fees were withdrawn
    /// @param receiver Address of the wallet in the source chain
    /// @param amount The amount of fees from a single token to be withdrawn
    event Withdraw(
        address indexed receiver,
        uint256 amount
    );

    /// @notice Indicates that the a admin was set
    /// @param newAdmin The address of a new admin
    event SetAdmin(
        address indexed newAdmin
    );

    /// @notice Indicates that a new fee rate was set
    /// @param newFeeRateBp A new fee rate in basis points
    event SetFeeRate(
        uint256 indexed newFeeRateBp
    );

    /// @notice Indicates that a new supported chain was set
    /// @param newChain The name of a new supported chain
    event SetNewChain(
        string newChain
    );

    /// @notice Indicates that a chain is no longer supported
    /// @param oldChain The name of a previously supported chain
    event RemoveChain(
        string oldChain
    );
}
