// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Utilities
import "./TWStrings.sol";

// The SignatureMint base contract has the following implementations:
// ERC721Base (Royalty, Ownable, a few others), PrimarySale, SignatureMintERC721
import "./ERC721SignatureMint.sol";

// The base contract is fairly lightweight, so implement all of the extensions
// we care about
import "./PermissionsEnumerable.sol";
import "./LazyMint.sol";

import "./RandomSignatureMint.sol";

using TWStrings for uint256;

contract BookDEA is
    PermissionsEnumerable,
    RandomSignatureMint
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes16 public mediaId;

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint16 _royaltyBps,
        address _primarySaleRecipient,
        bytes16 _mediaId
    )
        RandomSignatureMint(
            _defaultAdmin,
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        mediaId = _mediaId;
    }


    /***********************************************************************
     *  Roles & Permissions
     ***********************************************************************/

    /// @dev Restricts who can sign mint requests
    function _canSignAnyRequest(address _signer) internal view virtual override returns (bool) {
        return hasRole(MINTER_ROLE, _signer);
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override(ERC721Base, Royalty) returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Determine if the current address can lazy mint
    function _canLazyMint() internal view virtual override returns (bool) {
        return hasRole(MINTER_ROLE, _msgSender());
    }

    /// @dev Determine if the current address can change the randomized minting flag
    function _canChangeRandomizedMinting() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _canChangeCoolMint() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /***********************************************************************
     *  Minting
     ***********************************************************************/


    /// @dev Lazy mint a batch of tokens, must have the MINTER_ROLE
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public override returns (uint256 batchId) {
        // Generate and add all of the ids to the remainingMintableTokens array
        if (isRandomized) {
            for (uint256 i = 0; i < _amount; i++) {
                remainingMintableTokens.push(nextTokenIdToLazyMint + i);
            }
        }

        return super.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /***********************************************************************
     *  Extras
     ***********************************************************************/

    /**
     * Returns the total amount of tokens minted in the contract.
     * This was pulled from the original signature drop contract
     */
    function totalMinted() external view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /** Returns the total amount of tokens that were uploaded
     *  into the contract.
     */
    function totalLazyMinted() external view returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /**
     * A function that takes a mint request & signature, and returns the price.
     * This is so that usewinter can pull dynamic prices
     */
    function mintRequestPrice(MintRequest calldata _req, bytes calldata _signature)
        public
        view
        returns (uint256) {
        (bool isValid,) = verify(_req, _signature);
        require(isValid, "Invalid signature");

        return _req.pricePerToken;
    }

    /**
     * A function that takes a random mint request & signature, and returns the
     * price. This is so that usewinter can pull dynamic prices
     */
    function randMintRequestPrice(RandomMintRequest calldata _req, bytes calldata _signature)
        public
        view
        returns (uint256) {
        (bool isValid,) = verifyRandom(_req, _signature);
        require(isValid, "Invalid signature");

        return _req.pricePerToken;
    }
}
