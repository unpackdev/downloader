// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./UUPSUpgradeable.sol";
import "./IERC721KFNCReceiver.sol";
import "./IERC721KFNC.sol";
import "./IERC165KFNC.sol";


/// @title ERC721KFNCUUPSUpgradeable
/// @author Kfish n Chips
/// @notice Implementation of Non-Fungible Token Standard
/// @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
/// the Metadata extension, but not including the Enumerable extension, which is available separately as
/// {ERC721Enumerable}.
/// @custom:security-contact security@kfishnchips.com
abstract contract ERC721KFNCUUPSUpgradeable is IERC721KFNC, UUPSUpgradeable {
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /// @dev Mapping from token ID to owner address ordered
    mapping(uint256 => address) private _tokenOwnersOrdered;
    /// @dev Mapping from token ID to owner address unordered
    mapping(uint256 => bool) private _unorderedOwner;
    /// @dev Mapping from token ID to owner address
    mapping(uint256 => address) private _tokenOwners;
    /// @dev Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenOperators;
    /// @dev Mapping from token ID to whether it has been burned
    mapping(uint256 => bool) private _burnedTokens;
    /// @dev Mapping owner address to token count
    mapping(address => uint256) private _balances;
    /// @dev Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operators;

    /// @dev Token name
    string private _name;
    /// @dev Token symbol
    string private _symbol;

    /// @dev Base URI for computing {tokenURI}.
    string private _baseURI;

    /// @dev Count NFTs tracked
    uint256 internal _nextTokenId;
    /// @dev Firts NFTs
    uint256 private _startingTokenId;
    /// @dev Count NFTs burned
    uint256 private _burnCounter;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external {
        address owner = ownerOf(_tokenId);
        if (owner != msg.sender && !_operators[owner][msg.sender] && _tokenOperators[_tokenId] != msg.sender)
            revert CallerNotOwnerOrApprovedOperator();

        if (!_unorderedOwner[_tokenId]) {
            _tokenOwners[_tokenId] = owner;
            _unorderedOwner[_tokenId] = true;
        }
        _tokenOperators[_tokenId] = _approved;

        emit Approval(msg.sender, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        _operators[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Name for NFTs in this contract
    function name() external view returns (string memory) {
        return _name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @notice Base URI for computing {tokenURI}
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view virtual returns (string memory) {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        return bytes(_baseURI).length > 0 ? string.concat(_baseURI, toString(_tokenId)) : "";
    }


    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) revert QueryBalanceOfZeroAddress();
        return _balances[_owner];
    }

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return _nextTokenId - _startingTokenId - _burnCounter;
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address) {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        return _tokenOperators[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operators[_owner][_operator];
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public {
        transferFrom(_from, _to, _tokenId);
        if (_to.code.length > 0) {
            _checkERC721Received(_from, _to, _tokenId, data);
        }
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        address owner = ownerOf(_tokenId);
        if (owner != _from) revert TokenNotOwnedByFromAddress();
        if (owner != msg.sender && !_operators[_from][msg.sender] && _tokenOperators[_tokenId] != msg.sender)
            revert CallerNotOwnerOrApprovedOperator();
        if (_to == address(0)) revert InvalidTransferToZeroAddress();

        _beforeTokenTransfer(_from, _to, _tokenId);

        _balances[_from] -= 1;
        _balances[_to] += 1;

        _tokenOperators[_tokenId] = address(0);
        _tokenOwners[_tokenId] = _to;
        _unorderedOwner[_tokenId] = true;

        emit Transfer(_from, _to, _tokenId);

        _afterTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view returns (address) {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        if (_burnedTokens[_tokenId]) revert QueryBurnedToken();
        return _unorderedOwner[_tokenId] ? _tokenOwners[_tokenId] : _ownerOf(_tokenId);
    }

    /// @notice Find the owner of an NFT
    /// @dev Does not revert if token is burned, this is used to query via multi-call
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function unsafeOwnerOf(uint256 _tokenId) public view returns (address) {
        if(_burnedTokens[_tokenId]) return address(0);
        return _unorderedOwner[_tokenId] ? _tokenOwners[_tokenId] : _ownerOf(_tokenId);
    }

    /// @notice Same as calling {safeMint} without data
    function safeMint(address _to, uint256 _quantity) internal {
        safeMint(_to, _quantity, "");
    }

    /// @notice Same as calling {_mint} and then checking for IERC721Receiver
    function safeMint(
        address _to,
        uint256 _quantity,
        bytes memory _data
    ) internal {
        _mint(_to, _quantity);
        uint256 currentTokenId = _nextTokenId - 1;
        unchecked {
            if (_to.code.length != 0) {
                uint256 tokenId = _nextTokenId - _quantity - 1;
                do {
                    if (!_checkERC721Received(address(0), _to, ++tokenId, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (tokenId < currentTokenId);
            }
        }
    }

    /// @notice Mint a quantity of NFTs to an address
    /// @dev Saves the first token id minted by the address to a map of
    ///      used to verify ownership initially.
    ///      {_tokenOwnersOrdered} will be used to find the owner unless the token
    ///      has been transfered. In that case, it will be available in {_tokenOwners} instead.
    ///      This is done to reduce gas requirements of minting while keeping on-chain lookups
    ///      cheaper as tokens are transfered around. It helps with the burning of tokens.
    /// @param _to Receiver address
    /// @param _quantity The quantity to be minted
    function _mint(address _to, uint256 _quantity) internal {
        if (_to == address(0)) revert InvalidTransferToZeroAddress();
        if (_quantity == 0) revert MintZeroTokenId();
        unchecked {
            _balances[_to] += _quantity;
            uint256 newTotal = _nextTokenId + _quantity;

            for (uint256 i = _nextTokenId; i < newTotal; i++) {
                emit Transfer(address(0), _to, i);
            }

            _tokenOwnersOrdered[_nextTokenId] = _to;
            _nextTokenId = newTotal;
        }
    }

    /// @notice Same as calling {_burn} without a from address or approval check
    function _burn(uint256 _tokenId) internal {
        _burn(_tokenId, msg.sender);
    }

    /// @notice Same as calling {_burn} without approval check
    function _burn(uint256 _tokenId, address _from) internal {
        _burn(_tokenId, _from, false);
    }

    /// @notice Burn an NFT
    /// @dev Checks ownership of the token
    /// @param _tokenId The token id
    /// @param _from The owner address
    /// @param _approvalCheck Check if the caller is owner or an approved operator
    function _burn(
        uint256 _tokenId,
        address _from,
        bool _approvalCheck
    ) internal {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        address owner = ownerOf(_tokenId);
        if (owner != _from) revert TokenNotOwnedByFromAddress();
        if (_approvalCheck) {
            if (owner != msg.sender && !_operators[_from][msg.sender] && _tokenOperators[_tokenId] != msg.sender)
                revert CallerNotOwnerOrApprovedOperator();
        }

        _balances[_from]--;
        _burnCounter++;
        _burnedTokens[_tokenId] = true;

        _tokenOperators[_tokenId] = address(0);

        emit Transfer(_from, address(0), _tokenId);
    }

    /// @notice Before Token Transfer Hook
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /* solhint-disable no-empty-blocks */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    /* solhint-disable no-empty-blocks */

    /// @notice After Token Transfer Hook
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /* solhint-disable no-empty-blocks */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    /* solhint-disable no-empty-blocks */

    /// @notice Initializer due to this being an upgradeable contract
    /// @dev calls the unchained initializer
    /// @param name_ Name of the contract
    /// @param symbol_ An abbreviated name for NFTs in this contract
    function __ERC721KFNC_init(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal onlyInitializing {
        __ERC721KFNC_init_unchained(name_, symbol_, baseURI_);
    }

    /// @notice Initializer due to this being an upgradeable contract
    /// @param name_ Name of the contract
    /// @param symbol_ An abbreviated name for NFTs in this contract
    function __ERC721KFNC_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _nextTokenId = _startingTokenId = startingTokenId();
    }

     /// @notice Used to set the baseURI for metadata
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param baseURI_ The base URI
    function _setBaseURI(string memory baseURI_)
        internal
    {
        _baseURI = baseURI_;
    }

    /// @notice Verify whether a token exists and has not been burned
    /// @param _tokenId The token id
    /// @return bool
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _tokenId >= _startingTokenId && _tokenId < _nextTokenId && !_burnedTokens[_tokenId];
    }

    /// @notice Number to use as the first token id
    /// @dev Overridable by implementing contract
    function startingTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /// @notice Used to change a token id uint256 into string
    /// @param value The number to change
    /// @return string
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OpenZeppelin's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /// @notice Checking if the receiving contract implements IERC721Receiver
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /// @param _data Extra data
    function _checkERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool)
    {
        try IERC721KFNCReceiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721KFNCReceiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /// @notice Find the owner of an NFT
    /// @dev This function should only be called from {ownerOf(_tokenId)}
    ///      This iterates through the original minters since they are ordered
    ///      If an owner is address(0), it keeps looking for the owner by checking the
    ///      previous tokens. If minter A minted 10, then the first token will have the address
    ///      and the rest will have address(0)
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function _ownerOf(uint256 _tokenId) private view returns (address) {
        uint256 curr = _tokenId;
        unchecked {
            address owner = address(0);
            while (owner == address(0)) {
                if (!_unorderedOwner[curr]) {
                    owner = _tokenOwnersOrdered[curr];
                }
                curr--;
            }
            return owner;
        }
    }
}
