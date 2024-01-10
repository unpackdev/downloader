pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract MONAFlower is ERC721, ReentrancyGuard, Ownable {

    uint256 public tokenPrice = 50000000000000000;
    uint256 public discountTokenPrice = 45000000000000000;
    uint256 public saleId = 1;
    bool private isFreezed;
    string private __baseURI;
    address payable private _address;

    using Strings for uint256;

    constructor(string memory baseURI, address payable __address, address to) ERC721("MONA Flower", "MONA") {
        _address = __address;
        __baseURI = baseURI;
        for (uint256 i = 9871; i <= 10000; i++) {
            _safeMint(to, i);
        }
    }

    /**
     * @notice 10,000 unique NFTs by enthusiastic Monacoin lovers on the Ethereum.
     * @dev In early 2014, Monacoin made its debut on 2ch.net, a famous internet bbs in Japan.
     *      Although other PoW cryptocurrencies existed, but Mr. Watanabe, who was also known as GOD in Japanese computer programers, modified the first cryptocurrency in Japan.
     *      He launched Monacoin in just 8 days. Now, inspired by the famous and cool BTC Flower by Ludo on ICP, MONA Flower is born!
     * @dev This story cuts closer to the ideals of open source and inspiration than most realize.
     *      Monacoin started in internet with small community, but the first cryptocurrency in Japan the world has ever known.
     *      Egalitarian in nature, it has no owner and is free for everyone — Mr. Watanabe’s gift to the world.
     *      This was only the beginning. Mr. Watanabe probably went on to stay involved in the space throughout crypto winter.
     *      His DNA, or rather enthusiastic Monacoin lovers considered MONA Flower in February 2022, remaining a symbol of hope in the market’s darkest days.
     * @dev The next iteration of MONA Flower is coming in the form of 10,000 digital NFTs, commemorating the homage to Monacoin.
     *      They will exist on Ethereum, not Monacoin, because Ethereum is popular — but too expensive on gas fee.
     *      The art itself will be a true inspired homage, a single piece of art in iterable and varied forms, distributed as a network species.
     * @dev MONA Flower is more than just an artistic representation or symbol for the Monacoin movement — it’s a distillation of Monacoin’s story that reminds us where we’ve been,
     *      where we’re going, and most importantly, why we Monacoiners do what we do.
     * @dev See https://monaflower.xyz
     */
    function README() public view returns(string memory) {
        return "";
    }

    function mint(uint256 amount) external nonReentrant payable {
        require(amount > 0, "Amount must be greater than 0");
        if (amount >= 10) {
            require(msg.value == (amount * discountTokenPrice), "Incorrect money");
        } else {
            require(msg.value == (amount * tokenPrice), "Incorrect money");
        }
        require(saleId + amount <= 9871, "Sale id overflow");

        for (uint256 i; i < amount; i++) {
            _safeMint(_msgSender(), saleId);
            saleId = saleId + 1;
        }
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return __baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Does not exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function withdraw() external {
        Address.sendValue(_address, address(this).balance);
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        require(!isFreezed, "Metadata is already frozen");
        __baseURI = newURI;
    }

    function freezeMetadata() external onlyOwner {
        require(!isFreezed, "Metadata is already frozen");
        isFreezed = true;
    }
}
