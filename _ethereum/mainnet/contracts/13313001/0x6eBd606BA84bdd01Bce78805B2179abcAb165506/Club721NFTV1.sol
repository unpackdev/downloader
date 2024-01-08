// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract Club721NFTV1 is OwnableUpgradeable, EIP712Upgradeable, ERC721EnumerableUpgradeable {
    // $ sha256sum club721member.mp4
    string public constant provenanceHash = "32821497793b2290db4071bfcacfab4e3e73f143054cce38705abdbc3c9a7c22";
    bytes32 public constant MINT_CALL_HASH_TYPE = keccak256("mint(address receiver,uint256 maxMember)");

    uint256 public maxMember;
    uint256 public ogCount;

    string public ogURI;
    string public contractURI;
    string public baseURI;

    address public clubSigner;
    bool public paused;

    mapping(bytes32 => bool) public digestUsed;

    modifier whenNotPaused() {
        require(!paused, "Club721NFT: paused");
        _;
    }

    function initialize(address _newOwner) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __EIP712_init_unchained('Club721NFT', '1');
        __ERC165_init_unchained();
        __ERC721_init_unchained('Club721 Membership', 'Club721');
        __ERC721Enumerable_init_unchained();

        paused = true;
        clubSigner = 0xaAE9B47610c7bEB41CDe4e6897C82F5181AF5fBE;
        maxMember = 307;
        ogCount = 307;
        contractURI = "https://infura-ipfs.io/ipfs/QmVtQZv3amc2ra4A2EynD9iD43QKD66fEKiiKXWBappHgH";
        baseURI = "https://infura-ipfs.io/ipfs/QmeLtPiVp6565mGVwtdqhw5AnPKUnsgWn6W8czEiPuoZsd";
        ogURI = "https://infura-ipfs.io/ipfs/QmSqNh26UVnkjtguPa14nVn9nKffkYkUWGVVZocArSZu8Y";

        _mint(0x8c0d2B62F133Db265EC8554282eE60EcA0Fd5a9E, 0);
        _mint(0x0D342C14B14044bff092418B1D05e2Ab8aB61c11, 1);
        _mint(0x8c0d2B62F133Db265EC8554282eE60EcA0Fd5a9E, 2);
        _mint(0x1E57e21CC3de9407749edA5Bfc544eB7c58da9d2, 3);
        _mint(0x0dee503261FA153BC9372f5b201C56Ead3b33721, 4);
        _mint(0x142ec4245e4e64b975FD0A5596BE8AbcC0378888, 5);
        _mint(0x11D3D7a8E98e25081fA16D5660ADab6eB3952999, 6);

        transferOwnership(_newOwner);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function mint(bytes memory signature) external whenNotPaused {
        uint256 total = totalSupply();
        require(total + 1 <= maxMember, "Club721NFT: Exceed the max supply");
        address sender = msg.sender;
        bytes32 digest = getDigestWithPrefix(sender);
        require(!digestUsed[digest], "Club721NFT: digest used");
        address _signer = ECDSAUpgradeable.recover(digest, signature);
        require(clubSigner == _signer, "Club721NFT: Invalid signer");
        digestUsed[digest] = true;
        _safeMint(sender, total);
    }

    function getDigestWithPrefix(address sender) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", getDigest(sender)));
    }

    function getDigest(address sender) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MINT_CALL_HASH_TYPE, sender, maxMember)));
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

    function ownerMint(address to, uint256 count) public onlyOwner {
        require(count > 0, "Club721NFT: Mint zero nft");
        uint256 total = totalSupply();
        require(total + count <= maxMember, "Club721NFT: Exceed the max supply");
        for (uint256 i = 0; i < count; i++) {
            _mint(to, total + i);
        }
    }

    function doPause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function setSigner(address _signer) external onlyOwner {
        clubSigner = _signer;
    }

    function setMaxMember(uint256 _maxMember) external onlyOwner {
        maxMember = _maxMember;
    }

    function setOgCount(uint256 _ogCount) external onlyOwner {
        ogCount = _ogCount;
    }

    function setOgURI(string calldata _uri) external onlyOwner {
        ogURI = _uri;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setContractURI(string calldata _uri) external onlyOwner {
        contractURI = _uri;
    }

    function approveERC721(IERC721Upgradeable _nft, address who, bool approved) external onlyOwner {
        _nft.setApprovalForAll(who, approved);
    }

    function approveERC20(IERC20Upgradeable _token, address who, uint256 amount) external onlyOwner {
        _token.approve(who, amount);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
