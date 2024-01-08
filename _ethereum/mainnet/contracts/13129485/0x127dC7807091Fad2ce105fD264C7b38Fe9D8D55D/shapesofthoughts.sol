// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";

contract ShapesOfThoughts is ERC721, Ownable {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 private constant TOKENS_COUNT = 4;
    uint256 private constant THOUGHT_LIMIT = 140;

    uint256[TOKENS_COUNT] private _CHARACTER_LIMITS = [1962, 1728, 1870, 1856];

    address public payoutAddress;

    string[] private _thoughts;
    uint256[] private _thoughtsTokenIds;

    mapping(uint256 => uint256) private _tokenCharacters;

    constructor() ERC721("Shapes of thoughts", "STHGTS") {
        payoutAddress = msg.sender;

        for (uint i = 1; i <= TOKENS_COUNT; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function addThought(string calldata thought, uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");

        bytes memory thoughtBytes = bytes(thought);
        require(thoughtBytes.length <= THOUGHT_LIMIT && thoughtBytes.length >= 1, "Invalid length");
        require((_tokenCharacters[tokenId] + thoughtBytes.length) <= _CHARACTER_LIMITS[tokenId - 1], "Too long");

        for (uint i; i < thoughtBytes.length; i++) {
            uint c = uint8(thoughtBytes[i]);
            require(
                (c >= 97 && c <= 122) // a-z
                || (c >= 32 && c <= 64) // special
            , "Invalid character");
        }

        _thoughts.push(thought);
        _thoughtsTokenIds.push(tokenId);
        _tokenCharacters[tokenId] += thoughtBytes.length;
    }

    function getThoughts() public view returns (string[] memory) {
        return _thoughts;
    }

    function getThoughtsTokenIds() public view returns (uint256[] memory) {
        return _thoughtsTokenIds;
    }

    function updatePayoutAddress(address newPayoutAddress) public onlyOwner {
        payoutAddress = newPayoutAddress;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 amount) {
        uint256 fivePercent = SafeMath.div(SafeMath.mul(salePrice, 500), 10000);
        return (payoutAddress, fivePercent);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://swark.art/api/shapesofthoughts/";
    }
}
