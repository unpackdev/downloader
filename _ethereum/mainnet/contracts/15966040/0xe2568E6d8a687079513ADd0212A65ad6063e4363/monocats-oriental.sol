// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";

contract MonoCatsOrientalYokai is ERC721, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 private constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 private constant INCREASE_CATS_ROLE = keccak256('INCREASE_CATS_ROLE');

    uint256 public constant MAX_CATS = 12;

    string private _baseTokenURI;

    struct userCats {
        address addr;
        uint256[] catIds;
    }

    mapping(address => EnumerableSet.UintSet) private userCatIdsOnFlow;

    event AddCatsIdEvent(address addr, uint256 ids);
    event MintEvent(address addr, uint256 tokenId);

    constructor(
        address admin,
        address increase,
        string memory baseURI
    ) ERC721(unicode'MonoCats: Oriental Yōkai', 'MCOY') {
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
            'https://static.mono.fun/public/contents/projects/a73c1a41-be88-4c7c-a32e-929d453dbd39/nft/monocatsv2/MonoCatsv2_Yokai.json';
    }

    function addUserCatIds(userCats[] calldata _userCats) external {
        require(hasRole(INCREASE_CATS_ROLE, msg.sender), 'must have increase role');
        for (uint256 i = 0; i < _userCats.length; i++) {
            address addr = _userCats[i].addr;
            uint256[] memory catIds = _userCats[i].catIds;
            for (uint256 j = 0; j < _userCats[i].catIds.length; j++) {
                EnumerableSet.add(userCatIdsOnFlow[addr], catIds[j]);
                emit AddCatsIdEvent(addr, catIds[j]);
            }
        }
    }

    function getUserCatsIds() public view returns (uint256[] memory) {
        return EnumerableSet.values(userCatIdsOnFlow[msg.sender]);
    }

    function mint() public {
        address to = msg.sender;
        require(userCatIdsOnFlow[to].length() > 0, unicode'must have Oriental Yōkai cats on flow to mint a cat');
        for (uint256 i = 0; i < userCatIdsOnFlow[to].length(); i++) {
            uint256 tokenId = EnumerableSet.at(userCatIdsOnFlow[to], i);
            EnumerableSet.remove(userCatIdsOnFlow[msg.sender], tokenId);

            _safeMint(msg.sender, tokenId);

            emit MintEvent(msg.sender, tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
