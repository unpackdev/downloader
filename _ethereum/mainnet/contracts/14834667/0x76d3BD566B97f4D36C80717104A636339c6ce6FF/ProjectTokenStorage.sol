// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165P.sol";
import "./Counters.sol";
pragma abicoder v2;

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ProjectTokenStorage is ERC165P {
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 public constant _ERC721_RECEIVED = 0x150b7a02;

    address public _owner;

    // Token name
    string public _name;

    // Token symbol
    string public _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) public _tokenURIs;

    // Base URI
    string public _baseURI;

    // Mapping from token ID to owner
    mapping (uint256 => address) public _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) public _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) public _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) public _operatorApprovals;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) public _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) public _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] public _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) public _allTokensIndex;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 public constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 public constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    bool public pauseProxy;

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

}
