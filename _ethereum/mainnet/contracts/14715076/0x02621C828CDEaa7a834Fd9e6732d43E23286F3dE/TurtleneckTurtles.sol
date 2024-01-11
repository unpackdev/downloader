// SPDX-License-Identifier: CC0
// Name: Tutleneck Turtles
// Twitter: @turtles_nft

//                                ___-------___
//                            _-~~             ~~-_
//                        _-~                    /~-_
//      /^\__/^\         /~  \                   /    \
//    /|  ♥|| ♥|        /      \_______________/        \
//   | |___||__|      /       /                \          \
//   |          \    /      /                    \          \
//   |   (_______) /______/       TURTLENECK       \_________ \
//   |         / /         \       TURTLES        /            \
//    \ - - - ^  \^\\         \                  /               \     /
//      \         ||           \______________/      _-_       //\__//
//        \       ||------_-~~-_ ------------- \ --/~   ~\    || __/
//          ~-----||====/~     |==================|       |/~~~~~
//           (_(__/  ./     /                    \_\      \.
//                  (_(___/                       \_____) _)  

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

error NormalSaleNotActive();
error WhitelistNotActive();
error ExceededLimit();
error NotEnoughTokensLeft();
error WrongEther();
error InvalidMerkle();
error WhitelistUsed();

contract TurtleneckTurtles is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    using MerkleProof for bytes32[];

    address proxyRegistryAddress;

    bytes32 public merkleRoot = 0x4df31de25999d95cb6375304500b8cc8dddc9801de8cc97d6c6dc95630f47c09;
    uint256 public maxMints = 50;
    uint256 public maxSupply = 100;
    uint256 public mintRate = 0.05 ether;
    uint256 public whitelistMintRate = 0.04 ether;
    string public notRevealedUri = "ipfs://QmewsUNXhCEL2WdNHu4P5EJTTpbi6pKfEpQGvqTUpgKEwa/hidden.json";
    string public baseExtension = ".json";
    string public baseURI = "ipfs://QmdfJd9PuHgT6aNFVBjDu18UyUj2KrNrTmB4ra8BBPuDWA/";
    bool public revealed = true;
    bool public whitelistSale = true;
    bool public normalSale = true;

    mapping(address => uint256) public usedAddresses;

    constructor() ERC721A("TurtleneckTurtles", "TNT") {}

    function mint(uint256 quantity) external payable nonReentrant {
        if (!normalSale) revert NormalSaleNotActive();
        if (quantity + _numberMinted(msg.sender) > maxMints) {
            revert ExceededLimit();
        }
        if (totalSupply() + quantity > maxSupply) {
            revert NotEnoughTokensLeft();
        }
        if (mintRate * quantity != msg.value) {
            revert WrongEther();
        }
        _safeMint(msg.sender, quantity);
    }

    function whitelistBuy(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        if (quantity > 20) revert ExceededLimit();
        if (whitelistMintRate * quantity != msg.value) {
            revert WrongEther();
        }
        if (usedAddresses[msg.sender] + quantity > 20) {
            revert WhitelistUsed();
        }
        if (!whitelistSale) revert WhitelistNotActive();

        if (totalSupply() + quantity > maxSupply) {
            revert NotEnoughTokensLeft();
        }
        if (!isWhiteListed(msg.sender, proof)) revert InvalidMerkle();
        usedAddresses[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!revealed) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _newURI) public onlyOwner {
        notRevealedUri = _newURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function toggleSale() public onlyOwner {
        normalSale = !normalSale;
    }

    function toggleWhitelistSale() public onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function renounceOwnership() public override onlyOwner {}

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    function setWhitelistMintRate(uint256 _mintRate) public onlyOwner {
        whitelistMintRate = _mintRate;
    }

    function setMaxSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = _newSupply;
    }

    function setMaxMints(uint256 _newMaxMints) public onlyOwner {
        maxMints = _newMaxMints;
    }
}
