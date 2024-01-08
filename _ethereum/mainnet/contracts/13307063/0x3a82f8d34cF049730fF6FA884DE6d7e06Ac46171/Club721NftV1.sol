// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";

contract Club721NftV1 is OwnableUpgradeable, ERC721EnumerableUpgradeable {
    // $ sha256sum club721member.mp4
    string public constant provenanceHash = "32821497793b2290db4071bfcacfab4e3e73f143054cce38705abdbc3c9a7c22";
    uint256 public maxMember;
    uint256 public ogCount;

    string public ogURI;
    string public contractURI;
    string public baseURI;

    address public store1;
    address public store2;

    modifier onlyStoreOrOwner() {
        address sender = msg.sender;
        require(store1 == sender || store2 == sender || owner() == sender, 'Club721NFT: caller is not store or owner');
        _;
    }

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained('Club721 membership', 'club721');
        __ERC721Enumerable_init_unchained();

        maxMember = 307;
        ogCount = 307;
        contractURI = "https://ipfs.io/ipfs/QmVtQZv3amc2ra4A2EynD9iD43QKD66fEKiiKXWBappHgH";
        baseURI = "https://ipfs.io/ipfs/QmeLtPiVp6565mGVwtdqhw5AnPKUnsgWn6W8czEiPuoZsd";
        ogURI = "https://ipfs.io/ipfs/QmSqNh26UVnkjtguPa14nVn9nKffkYkUWGVVZocArSZu8Y";
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function mint(address to, uint256 count) external onlyStoreOrOwner {
        uint256 total = totalSupply();
        require(total + count <= maxMember, "Club721NFT: Exceed the max supply");
        for (uint256 i = 0; i < count; i++) {
            _safeMint(to, total + i);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenId < ogCount) {
            return ogURI;
        }
        return baseURI;
    }

    function setMaxMember(uint256 _maxMember) external onlyOwner {
        maxMember = _maxMember;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setOgURI(string calldata _uri) external onlyOwner {
        ogURI = _uri;
    }

    function setOgCount(uint256 _ogCount) external onlyOwner {
        ogCount = _ogCount;
    }

    function setContractURI(string calldata _uri) external onlyOwner {
        contractURI = _uri;
    }

    function setStore1(address _store) external onlyOwner {
        store1 = _store;
    }

    function setStore2(address _store) external onlyOwner {
        store2 = _store;
    }

    function approveERC721(ERC721Upgradeable _nft, address who, bool approved) external onlyOwner {
        _nft.setApprovalForAll(who, approved);
    }

    function approveERC20(IERC20Upgradeable _token, address who, uint256 amount) external onlyOwner {
        _token.approve(who, amount);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
