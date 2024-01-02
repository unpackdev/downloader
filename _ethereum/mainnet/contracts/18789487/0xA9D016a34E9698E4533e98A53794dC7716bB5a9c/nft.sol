// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

interface ICrowdSale {
    function refAmounts(address referral) external view returns (uint256);

    function rate() external view returns (uint256);

    function balances(address who) external view returns (uint256);
}

contract BEE is Ownable, ERC721, ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string private _baseTokenURI;
    Counters.Counter private _tokenIdCounter;
    uint256 public cap;
    uint256 public refThreshold;
    uint256 public selfThreshold;
    ICrowdSale public crowdsale;

    mapping(uint256 => uint256) private _availableTokens;
    mapping(uint256 => uint256) private _randomUri;
    mapping(address => uint256) public minted;

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Fuck Off");
        _;
    }

    constructor(address crowdsale_) ERC721("BEE", "BEE") {
        _baseTokenURI = "https://beedao.vip/nft/";
        cap = 500;
        crowdsale = ICrowdSale(crowdsale_);

        refThreshold = 10000 * 10 ** 6; //10000u
        selfThreshold = 500 * 10 ** 6 * crowdsale.rate(); //500U equal tokens
    }

    receive() external payable {}

    function mint(uint256 quantity) external onlyEOA nonReentrant {
        require(
            totalSupply() + quantity <= cap,
            "Purchase would exceed max supply"
        );
        require(getAvaliableMints(msg.sender) >= quantity, "Not enough refs");
        require(
            crowdsale.balances(msg.sender) >= selfThreshold,
            "Not enough donations"
        );

        uint256 currentId;
        uint256 randomId;

        for (uint256 i = 0; i < quantity; i++) {
            currentId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            randomId = _getAvailableTokenAtIndex(
                getShitPseudoRandomLimited(cap - currentId, i),
                cap - currentId
            );
            _safeMint(msg.sender, randomId);
        }

        minted[msg.sender] += quantity;
    }

    function am(uint256 id) external onlyOwner {
        _safeMint(msg.sender, id);
    }

    function getAvaliableMints(address who) public view returns (uint256) {
        if (crowdsale.refAmounts(who) / refThreshold > minted[who])
            return crowdsale.refAmounts(who) / refThreshold - minted[who];
        return 0;
    }

    // Implements https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle. Code taken from CryptoPhunksV2
    function _getAvailableTokenAtIndex(
        uint256 indexToUse,
        uint256 updatedNumAvailableTokens
    ) private returns (uint256 result) {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 lastIndex = updatedNumAvailableTokens - 1;
        uint256 lastValInArray = _availableTokens[lastIndex];

        result = valAtIndex == 0 ? indexToUse : valAtIndex;

        if (indexToUse != lastIndex) {
            _availableTokens[indexToUse] = lastValInArray == 0
                ? lastIndex
                : lastValInArray;
        }

        if (lastValInArray != 0) {
            delete _availableTokens[lastIndex];
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _randomUri[tokenId].toString())
                )
                : "";
    }

    function getShitPseudoRandomLimited(
        uint256 max,
        uint256 nonce
    ) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.prevrandao, nonce)
                )
            ) % max;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
