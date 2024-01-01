// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// Local imports
import "./CrossChainRequestTypes.sol";
import "./StorageTypes.sol";

/// @notice Library that defines requests sent from frontend to smart contracts.
library RequestTypes {
    // -----------------------------------------------------------------------
    //                              Base
    // -----------------------------------------------------------------------

    /// @dev Struct defining low level data for any request.
    /// @param sender Address of account executing tx
    /// @param expiry Deadline on which request expires
    /// @param nonce Number used only once used to prevent tx reply or out of order execution
    struct BaseRequest {
        address sender;
        uint256 expiry;
        uint256 nonce;
    }

    // -----------------------------------------------------------------------
    //                              Raise
    // -----------------------------------------------------------------------

    /// @dev Struct used to create a raise.
    /// @param raise Struct containing info about raise
    /// @param raiseDetails Mapping of raise id to vested token information
    /// @param erc20Asset Struct containing info about vested ERC20
    /// @param baseAsset Struct containing info about asset used for investment
    /// @param badgeUri IPFS URI that initializes equity badge for the raise
    /// @param base Struct defining low level data for a request
    struct CreateRaiseRequest {
        StorageTypes.Raise raise;
        StorageTypes.RaiseDetails raiseDetails;
        StorageTypes.ERC20Asset erc20Asset;
        StorageTypes.BaseAsset baseAsset;
        string badgeUri;
        BaseRequest base;
    }

    /// @dev Struct used to create a raise.
    /// @param raise Struct containing info about raise
    /// @param raiseDetails Mapping of raise id to vested token information
    /// @param erc20Asset Struct containing info about vested ERC20
    /// @param baseAsset Struct containing info about asset used for investment
    /// @param crossChainBase Struct defining low level data for a cross-chain requests
    struct RegisterRaiseRequest {
        StorageTypes.Raise raise;
        StorageTypes.RaiseDetails raiseDetails;
        StorageTypes.ERC20Asset erc20Asset;
        StorageTypes.BaseAsset baseAsset;
        CrossChainRequestTypes.CrossChainBase crossChainBase;
    }

    // -----------------------------------------------------------------------
    //                              Set token
    // -----------------------------------------------------------------------

    /// @dev Struct used to set a token for an early stage raise.
    /// @param raiseId UUID of raise
    /// @param token Address of ERC20
    /// @param base Struct defining low level data for a request
    struct SetTokenRequest {
        string raiseId;
        address token;
        BaseRequest base;
    }

    // -----------------------------------------------------------------------
    //                              Invest
    // -----------------------------------------------------------------------

    /// @dev Struct used to invest into raise.
    /// @param raiseId UUID of raise
    /// @param investment Amount of base asset used to invest
    /// @param maxTicketSize Individual limit of investment for validation
    /// @param base Struct defining low level data for a request
    struct InvestRequest {
        string raiseId;
        uint256 investment;
        uint256 maxTicketSize;
        BaseRequest base;
    }

    // -----------------------------------------------------------------------
    //                              Voting
    // -----------------------------------------------------------------------

    /// @dev Struct used to unlock milestone
    /// @param raiseId UUID of raise
    /// @param milestone Struct containing info about unlocked milestone
    /// @param base Struct defining low level data for a request
    struct UnlockMilestoneRequest {
        string raiseId;
        StorageTypes.Milestone milestone;
        BaseRequest base;
    }

    /// @dev Struct used to submit failed repair plan
    /// @param raiseId UUID of raise
    /// @param base Struct defining low level data for a request
    struct RejectRaiseRequest {
        string raiseId;
        BaseRequest base;
    }

    // -----------------------------------------------------------------------
    //                              Claiming
    // -----------------------------------------------------------------------

    /// @dev Struct used to claim a tokens from milestone
    /// @param raiseId UUID of raise
    /// @param recipient Account claiming funds
    /// @param base Struct defining low level data for a request
    struct ClaimRequest {
        string raiseId;
        address recipient;
        BaseRequest base;
    }
}
