// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract NFT is ERC721Enumerable, AccessControl {
    using SafeMath for uint256;

    string private _baseTokenURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    mapping(uint256 => bytes1) private _nftType;

    constructor() ERC721("ISLANDverse", "IVERSE") {
        _baseTokenURI = "https://raw.githubusercontent.com/islanddoges/nfts/master/";
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function grantMinter(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Onlyowner");

        grantRole(MINTER_ROLE, account);
    }

    function grantBurner(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Onlyowner");

        grantRole(BURNER_ROLE, account);
    }

    function revokeMinter(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Onlyowner");

        revokeRole(MINTER_ROLE, account);
    }

    function revokeBurner(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Onlyowner");

        revokeRole(BURNER_ROLE, account);
    }

    function minterMint(address account, bytes1 nft_type) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Onlyminter");

        uint256 _curr = totalSupply();
        _safeMint(account, _curr);
        _nftType[_curr] = nft_type;
    }

    function burnerBurn(uint256 index) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Onlyburner");

        _burn(index);
    }

    function getType(uint256 index) public view returns (bytes1) {
        return _nftType[index];
    }

    function setType(uint256 index, bytes1 nft_type) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Onlyowner");

        _nftType[index] = nft_type;
    }

    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Onlyowner");

        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}
