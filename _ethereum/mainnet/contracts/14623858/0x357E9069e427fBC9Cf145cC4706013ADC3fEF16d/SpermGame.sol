// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./RandomlyAssigned.sol";

contract SpermGame is ERC721, Ownable, RandomlyAssigned {
    using Strings for uint;
    using ECDSA for bytes32;

    uint public immutable MAX_TOKENS;
    uint public immutable PUBLIC_MINT_COST = 60000000000000000; // 0.06 Ether
    uint public immutable PRESALE_MINT_COST = 44000000000000000; // 0.044 Ether
    uint internal immutable MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    string public constant PROVENANCE_HASH = "F7A2C002932960FADC377711441ADA7ABB4B32454852BF016027BA5F8185036C";

    string private baseURI;
    string private wrappedBaseURI;

    bool isRevealed;
    bool publicMintAllowed;

    address private operatorAddress;

    mapping(bytes32 => bool) public executed;

    uint[] public medalledTokenIds;

    constructor(
        string memory initialURI,
        uint _MAX_TOKENS)
    ERC721("Sperm Game", "SG")
    RandomlyAssigned(_MAX_TOKENS, 0) {
        isRevealed = false;
        publicMintAllowed = false;
        baseURI = initialURI;
        MAX_TOKENS = _MAX_TOKENS;
        operatorAddress = msg.sender;
        medalledTokenIds = new uint[]((_MAX_TOKENS / 256) + 1);
    }

    function mint(uint num) external payable ensureAvailabilityFor(num) {
        require(publicMintAllowed, "Public minting is not open");
        require(msg.value >= num * PUBLIC_MINT_COST, "Mint cost is 0.06 ETH per token");

        uint tokenId;
        for (uint i = 0; i < num; i++) {
            tokenId = nextToken();
            _safeMint(msg.sender, tokenId);
        }
    }

    function allowlistMint(uint num, uint nonce, bytes calldata signature) external payable ensureAvailabilityFor(num) {
        verifyAllowlistMint(msg.sender, num, nonce, signature);
        require(msg.value >= num * PRESALE_MINT_COST, "Mint cost is 0.044 ETH per token");

        uint tokenId;
        for (uint i = 0; i < num; i++) {
            tokenId = nextToken();
            _safeMint(msg.sender, tokenId);
        }
    }

    function devMint(uint num, uint nonce, uint rand, bytes calldata signature) external payable ensureAvailabilityFor(num) {
        verifyDevMint(msg.sender, num, nonce, rand, signature);

        uint tokenId;
        for (uint i = 0; i < num; i++) {
            tokenId = nextToken();
            _safeMint(msg.sender, tokenId);
        }
    }

    function claimMedal(uint[] calldata tokenIds, bytes[] calldata signatures) external {
        require(tokenIds.length == signatures.length, "Must have one signature per tokenId");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Must be owner of the tokenId to claim medal");
            verifyTokenInFallopianPool(tokenIds[i], signatures[i]);
            setMedalled(tokenIds[i]);
        }
    }

    function unclaimMedal(uint[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Must be owner of the tokenId to unclaim medal");
            unsetMedalled(tokenIds[i]);
        }
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool isValid) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == operatorAddress;
    }

    function verifyAllowlistMint(address wallet, uint num, uint nonce, bytes calldata signature) internal {
        bytes32 msgHash = keccak256(abi.encodePacked(wallet, num, nonce));
        require(!executed[msgHash], "Transaction with this msgHash already executed");
        require(isValidSignature(msgHash, signature), "Invalid signature");
        executed[msgHash] = true;
    }

    function verifyDevMint(address wallet, uint num, uint nonce, uint rand, bytes calldata signature) internal {
        bytes32 msgHash = keccak256(abi.encodePacked(wallet, num, nonce, rand));
        require(!executed[msgHash], "Transaction with this msgHash already executed");
        require(isValidSignature(msgHash, signature), "Invalid signature");
        executed[msgHash] = true;
    }

    function verifyTokenInFallopianPool(uint tokenId, bytes calldata signature) internal view {
        bytes32 msgHash = keccak256(abi.encodePacked(tokenId));
        require(isValidSignature(msgHash, signature), "Invalid signature");
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        if (isRevealed && !isMedalled(tokenId)) {
            return string(abi.encodePacked(baseURI, "/", tokenId.toString()));
        } else if (isRevealed && isMedalled(tokenId)) {
            return string(abi.encodePacked(wrappedBaseURI, "/", tokenId.toString()));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function setTokenURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setWrappedBaseTokenURI(string calldata _wrappedBaseURI) external onlyOwner {
        wrappedBaseURI = _wrappedBaseURI;
    }

    function setOperatorAddress(address _address) external onlyOwner {
        operatorAddress = _address;
    }

    function togglePublicMintingAllowed() external onlyOwner {
        publicMintAllowed = !publicMintAllowed;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function isMedalled(uint tokenId) public view returns (bool) {
        uint[] memory bitMapList = medalledTokenIds;
        uint Y = tokenId / 256;
        uint partition = bitMapList[Y];
        if (partition == MAX_INT) {
            return true;
        }
        uint X = tokenId % 256;
        uint bit = partition & (1 << X);
        return (bit != 0);
    }

    function setMedalled(uint tokenId) internal {
        uint[] storage bitMapList = medalledTokenIds;
        uint Y = tokenId / 256;
        uint partition = bitMapList[Y];
        uint X = tokenId % 256;
        bitMapList[Y] = partition | (1 << X);
    }

    function unsetMedalled(uint tokenId) internal {
        uint[] storage bitMapList = medalledTokenIds;
        uint Y = tokenId / 256;
        uint partition = bitMapList[Y];
        uint X = tokenId % 256;
        bitMapList[Y] = partition & (0 << X);
    }
}