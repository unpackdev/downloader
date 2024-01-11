// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Adminable.sol";
import "./Ownable.sol";

struct ConstructorConfig {
    string name;
    string symbol;
    string tokenURI;
    uint256 quantity;
    address admin;
    address owner;
}

struct TransferTo {
    uint256 id;
    address to;
}

/// @title HumeAngelbabyCommunityEP1
/// @notice Represents a single from the first HumeAngelbaby EP.
contract HumeAngelbabyCommunityEP1 is ERC721A, Ownable, Adminable {
    /// @dev The current token URI returned by tokenURI().
    string private _tokenURI;

    /// Emitted when contract is constructed.
    /// @param sender the `msg.sender` that deploys the contract.
    /// @param config All config used by the constructor.
    event Construct(address sender, ConstructorConfig config);

    /// Emitted when the token URI is changed by the admin.
    /// @param sender the `msg.sender` (admin) that sets the token URI.
    /// @param tokenURI the new token URI.
    event TokenURI(address sender, string tokenURI);

    /// Token constructor.
    /// Assigns owner and admin roles, mints all tokens for the admin and sets
    /// initial token URI.
    constructor(ConstructorConfig memory config_)
        ERC721A(config_.name, config_.symbol)
    {
        // Setup roles.
        _transferAdmin(config_.admin);
        _transferOwnership(config_.owner);

        // Mint all tokens for the admin.
        _safeMint(config_.admin, config_.quantity);

        _tokenURI = config_.tokenURI;
        emit Construct(msg.sender, config_);
    }

    /// Admin MAY set a new token URI at any time.
    /// @param tokenURI_ The new token URI for all tokens.
    function adminSetTokenURI(string memory tokenURI_) external onlyAdmin {
        _tokenURI = tokenURI_;
        emit TokenURI(msg.sender, tokenURI_);
    }

    /// Admin MAY set a new owner at any time.
    /// The owner has no onchain rights other than transferring ownership.
    /// @param owner_ The new owner address.
    function adminSetOwner(address owner_) external onlyAdmin {
        _transferOwnership(owner_);
    }

    /// Optimistically transfer many tokens to many EOA
    /// (Externally Owned Account) recipients.
    /// As a recipient in the list could be a smart contract that does NOT
    /// implement `ERC721TokenReceiver` a `safeTransferFrom` call WOULD fail.
    /// 721A has set its `onERC721Received` checks to private rather than
    /// internal so we simply skip all contracts. The sender will need to
    /// review the result of the transfers offchain and retry sending to any
    /// contracts individually.
    /// @param transfers_ List of ids and recipients to transfer to.
    function multiTransferToEOA(TransferTo[] calldata transfers_) external {
        address to_;
        uint256 id_;
        for (uint256 i_ = 0; i_ < transfers_.length; i_++) {
            to_ = transfers_[i_].to;
            id_ = transfers_[i_].id;
            // Rather than error on failed receipt of the 721 by a smart
            // contract we skip that recipient and continue processing other
            // transfers.
            if (to_.code.length == 0) {
                transferFrom(msg.sender, to_, id_);
            }
        }
    }

    /// @inheritdoc ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// Override the 721A tokenURI to remove the string concatenation of token
    /// IDs as all metadata for all tokens is identical. WILL error as per spec
    /// if called for a nonexistant tokenID_.
    /// @inheritdoc ERC721A
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId_)) revert URIQueryForNonexistentToken();
        return _tokenURI;
    }
}
