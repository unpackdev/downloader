// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./draft-IERC6093.sol";
import "./Strings.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./ArrayUtils.sol";

/**
 * @title ERC721MintboundPartitioned
 * @author Aaron Hanson <coffee.becomes.code@gmail.com> @CoffeeConverter
 * @notice https://nftcoffee.dev/
 */
contract ERC721MintboundPartitioned is Context, ERC165, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    error CannotApproveSoulboundToken();
    error CannotTransferSoulboundToken();
    error ExceedsPartitionSize();
    error InvalidPartitionId();
    error InvalidPartitionSize();

    uint256 private constant MAX_PARTITION_SIZE = 2**255 - 1; // largest that allows for two partitions
    uint256 public immutable PARTITION_SIZE;
    uint256 public immutable PARTITION_MAX_ID;

    string private NAME;
    string private SYMBOL;

    string private baseUri;

    mapping (uint256 partitionId => uint256 balance) public partitionBalances;
    mapping (address owner => uint256 balance) private ownerBalances;
    mapping (uint256 tokenId => address owner) private tokenOwners;

    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _partitionSize
    ) {
        NAME = _name;
        SYMBOL = _symbol;
        if (_partitionSize == 0 || _partitionSize > MAX_PARTITION_SIZE) revert InvalidPartitionSize();
        PARTITION_SIZE = _partitionSize;
        PARTITION_MAX_ID = type(uint256).max / _partitionSize - 1;
    }

    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256)
    {
        if (_owner == address(0)) revert ERC721InvalidOwner(address(0));
        return ownerBalances[_owner];
    }

    function ownerOf(
        uint256 _tokenId
    )
        external
        view
        returns (address)
    {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        address tokenOwner = tokenOwners[_tokenId];
        while (tokenOwner == address(0)) {
            tokenOwner = tokenOwners[--_tokenId];
        }
        return tokenOwner;
    }

    function tokenURI(
        uint256 _tokenId
    )
        external
        view
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, _tokenId.toString(), ".json") : "";
    }

    function name()
        external
        view
        returns (string memory)
    {
        return NAME;
    }

    function symbol()
        external
        view
        returns (string memory)
    {
        return SYMBOL;
    }

    function approve(
        address /*_approved*/,
        uint256 /*_tokenId*/
    )
        external
        pure
    {
        revert CannotApproveSoulboundToken();
    }

    function setApprovalForAll(
        address /*_operator*/,
        bool /*_approved*/
    )
        external
        pure
    {
        revert CannotApproveSoulboundToken();
    }

    function safeTransferFrom(
        address /*_from*/,
        address /*_to*/,
        uint256 /*_tokenId*/
    )
        external
        pure
    {
        revert CannotTransferSoulboundToken();
    }

    function safeTransferFrom(
        address /*_from*/,
        address /*_to*/,
        uint256 /*_tokenId*/,
        bytes calldata /*_data*/
    )
        external
        pure
    {
        revert CannotTransferSoulboundToken();
    }

    function transferFrom(
        address /*_from*/,
        address /*_to*/,
        uint256 /*_tokenId*/
    )
        external
        pure
    {
        revert CannotTransferSoulboundToken();
    }

    function getApproved(
        uint256 /*_tokenId*/
    )
        external
        pure
        returns (address)
    {
        return address(0);
    }

    function isApprovedForAll(
        address /*_owner*/,
        address /*_operator*/
    )
        external
        pure
        returns (bool)
    {
        return false;
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC165, IERC165)
        returns (bool)
    {
        return _interfaceId == type(IERC721).interfaceId
            || _interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(_interfaceId);
    }

    function _mint(
        address _to,
        uint256 _partitionId,
        uint256 _amount
    )
        internal
    {
        if (_to == address(0)) revert ERC721InvalidReceiver(address(0));
        if (_amount == 0) return;
        if (_partitionId > PARTITION_MAX_ID) revert InvalidPartitionId();
        uint256 partitionBal = partitionBalances[_partitionId];
        unchecked {
            if (_amount > PARTITION_SIZE - partitionBal) revert ExceedsPartitionSize();
            uint256 firstTokenId = _partitionId * PARTITION_SIZE + partitionBal;
            tokenOwners[firstTokenId] = _to;
            partitionBalances[_partitionId] = partitionBal + _amount;
            ownerBalances[_to] += _amount;
            for (uint t; t < _amount; ++t) emit Transfer(address(0), _to, firstTokenId + t);
        }
    }

    function _mintBatch(
        address _to,
        uint256[] memory _partitionIds,
        uint256[] memory _amounts
    )
        internal
    {
        if (_to == address(0)) revert ERC721InvalidReceiver(address(0));
        uint256 totalMinted;
        for (uint i; i < _partitionIds.length; ++i) {
            uint256 amt = _amounts[i];
            if (amt == 0) continue;
            uint256 partitionId = _partitionIds[i];
            if (partitionId > PARTITION_MAX_ID) revert InvalidPartitionId();
            uint256 partitionBal = partitionBalances[partitionId];
            unchecked {
                if (amt > PARTITION_SIZE - partitionBal) revert ExceedsPartitionSize();
                uint256 firstTokenId = partitionId * PARTITION_SIZE + partitionBal;
                tokenOwners[firstTokenId] = _to;
                partitionBalances[partitionId] = partitionBal + amt;
                for (uint t; t < amt; ++t) emit Transfer(address(0), _to, firstTokenId + t);
                totalMinted += amt;
            }
        }
        unchecked {
            ownerBalances[_to] += totalMinted;
        }
    }

    function _setBaseURI(
        string memory _newBaseUri
    )
        internal
    {
        baseUri = _newBaseUri;
    }

    function _exists(
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        return partitionBalances[_tokenId / PARTITION_SIZE] > _tokenId % PARTITION_SIZE;
    }

    function _baseURI()
        internal
        view
        virtual
        returns (string memory)
    {
        return baseUri;
    }
}
