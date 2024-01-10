// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721A.sol";
// import "./ERC721.sol";
// import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./console.sol";

contract DojiEth is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_FREE = 1500;
    uint256 public constant MAX_PUBLIC = 612;
    uint256 public constant MAX_SUPPLY = MAX_FREE + MAX_PUBLIC;
    uint256 public constant UNIT_PRICE = 0.05 ether;
    uint256 public constant MAX_PER_MINT = 5;

    mapping(address => uint256) public freeMinters;

    string private _tokenBaseURI = "https://doji.dev/api/metadata/";

    bool public saleLive;
    bool public freeMintLive;

    address public signerAddress;

    uint256 private _tokenIdCounter = 0;
    address scoresAddress;
    address vaultAddress;

    event StoryTitle(uint256 indexed tokenId, string title);
    event StoryOfTheDay(uint256 indexed tokenId, string story);

    constructor() ERC721A("Doji x Ethereum", "DOJIETH") {
        setSignerAddress(msg.sender);
    }

    function setVault(address _vaultAddress) external onlyOwner {
      vaultAddress = _vaultAddress;
    }

    function setScores(address _scoresAddress) public onlyOwner {
        scoresAddress = _scoresAddress;
    }

    function setSignerAddress(address signer) public onlyOwner {
        signerAddress = signer;
    }

    function startSale() external onlyOwner {
        saleLive = true;
    }

    function stopSale() external onlyOwner {
        saleLive = false;
    }

    function startFreeMint() external onlyOwner {
        freeMintLive = true;
    }

    function stopFreeMint() external onlyOwner {
        freeMintLive = false;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function verifyHash(bytes32 hash, bytes memory signature) public pure returns (address signer) {
        bytes32 messageDigest = ECDSA.toEthSignedMessageHash(hash);
        return ECDSA.recover(messageDigest, signature);
    }

    function mintFree(uint256 numberOfToken, uint256 maxFree, bytes memory signature) public payable {
        require(freeMintLive, "FREE_CLOSED");
        require(_tokenIdCounter + numberOfToken <= MAX_FREE, "FREE_MAX_EXCEEDED");
        bytes32 addressHash = keccak256(abi.encodePacked(msg.sender, maxFree));
        address signer = verifyHash(addressHash, signature);
        require(signer == signerAddress, "NOT_WHITELISTED");
        require(freeMinters[msg.sender] + numberOfToken <= maxFree, "FREE_MINTER_MAX_EXCEEDED");

        _mintNFT(numberOfToken);
    }

    function mintPublic(uint256 numberOfToken) public payable {
        require(saleLive, "SALE_CLOSED");
        require(_tokenIdCounter + numberOfToken <= MAX_SUPPLY, "ALL_SOLD_OUT");

        if (msg.sender != owner()) {
            if (_tokenIdCounter + numberOfToken > MAX_FREE) {
                require(msg.value >= UNIT_PRICE * numberOfToken, "NOT_ENOUGH_ETH");
            }
            require(numberOfToken <= MAX_PER_MINT, "TRANSACTION_MAX_EXCEEDED");
        }

        _mintNFT(numberOfToken);
    }

    function _mintNFT(uint256 numberOfToken) internal {
        require(numberOfToken > 0, "CANNOT_MINT_NONE");
        if (freeMintLive) {
            freeMinters[msg.sender] += numberOfToken;
        }

        _tokenIdCounter += numberOfToken;

        _safeMint(msg.sender, numberOfToken);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, toString(tokenId)));
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setStoryTitle(uint256 tokenId, string memory _title) public {
        require(ownerOf(tokenId) == msg.sender, "You don't own this token");
        emit StoryTitle(tokenId, _title);
    }

    function setStory(uint256 tokenId, string memory _story) public {
        require(ownerOf(tokenId) == msg.sender, "You don't own this token");
        emit StoryOfTheDay(tokenId, _story);
    }
}
