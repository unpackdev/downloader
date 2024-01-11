// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./ERC721AUpgradeable.sol";
import "./MerkleProof.sol";

import "./console.sol";

interface ICloneFactory {
    function getProtocolFeeAndRecipient(address _contract) external view returns (uint256, address);
}

/**
Can have to up 1,10000 tokenIds whitelisted
 */
contract PhantomAirdropWhitelist is Initializable, ERC721AUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for string;
    using AddressUpgradeable for address;

    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;
    uint256 private constant BITPOS_NUMBER_MINTED = 64;
    uint256 private constant BITMASK_BURNED = 1 << 224;
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
    string public baseExtension;

    IERC721 public parent;
    bool public isRevealed;
    bool public isSelectiveAirdrop;
    string public baseURI;
    ICloneFactory public immutable cloneFactory;
    uint256 public START_INDEX;

    uint256[] public _airdropBitmask;

    constructor(address _cloneFactory) {
        require(_cloneFactory.isContract(), "CloneFactory: _cloneFactory is not a contract");
        cloneFactory = ICloneFactory(_cloneFactory);
    }

    function initialize(
        address payable _owner,
        string[] memory _stringData,
        uint256[] memory _uintData,
        bool[] memory _boolData,
        address[] memory _addressData
    ) external initializerERC721A initializer {
        require(_stringData.length == 4, "Missing string data (name, symbol, baseURI, baseExtension)");
        require(
            _uintData.length >= 2,
            "Missing integer data (tokenIDstartIndex, tokenIDendIndex, 40 other whitelist numbers)"
        );
        require(_boolData.length == 2, "Missing bool data (isRevealed, isSelctiveAirdrop)");
        require(_addressData.length == 1, "Missing address data (parent)");
        require(_uintData[1] >= _uintData[0]);
        __Ownable_init_unchained();

        START_INDEX = _uintData[0];
        // currentIndex needs to stay fixed throughout the contract, acts as Max_supply
        ERC721AStorage.layout()._packedAddressData[_owner] +=
            (_uintData[1] - _uintData[0] + 1) *
            ((1 << BITPOS_NUMBER_MINTED) | 1);

        baseExtension = _stringData[3];
        baseURI = _stringData[2];
        __ERC721A_init(_stringData[0], _stringData[1]);
        ERC721AStorage.layout()._currentIndex = _uintData[1] + 1;
        isSelectiveAirdrop = _boolData[1];
        isRevealed = _boolData[0];
        if (isSelectiveAirdrop && _uintData.length > 2) {
            for (uint256 i = 0; i < _uintData.length - 2; i++) {
                _airdropBitmask.push(_uintData[i + 2]);
            }
        }
        parent = IERC721(_addressData[0]); //asumption that parent contract is enumerated and has no burns
        transferOwnership(_owner);
    }

    /*
     * This function creates a whitelist of tokenIds up 10k tokenIds
     */
    function setAirdropBitmask(uint256[] memory _bitmask) public onlyOwner {
        require(isSelectiveAirdrop, "Contract is not selective airdrop mode.");
        for (uint256 i = 0; i < _bitmask.length; i++) {
            _airdropBitmask[i] = _bitmask[i];
        }
    }

    function isValidTokenId(uint256 tokenId) public view returns (bool) {
        require(isSelectiveAirdrop, "Contract is not selective airdrop mode.");
        uint256 depth = tokenId / 256;
        uint256 layerBitmask = _airdropBitmask[depth];
        uint256 bitMask = 1 << (tokenId % 256);
        return ((layerBitmask | bitMask) == layerBitmask);
    }

    /*
     * WARNING: DO NOT CALL FROM OTHER CONTRACT
     *
     */
    function totalSupply() external view override(ERC721AUpgradeable) returns (uint256) {
        uint256 _totalSupply = 0;
        for (uint256 i = _startTokenId(); i <= ERC721AStorage.layout()._currentIndex; i++) {
            address q = address(uint160(_packedOwnershipOf(i)));
            if (q != address(0)) {
                if (isSelectiveAirdrop) {
                    if (isValidTokenId(i)) {
                        _totalSupply++;
                    }
                } else {
                    _totalSupply++;
                }
            } else {
                try parent.ownerOf(i) returns (address o) {
                    if (o != address(0)) {
                        if (isSelectiveAirdrop) {
                            if (isValidTokenId(i)) {
                                _totalSupply++;
                            }
                        } else {
                            _totalSupply++;
                        }
                    }
                } catch (bytes memory) {
                    continue;
                }
            }
        }
        return _totalSupply;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return START_INDEX;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice This function emits an event that is listened to by NFT
     *         marketplaces and allows for the entire collection to be
     *         available and viewed even before ownership of tokens is
     *         written to as per common ERC implementation.
     * @dev True ownership is determined by our parent collection
     *         interface until a transaction decouples ownership
     *         of this child token from the parent token.
     */
    function initialize2309(uint256 _start, uint256 _end) public virtual onlyOwner {
        emit ConsecutiveTransfer(_start, _end, address(0x0), address(this));
    }

    function initializeToOwnersEnumerated(uint256 _start, uint256 _end) public virtual onlyOwner {
        require(_end >= _start, "Ending index must be geq than start index");
        for (uint256 i = _start; i <= _end; i++) {
            try parent.ownerOf(i) returns (address _owner) {
                emit Transfer(address(0x0), _owner, i);
            } catch Error(string memory) {
                continue;
            }
        }
    }

    function initializeToOwnersNonEnumerated(uint256[] calldata _tokenIds, address[] calldata _accounts)
        public
        virtual
        onlyOwner
    {
        require(_tokenIds.length == _accounts.length, "");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            //address q = parent.ownerOf(_tokenIds[i]);
            emit Transfer(address(0x0), _accounts[i], _tokenIds[i]);
        }
        // revert
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return
            isRevealed
                ? (
                    bytes(baseURI).length > 0
                        ? string(abi.encodePacked(baseURI, StringsUpgradeable.toString(_tokenId), baseExtension))
                        : ""
                )
                : string(abi.encodePacked(baseURI));
    }

    function reveal(string memory _revealedURI) external onlyOwner {
        require(!isRevealed, "Already revealed.");
        baseURI = _revealedURI;
        isRevealed = true;
    }

    function getLocalStorageBalance(address _owner) public view virtual returns (uint256) {
        return ERC721AStorage.layout()._packedAddressData[_owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /*
     * WARNING: DO NOT CALL FROM OTHER CONTRACT
     *
     */
    function balanceOf(address _owner) public view virtual override(ERC721AUpgradeable) returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = _startTokenId(); i <= ERC721AStorage.layout()._currentIndex; i++) {
            address q = address(uint160(_packedOwnershipOf(i)));
            if (q != address(0)) {
                if (q == _owner) {
                    if (isSelectiveAirdrop) {
                        if (isValidTokenId(i)) {
                            balance++;
                        }
                    } else {
                        balance++;
                    }
                }
            } else {
                try parent.ownerOf(i) returns (address o) {
                    if (o == _owner && o != address(0)) {
                        if (isSelectiveAirdrop) {
                            if (isValidTokenId(i)) {
                                balance++;
                            }
                        } else {
                            balance++;
                        }
                    }
                } catch (bytes memory) {}
            }
        }
        return balance;
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721AUpgradeable) returns (address) {
        require(
            _startTokenId() <= tokenId && tokenId < ERC721AStorage.layout()._currentIndex,
            "ERC721: approved query for nonexistent token"
        );
        // If the address has been written to storage use the stored address
        if (isSelectiveAirdrop) {
            require(isSelectiveAirdrop && isValidTokenId(tokenId), "ERC721: approved query for nonexistent token");
        }

        address q = address(uint160(_packedOwnershipOf(tokenId)));
        if (q != address(0)) {
            return q;
        } else {
            return parent.ownerOf(tokenId);
        }
        // Fallback to use owner of the token that it was migrated from
    }

    function _packedOwnershipOf(uint256 tokenId) internal view virtual override returns (uint256) {
        uint256 curr = tokenId;
        //console.log("Queying for tokenID", tokenId);
        unchecked {
            if (_startTokenId() <= curr) {
                uint256 packed = ERC721AStorage.layout()._packedOwnerships[curr];

                return packed;
            }
        }

        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721AUpgradeable) {
        // call the new ownerOf function

        uint256 prevOwnershipPacked = uint256(uint160(ownerOf(tokenId)));

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        // We can directly increment and decrement the balances.
        // not set
        unchecked {
            //}
            //
            // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                to,
                BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            emit Transfer(from, to, tokenId);
            _afterTokenTransfers(from, to, tokenId, 1);
        }
        //
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721AUpgradeable) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 _tokenId) public view override(ERC721AUpgradeable) returns (address) {
        if (!_exists(_tokenId)) revert ApprovalQueryForNonexistentToken();

        return ERC721AStorage.layout()._tokenApprovals[_tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721AUpgradeable) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            _interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            _interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            _interfaceId == type(IERC721Enumerable).interfaceId; // ERC165 interface ID for IERC721Enumerable.
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return ERC721AStorage.layout()._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721AUpgradeable) {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        ERC721AStorage.layout()._operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address _to, uint256 _tokenId) public override(ERC721AUpgradeable) {
        address owner = ownerOf(_tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        ERC721AStorage.layout()._tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /*
     * WARNING: DO NOT CALL FROM OTHER CONTRACT
     *
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _targetIndex) external view returns (uint256) {
        uint256 currIndex = 0;
        for (uint256 i = _startTokenId(); i <= ERC721AStorage.layout()._currentIndex; i++) {
            address q = address(uint160(_packedOwnershipOf(i)));
            if (q != address(0)) {
                if (q == _owner) {
                    if (isSelectiveAirdrop) {
                        if (isValidTokenId(i)) {
                            if (currIndex == _targetIndex) {
                                return i;
                            }
                            currIndex++;
                        }
                    } else {
                        if (currIndex == _targetIndex) {
                            return i;
                        }
                        currIndex++;
                    }
                }
            } else {
                try parent.ownerOf(i) returns (address o) {
                    if (o == _owner) {
                        if (isSelectiveAirdrop) {
                            if (isValidTokenId(i)) {
                                if (currIndex == _targetIndex && o != address(0)) {
                                    return i;
                                }
                                currIndex++;
                            }
                        } else {
                            if (currIndex == _targetIndex && o != address(0)) {
                                return i;
                            }
                            currIndex++;
                        }
                    }
                } catch (bytes memory) {
                    continue;
                }
            }
        }
        revert();
    }

    /*
     * WARNING: DO NOT CALL FROM OTHER CONTRACT
     *
     */
    function tokenByIndex(uint256 _targetIndex) external view returns (uint256) {
        uint256 currIndex = 0;
        for (uint256 i = _startTokenId(); i <= ERC721AStorage.layout()._currentIndex; i++) {
            address q = address(uint160(_packedOwnershipOf(i)));
            if (q != address(0)) {
                if (isSelectiveAirdrop) {
                    if (isValidTokenId(i)) {
                        if (currIndex == _targetIndex) {
                            return i;
                        }
                        currIndex++;
                    }
                } else {
                    if (currIndex == _targetIndex) {
                        return i;
                    }
                    currIndex++;
                }
            } else {
                try parent.ownerOf(i) returns (address o) {
                    if (isSelectiveAirdrop) {
                        if (isValidTokenId(i)) {
                            if (currIndex == _targetIndex && o != address(0)) {
                                return i;
                            }
                            currIndex++;
                        }
                    } else {
                        if (currIndex == _targetIndex && o != address(0)) {
                            return i;
                        }
                        currIndex++;
                    }
                } catch (bytes memory) {
                    continue;
                }
            }
        }
        revert();
    }
}
