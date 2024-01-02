// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IERC721A.sol";
import "./String.sol";
import "./Roles.sol";

bytes32 constant _TRANSFER_EVENT_SIGNATURE =
0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

interface ERC721A__IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

abstract contract ERC721 is IERC721A {
  using String for uint256;

  error NotOwner();
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  struct TokenApprovalRef {
    address value;
  }

  address public owner;

  mapping(address => uint256) private _balance;
  mapping(uint256 => address) internal _owner;
  mapping(uint256 => TokenApprovalRef) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  string public constant name = 'KingdomTiles';
  string public constant symbol = 'KT';

  string internal _baseURI;

  modifier onlyOwner() {
    if (msg.sender != owner) {
      _revert(NotOwner.selector);
    }
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function tokenURI(uint256 tokenId) external view returns(string memory) {
    string memory extra = _owner[tokenId] == address(this) ? "_ccip" : "";
    return string(abi.encodePacked(_baseURI, tokenId.toString(), extra, ".json"));
  }

  function balanceOf(address tokenOwner) external view returns(uint256) {
    return _balance[tokenOwner];
  }

  function ownerOf(uint256 tokenId) external view returns(address) {
    return _owner[tokenId];
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    if (!_exists(tokenId)) _revert(ApprovalQueryForNonexistentToken.selector);

    return _tokenApprovals[tokenId].value;
  }

  function isApprovedForAll(address tokenOwner, address operator) public view returns (bool) {
    return _operatorApprovals[tokenOwner][operator];
  }

  function approve(address to, uint256 tokenId) public payable {
    address tokenOwner = _owner[tokenId];

    if (msg.sender != tokenOwner)
      if (!isApprovedForAll(tokenOwner, msg.sender)) {
        _revert(ApprovalCallerNotOwnerNorApproved.selector);
      }

    _tokenApprovals[tokenId].value = to;
    emit Approval(tokenOwner, to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public {
    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable {
    address prevOwner = _owner[tokenId];

    if (prevOwner != from) _revert(TransferFromIncorrectOwner.selector);

    (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

    // The nested ifs save around 20+ gas over a compound boolean condition.
    if (msg.sender != from)
      if (msg.sender != approvedAddress)
        if (!_operatorApprovals[from][msg.sender]) _revert(TransferCallerNotOwnerNorApproved.selector);

    // Clear approvals from the previous owner.
    assembly {
      if approvedAddress {
      // This is equivalent to `delete _tokenApprovals[tokenId]`.
        sstore(approvedAddressSlot, 0)
      }
    }

    unchecked {
      --_balance[from]; // Updates: `balance -= 1`.
      ++_balance[to]; // Updates: `balance += 1`.

      _owner[tokenId] = to;
    }

    // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
    assembly {
    // Emit the `Transfer` event.
      log4(
        0, // Start of data (0, since no data).
        0, // End of data (0, since no data).
        _TRANSFER_EVENT_SIGNATURE, // Signature.
        from, // `from`.
        to, // `to`.
        tokenId // `tokenId`.
      )
    }
    if (to == address(0)) _revert(TransferToZeroAddress.selector);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable {
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public payable {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0)
      if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
        _revert(TransferToNonERC721ReceiverImplementer.selector);
      }
  }

  function transferOwnership(address newOwner) external onlyOwner {
    owner = newOwner;
    emit OwnershipTransferred(msg.sender, newOwner);
  }

  function _setBaseURI(string calldata uri) internal virtual {
    _baseURI = uri;
  }

  function _mint(address to, uint256 tokenId) internal virtual {
    _owner[tokenId] = to;
    unchecked {
      _balance[to] += 1;
    }
    if (to == address(0)) _revert(MintToZeroAddress.selector);

    assembly {
      log4(
        0,
        0,
        _TRANSFER_EVENT_SIGNATURE, // Signature.
        0,
        to,
        tokenId
      )
    }
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);

    unchecked {
      if (to.code.length != 0) {
        if (!_checkContractOnERC721Received(address(0), to, tokenId, _data)) {
          _revert(TransferToNonERC721ReceiverImplementer.selector);
        }
      }
    }
  }

  /**
   * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, '');
  }

  function _revert(bytes4 errorSelector) internal pure {
    assembly {
      mstore(0x00, errorSelector)
      revert(0x00, 0x04)
    }
  }

  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try ERC721A__IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (
      bytes4 retval
    ) {
      return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        _revert(TransferToNonERC721ReceiverImplementer.selector);
      }
      assembly {
        revert(add(32, reason), mload(reason))
      }
    }
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owner[tokenId] != address(0);
  }

  function _getApprovedSlotAndAddress(uint256 tokenId)
  private
  view
  returns (uint256 approvedAddressSlot, address approvedAddress)
  {
    TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
    // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
    assembly {
      approvedAddressSlot := tokenApproval.slot
      approvedAddress := sload(approvedAddressSlot)
    }
  }
}
