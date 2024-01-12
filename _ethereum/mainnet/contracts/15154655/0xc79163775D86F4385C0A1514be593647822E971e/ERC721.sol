// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety; 1 yeet = 1 yeet
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint256 gnssId;
    }

    mapping(uint256 => TokenOwnership) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => bool) private _gnssTracker;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
    }

    function _gnssExists(uint256 gnssId) external view returns (bool) {
        return _gnssTracker[gnssId];
    }

    function gnssFromYNSS(uint256 ynssId) external view returns (uint256) {
        require(_exists(ynssId), "n/e");

        return _owners[ynssId].gnssId;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < _totalSupply, "g");
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), "b");

        uint256 tokenIdsIdx = 0;
//        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < _totalSupply; i++) {
            TokenOwnership memory ownership = _owners[i];
//            if (ownership.addr != address(0)) {
//                currOwnershipAddr = ownership.addr;
//            }
//            if (currOwnershipAddr == owner) {
//                if (tokenIdsIdx == index) {
//                    return i;
//                }
//                tokenIdsIdx++;
//            }
            if (ownership.addr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "0");
        return _balances[owner];
    }

    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        require(_exists(tokenId), "t");

//        uint256 lowestTokenToCheck;
//        if (tokenId >= maxBatchSize) {
//            lowestTokenToCheck = tokenId - maxBatchSize + 1;
//        }
//
//        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
//            TokenOwnership memory ownership = _owners[curr];
//            if (ownership.addr != address(0)) {
//                return ownership;
//            }
//        }

        return _owners[tokenId];

//        revert("o");
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {}

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "o");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "a"
        );

        _approve(to, tokenId, owner);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "a");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), "a");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "z"
        );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _totalSupply;
    }

    function _safeMint(address to, uint256[] memory gnssIds) internal {
        _safeMint(to, gnssIds, "");
    }

    function _safeMint(
        address to,
        uint256[] memory gnssIds,
        bytes memory _data
    ) internal {
        uint256 quantity = gnssIds.length;
        uint256 startTokenId = _totalSupply;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "a");
//        require(quantity <= maxBatchSize, "m");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

//        AddressData memory addressData = _addressData[to];
//        _addressData[to] = AddressData(
//            addressData.balance + uint128(quantity),
//            addressData.numberMinted + uint128(quantity)
//        );

        _balances[to] += quantity;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            require(!(this._gnssExists(gnssIds[i])), "gnss already converted");
            _owners[updatedIndex] = TokenOwnership(to, gnssIds[i]);
            _gnssTracker[gnssIds[i]] = true;
            emit Transfer(address(0), to, updatedIndex);
            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                "z"
            );
            updatedIndex++;
        }
        //        updatedIndex += quantity;

        _totalSupply = updatedIndex;
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
        getApproved(tokenId) == _msgSender() ||
        isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(isApprovedOrOwner, "a");

        require(prevOwnership.addr == from, "o");
        require(to != address(0), "0");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

//        _addressData[from].balance -= 1;
//        _addressData[to].balance += 1;
//        _owners[tokenId] = TokenOwnership(to, uint64(block.timestamp));
//
//        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
//        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
//        uint256 nextTokenId = tokenId + 1;
//        if (_owners[nextTokenId].addr == address(0)) {
//            if (_exists(nextTokenId)) {
//                _owners[nextTokenId] = TokenOwnership(prevOwnership.addr, prevOwnership.startTimestamp);
//            }
//        }
        
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId].addr = to;

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

////////////////////////////////////////



















