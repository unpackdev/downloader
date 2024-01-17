// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";
import "./Math.sol";
import "./Counters.sol";

contract MonoCats is ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public constant imageHash = '080a47b46e0507ea40d250e3f06330a870b23301f1178fe195376b14c5fb15b1';

    bytes32 private constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 private constant INCREASE_CATS_ROLE = keccak256('INCREASE_CATS_ROLE');

    uint256 public constant MAX_CATS = 2000;
    uint256 public constant MAX_MINT_ONCE = 20;

    string private _baseTokenURI;

    mapping(address => uint256) private userCatsNumberOnFlow;

    event IncreaseCatsNumberEvent(address addr, uint256 num);
    event MintEvent(address addr, uint256 tokenId);

    constructor(
        address admin,
        address increase,
        string memory baseURI
    ) ERC721('MonoCats: Evolved!', 'MCAT') {
        _setupRole(ADMIN_ROLE, admin);
        _setupRole(INCREASE_CATS_ROLE, increase);
        _baseTokenURI = baseURI;
    }

    function setBaseURI(string memory baseURI) external {
        require(hasRole(ADMIN_ROLE, msg.sender), 'must have admin role');
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return
            'https://static.mono.fun/public/contents/projects/a73c1a41-be88-4c7c-a32e-929d453dbd39/nft/monocatsv2/MonoCatsv2.json';
    }

    function increaseCatsNumber(address[] calldata addrs, uint256[] calldata nums) external {
        require(hasRole(INCREASE_CATS_ROLE, msg.sender), 'must have increase role');
        for (uint256 i = 0; i < addrs.length; i++) {
            _increaseCatsNumber(addrs[i], nums[i]);
        }
    }

    function _increaseCatsNumber(address addr, uint256 num) internal {
        userCatsNumberOnFlow[addr] = userCatsNumberOnFlow[addr] + num;

        emit IncreaseCatsNumberEvent(addr, num);
    }

    function getUserCatsNumber() public view returns (uint256) {
        return userCatsNumberOnFlow[msg.sender];
    }

    function mint() public {
        address to = msg.sender;
        require(userCatsNumberOnFlow[to] >= 5, 'must have 5 above cats on flow to mint a cat');
        require(_tokenIds.current() < MAX_CATS, 'tokenID out of range');
        uint256 maxMint = userCatsNumberOnFlow[to] / 5;

        for (uint256 i = 0; i < Math.min(maxMint, MAX_MINT_ONCE); i++) {
            if (_tokenIds.current() < MAX_CATS) {
                userCatsNumberOnFlow[to] = userCatsNumberOnFlow[to] - 5;
                _safeMint(to, _tokenIds.current());
                emit MintEvent(to, _tokenIds.current());
                _tokenIds.increment();
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
