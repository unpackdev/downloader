// File: openzeppelin-contracts-master/contracts/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "./ERC1155Upgradeable.sol";

contract FomoNFT1155 is ERC1155Upgradeable {
    event Supply(uint256 indexed tokenId, uint256 value);
    event Creators(uint256 indexed tokenId, address indexed value);

    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public supply;
    mapping(uint256 => uint256) public minted;
    mapping(uint256 => string) private tokenURIs;

    function initialize(string memory _uri) public initializer {
        __ERC1155_init(_uri);
        __ERC1155_init_unchained(_uri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        uint256 maximum,
        string memory tokenUri,
        bytes memory data
    ) external returns (uint256) {
        require(maximum > 0, "supply incorrect");
        require(amount > 0, "amount incorrect");

        if (supply[id] == 0) {
            _saveSupply(id, maximum);
            _saveCreator(id, _msgSender());
        }

        uint256 newMinted = amount.add(minted[id]);
        require(newMinted <= supply[id], "more than supply");
        minted[id] = newMinted;

        require(creators[id] == _msgSender(), "different creator");

        _setTokenURI(id, tokenUri);
        _mint(account, id, amount, data);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return tokenURIs[tokenId];
    }

    function _saveSupply(uint256 _tokenId, uint256 _supply) internal {
        require(supply[_tokenId] == 0);
        supply[_tokenId] = _supply;
        emit Supply(_tokenId, _supply);
    }

    function _saveCreator(uint256 _tokenId, address _creator) internal {
        creators[_tokenId] = _creator;
        emit Creators(_tokenId, _creator);
    }

    function _setTokenURI(uint256 tokenId, string memory tokenUri) internal virtual {
        tokenURIs[tokenId] = tokenUri;
    }
}
