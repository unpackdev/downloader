// SPDX-License-Identifier: MIT
// Creator: Gigachad
pragma solidity ^0.8.9;
import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./Counters.sol";
import "./Address.sol";

contract PixelBeanz is ERC721, IERC2981, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    constructor(string memory customBaseURI_) ERC721("PixelBeanz", "pxbnz") {
        customBaseURI = customBaseURI_;
    }

    mapping(address => uint256) private mintCountMap;

    mapping(address => uint256) private allowedMintCountMap;

    uint256 public constant MINT_LIMIT_PER_WALLET = 5;

    function allowedMintCount(address minter) public view returns (uint256) {
        return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
    }

    function updateMintCount(address minter, uint256 count) private {
        mintCountMap[minter] += count;
    }

    ERC721 CopeBeanzAddr = ERC721(0xeECD896e39d1EBdAb51f0dbf7087F4EBc918C878);

    uint256 public constant MAX_SUPPLY = 2000;

    uint256 public constant MAX_MULTIMINT = 5;

    uint256 public constant PRICE = 20000000000000000; //same as 0.02

    Counters.Counter private supplyCounter;

    function mint(uint256 count) public payable nonReentrant {
        require(saleIsActive, "Sale not active");

        if (allowedMintCount(msg.sender) >= count) {
            updateMintCount(msg.sender, count);
        } else {
            revert("Minting limit exceeded");
        }

        require(totalSupply() + count - 1 < MAX_SUPPLY, "Max Supply Reached");

        require(count <= MAX_MULTIMINT, "Mint most 5 at a time");

        require(
            msg.value >= PRICE * count,
            "Too little eth, 0.02 ETH per item"
        );

        for (uint256 i = 0; i < count; i++) {
            _mint(msg.sender, totalSupply() + 1);

            supplyCounter.increment();
        }
    }

    function ownerMint(uint256 count) public nonReentrant onlyOwner {
        require(totalSupply() + count - 1 < MAX_SUPPLY, "Max Supply Reached");
        for (uint256 i = 0; i < count; i++) {
            _mint(msg.sender, totalSupply() + 1);

            supplyCounter.increment();
        }
    }

    function copeBeanzMint(uint256 count) public payable nonReentrant {
        require(saleIsActive, "Sale not active");
        if (allowedMintCount(msg.sender) >= count) {
            updateMintCount(msg.sender, count);
        } else {
            revert("Minting limit exceeded");
        }

        require(totalSupply() + count - 1 < MAX_SUPPLY, "Max Supply Reached");

        require(count <= MAX_MULTIMINT, "Mint most 5 at a time");

        require(
            msg.value >= (PRICE / 2) * count,
            "Too little eth, 0.01 ETH per item"
        );

        for (uint256 i = 0; i < count; i++) {
            require(
                CopeBeanzAddr.balanceOf(msg.sender) > 0,
                "You don't own any copebeanz"
            );
            _mint(msg.sender, totalSupply() + 1);
            supplyCounter.increment();
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    customBaseURI,
                    "/",
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    bool public saleIsActive = false;

    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    string private customBaseURI;

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    address private constant devAddr =
        0x8C4F0c30181b67C2E9a5B84957D9581C1392e2Fa;

    function withdraw() public nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(owner()), (balance * 85) / 100);

        Address.sendValue(payable(devAddr), (balance * 15) / 100);
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 690) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}
