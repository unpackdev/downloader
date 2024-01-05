//SPDX-License-Identifier: NONE
pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract ChainText is ERC721Enumerable, Ownable {
    uint256 public constant MIN_COST = 0.02 ether;
    uint256 public constant MAX_COST = 7.5 ether;

    uint256 public constant MIN_APPEND_COST = 0.05 ether;

    uint256 public constant MIN_LENGTH = 3;
    uint256 public constant MAX_LENGTH = 280;
    uint256 public constant MAX_APPENDS = 32;

    uint256 public constant TEXTS_PER_PRICE_LEVEL = 128;

    mapping(uint256 => string[]) private _textContents;
    mapping(uint256 => uint16) private _appearance;
    uint256 private currentCost;

    event ContentAdded(address indexed owner, uint256 indexed tokenId, string text);

    modifier existingToken(uint256 token) {
        require(_exists(token), "Nonexistent token");
        _;
    }

    constructor() public ERC721("ChainText.net", "CTXT") {
        _safeMint(msg.sender, 0);
        string memory firstMessage = unicode"✨\nChainText.net Genesis\n✨";
        _addText(0, firstMessage);
        _setAppearance(0, 0x230);
        currentCost = MIN_COST;
        emit ContentAdded(msg.sender, 0, firstMessage);
    }

    function textsPerPriceLevel() internal pure virtual returns (uint256) {
        return TEXTS_PER_PRICE_LEVEL;
    }

    function currentMintCost() public view returns (uint256) {
        return currentCost;
    }

    function currentAppendCost(uint256 token) public view existingToken(token) returns (uint256) {
        uint256 currentTextCount = _textContents[token].length;
        return calcAppendCost(currentTextCount);
    }

    function updatePrice() private {
        if (totalSupply() % textsPerPriceLevel() == 0 && currentCost < MAX_COST) {
            currentCost *= 2;
            if (currentCost > MAX_COST) {
                currentCost = MAX_COST;
            }
        }
    }
    
    function mintsUntilPriceIncrease() public view returns (uint16) {
        if (currentCost < MAX_COST) {
            uint256 nextIncrease = ((totalSupply() / textsPerPriceLevel()) + 1) * textsPerPriceLevel();
            return uint16(nextIncrease - totalSupply());
        } else {
            return 2**16 - 1;
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://chaintext.net/meta/";
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract"));
    }

    function mintText(string memory text, uint16 appearanceBits) public payable {
        uint256 len = bytes(text).length;
        require(len <= MAX_LENGTH, "Length out of bounds");
        uint256 minCost = currentMintCost();
        require(msg.value >= minCost, "Payment too low");

        uint256 tokenNumber = totalSupply();
        _safeMint(msg.sender, tokenNumber);
        _addText(tokenNumber, text);
        _setAppearance(tokenNumber, appearanceBits);
        updatePrice();
        emit ContentAdded(msg.sender, tokenNumber, text);
    }

    function appendText(uint256 token, string memory text) public payable {
        uint256 len = bytes(text).length;
        require(len >= MIN_LENGTH && len <= MAX_LENGTH, "Length out of bounds");
        require(msg.sender == ownerOf(token), "Not owner");
        require(_textContents[token].length < MAX_APPENDS, "Too many appends");
        uint256 minCost = calcAppendCost(_textContents[token].length);
        require(msg.value >= minCost, "Payment too low");

        _addText(token, text);

        emit ContentAdded(msg.sender, token, text);
    }

    function appendsRemaining(uint256 token) public view existingToken(token) returns (uint256) {
        return MAX_APPENDS - _textContents[token].length;
    }

    function claim(uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }

        // https://consensys.github.io/smart-contract-best-practices/recommendations/#dont-use-transfer-or-send
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    /**
    Get the text content of a ChainText token.
     */
    function content(uint256 token) public view existingToken(token) returns (string memory) {
        string[] memory strs = _textContents[token];
        string memory result = "";
        for (uint256 i = 0; i < strs.length; i += 4) {
            if (i + 3 < strs.length) {
                result = string(abi.encodePacked(result, strs[i], strs[i + 1], strs[i + 2], strs[i + 3]));
            } else if (i + 2 < strs.length) {
                result = string(abi.encodePacked(result, strs[i], strs[i + 1], strs[i + 2]));
            } else if (i + 1 < strs.length) {
                result = string(abi.encodePacked(result, strs[i], strs[i + 1]));
            } else {
                result = string(abi.encodePacked(result, strs[i]));
            }
        }
        return result;
    }

    /**
    Get the appearance of a ChainText token
    The appearance is encoded as a 16 bit int.
    The lowest 4 bits are encoding the index of the font [0=Plain, 1=Handwriting, 2=Cursive, etc.], the next 4 higher bits encode the index
    of the background type and the next 4 higher bits the color scheme.
    The highest 4 bits are reserved for future use.
    See https://chaintext.net/properties.json for the current encoding.
    */
    function appearance(uint256 token) public view existingToken(token) returns (uint16 appearanceBits) {
        return _appearance[token];
    }

    function calcAppendCost(uint256 currentTextCount) private pure returns (uint256) {
        uint256 steps = currentTextCount / 2;
        uint256 value = MIN_APPEND_COST * 2**steps;
        return value;
    }

    function _addText(uint256 tokenId, string memory _tokenURI) private {
        _textContents[tokenId].push(_tokenURI);
    }

    function _setAppearance(uint256 tokenId, uint16 appearanceBits) private {
        _appearance[tokenId] = appearanceBits;
    }
}
