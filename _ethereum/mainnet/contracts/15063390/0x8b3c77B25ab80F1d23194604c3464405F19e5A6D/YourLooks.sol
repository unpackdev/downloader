// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract YourLooks is ERC721, ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    // Project info
    IERC20 public immutable looksRareToken;
    string public YOLO_PROVENANCE = "620e3b871694a97e74051f6bf10a76bfdf31044f07acb076544fd9a20ed93091";
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINTS = 20;
    uint256 public PRICE_PER_TOKEN = 300 ether; // 300 LOOKS

    // LOOKS treasury contract
    address public yourLooksTreasury;

    // Private variables
    uint256 private _reserved = 100;
    string private _baseTokenURI;

    // Royalty
    address public royaltyAddress;
    uint96 public royaltyFee = 500;

    // Sale's state
    bool public saleIsActive = false;

    mapping(address => uint256) public purchased;

    // Team addresses
    address t1 = 0xa0996f64adF02a3d3b47b1a78E32cB5a73A3275c;
    address t2 = 0x1ad271F74bAAA8aCCeC2f2Dc8753D182DF0f871f;
    address t3 = 0xB76d98d56127181520f0fa3f5080274a71C0a88B;

    constructor(
        IERC20 _looksRareToken,
        string memory baseURI,
        address _yourLooksTreasury
    ) ERC721("YourLooks", "YOLO") {
        looksRareToken = IERC20(_looksRareToken);
        _baseTokenURI = baseURI;
        yourLooksTreasury = _yourLooksTreasury;
        royaltyAddress = _yourLooksTreasury;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);

        // team gets the first 3 Lookers
        _safeMint(t1, 0);
        _safeMint(t2, 1);
        _safeMint(t3, 2);
    }

    function startSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Just in case LOOKS does some crazy stuff
    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE_PER_TOKEN = _newPrice;
    }

    function mint(uint256 num) public nonReentrant {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale paused");
        require(num > 0, "Must mint at least one token");
        require(purchased[msg.sender] + num <= MAX_MINTS, "Can only mint up to 20 tokens per address");
        require(supply + num <= MAX_SUPPLY - _reserved, "Exceeds max supply");

        purchased[msg.sender] += num;

        // Payment
        uint256 costToMint = PRICE_PER_TOKEN * num;
        uint256 userBalance = looksRareToken.balanceOf(msg.sender);
        require(costToMint <= userBalance, "User balance is not enough");
        looksRareToken.safeTransferFrom(msg.sender, address(this), costToMint);

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function reserve(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= _reserved, "Exceeds reserved yourlooks supply");

        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }

        _reserved -= _amount;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdraw() external onlyOwner {
        looksRareToken.safeTransfer(yourLooksTreasury, looksRareToken.balanceOf(address(this)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
