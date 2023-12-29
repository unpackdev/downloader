// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";

contract FloridaMan is
    Ownable,
    ERC721A,
    ERC2981,
    ERC721ABurnable,
    ERC721AQueryable,
    ReentrancyGuard,
    PaymentSplitter
{
    error MintNotStarted();
    error ExceedsMaxMint();
    error ExceedsMaxSupply();
    error AlreadyClaimed();
    error InsufficientFunds();

    uint256 public OG_PRICE = 0.01 ether;
    uint256 public PUBLIC_PRICE = 0.015 ether;

    uint48 public maxSupply = 5555;
    uint48 public perWalletMax = 6;
    uint48 public ogMintsMax = 16;
    uint48 public ogMintCount = 0;

    bool public revealed = false;
    bool public active = false;

    mapping(address => uint) public claimed;

    string private baseURI = "";
    string private preRevealURI = "https://bafkreiddgcd4xyrnokm77yc432xw5333ihlvx4zpicts5ynzxdjs3dlug4.ipfs.nftstorage.link";

    constructor(
        address initialOwner,
        address[] memory payees,
        uint256[] memory shares
    )
        Ownable(initialOwner)
        ERC721A("Florida Man", "FLMan")
        PaymentSplitter(payees, shares)
    {
        _safeMint(address(payees[0]), 5);
        _safeMint(address(payees[1]), 5);
        _safeMint(address(payees[2]), 5);
        _safeMint(address(payees[3]), 5);
        _safeMint(address(payees[4]), 5);
        _setDefaultRoyalty(initialOwner, 420);
    }

    function mint(uint48 quantity) external payable nonReentrant {
        if (!active) revert MintNotStarted();
        if (totalSupply() + quantity > maxSupply) revert ExceedsMaxSupply();
        if (quantity > perWalletMax) revert ExceedsMaxMint();

        if (ogMintCount < ogMintsMax) {
            if (msg.value < quantity * OG_PRICE) revert InsufficientFunds();
            ogMintCount++;
        } else {
            if (msg.value < quantity * PUBLIC_PRICE) revert InsufficientFunds();
        }

        bool hasClaimed = claimed[_msgSender()] + quantity > perWalletMax;
        if (hasClaimed) revert AlreadyClaimed();

        _safeMint(_msgSender(), quantity);

        claimed[_msgSender()] += quantity;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(preRevealURI));
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        baseURI = newBaseUri;
    }

    function reveal(
        bool _revealed,
        string calldata _baseURI
    ) external onlyOwner {
        revealed = _revealed;
        baseURI = _baseURI;
    }

    function setOGMints(uint48 _max) external onlyOwner {
        ogMintsMax = _max;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        PUBLIC_PRICE = _price;
    }

    function setPerWalletMax(uint48 _perWalletMax) external onlyOwner {
        perWalletMax = _perWalletMax;
    }

    function setMaxSupply(uint48 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function toggleMint() external onlyOwner {
        active = !active;
    }
}
