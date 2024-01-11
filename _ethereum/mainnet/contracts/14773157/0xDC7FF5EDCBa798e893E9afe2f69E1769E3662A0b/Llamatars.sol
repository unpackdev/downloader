// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// local imports
import "./RandomlyAssigned.sol";

contract Llamatars is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard, RandomlyAssigned {
    using Strings for uint256;

    uint256 public constant MAX_PER_MINT = 20;
    uint256 public constant MAX_TOTAL_SUPPLY = 9999;
    uint256 public constant MINT_PRICE = 0.05 ether;

    uint256 public publicSaleStartTime;

    string public baseUri = "";

    mapping(address => uint256) public whiteListFreeMintAmountPerAddress;

    constructor() ERC721("LLAMATARS", "LLAMATARS") RandomlyAssigned(MAX_TOTAL_SUPPLY) {}

    function claimWhiteListFreeMint(uint16 _numTokens) external {
        require(whiteListFreeMintAmountPerAddress[_msgSender()] > 0, "Error: Not whitelisted");
        require(
            whiteListFreeMintAmountPerAddress[_msgSender()] >= _numTokens,
            "Error: Not allowed to claim that amount"
        );
        require(totalSupply() + _numTokens <= MAX_TOTAL_SUPPLY, "Error: Insufficient supply");

        whiteListFreeMintAmountPerAddress[_msgSender()] -= _numTokens;

        _mintBaseTokens(_numTokens, _msgSender());
    }

    function mint(uint16 _numTokens) external payable {
        require(isPublicSaleOpen(), "Error: The sale period is not open");
        require(totalSupply() + _numTokens <= MAX_TOTAL_SUPPLY, "Error: Insufficient supply");
        require(msg.value == _numTokens * MINT_PRICE, "Error: Incorrect amount sent");
        _mintBaseTokens(_numTokens, _msgSender());
    }

    /* View */
    function isPublicSaleOpen() public view returns (bool) {
        return publicSaleStartTime != 0 && block.timestamp >= publicSaleStartTime;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721) returns (string memory) {
        return string(abi.encodePacked(baseUri, "/", _tokenId.toString(), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseUri, "/contract-meta.json"));
    }

    /* Administration */
    function setPublicSaleStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, "Error: Start time must be in the future");
        require(!isPublicSaleOpen(), "Error: Base sales already started");

        publicSaleStartTime = _startTime;
    }

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function addToFreeMintWhiteList(address[] calldata _addresses, uint256 _numTokens) external onlyOwner {
        for (uint256 _index; _index < _addresses.length; _index++) {
            whiteListFreeMintAmountPerAddress[_addresses[_index]] += _numTokens;
        }
    }

    function removeFromFreeMintWhiteList(address[] calldata _addresses) external onlyOwner {
        for (uint256 _index; _index < _addresses.length; _index++) {
            delete whiteListFreeMintAmountPerAddress[_addresses[_index]];
        }
    }

    function withdrawBalance(uint256 _amount) external nonReentrant onlyOwner {
        require(_amount <= address(this).balance, "Error: Not enough balance left");
        address(msg.sender).call{value : _amount}("");
    }

    function withdrawTotalBalance() external nonReentrant onlyOwner {
        uint256 _amount = address(this).balance;
        address(msg.sender).call{value : _amount}("");
    }

    /* Internals */
    function _mintBaseTokens(uint16 _numTokens, address _to) internal ensureAvailabilityFor(_numTokens) {
        require(_numTokens <= MAX_PER_MINT, "Error: Too many purchases at once");
        for (uint256 i = 0; i < _numTokens; i++) {
            _mintBaseToken(_to);
        }
    }

    function _mintBaseToken(address _to) internal ensureAvailability {
        uint256 tokenId = nextTokenId();
        _safeMint(_to, tokenId);
    }

    /* Misc */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
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
