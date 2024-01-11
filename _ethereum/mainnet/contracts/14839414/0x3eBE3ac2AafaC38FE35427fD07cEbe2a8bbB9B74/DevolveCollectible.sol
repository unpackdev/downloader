// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721D.sol";
import "./ERC2981.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

error DevolveLevelNotActive();
error DevolveNoMoreLevels();
error DevolveTokenNotOwned();
error DevolveTokensNotSameBloodline();
error DevolveTokensNotSameDevolveState();
error DevolveTokensNotSameLevel();
error DevolveTokensSameId();
error MintExceedsMaxAllocation();
error MintExceedsMaxBloodlineSupply();
error MintExceedsMaxPerTx();
error MintExceedsMaxSupply();
error MintExceedsReservedAllocation();
error MintInsufficientFunds();
error MintInvalidBloodline();
error MintInvalidProof();
error MintInvalidSignature();
error MintSaleNotActive();
error MintUnderMinimumRequirement();
error SettingsInvalidLevel();
error SettingsInvalidResAllocation();
error SettingsInvalidSignerAddress();

contract DevolveCollectible is ERC2981, ERC721D, Ownable {
    using ECDSA for bytes32;

    string public baseURI;

    uint256 public wisemanPrice;

    uint256 public maxWisemanPurchase;

    uint256 public resAllocation;
    uint256 public resMinted;

    uint256 public constant MAX_WISEMEN = 42 * (2**(NUMBER_OF_LEVELS - 1)); // 42 in final level, why 42? It's the answer to life, the universe, and everything of course!
    uint256 public constant NUMBER_OF_LEVELS = 8;

    uint16[5] public MAX_WISEMEN_PER_BLOODLINE = [
        // Can't use array constant so using non-constant even though these totals can't be changed
        uint16(10 * (2**(NUMBER_OF_LEVELS - 1))), // earth
        uint16(10 * (2**(NUMBER_OF_LEVELS - 1))), // fire
        uint16(10 * (2**(NUMBER_OF_LEVELS - 1))), // water
        uint16(10 * (2**(NUMBER_OF_LEVELS - 1))), // air
        uint16(2 * (2**(NUMBER_OF_LEVELS - 1))) // energy
    ];

    struct LevelMeta {
        bool survivorDevolveIsActive;
        bool zombieDevolveIsActive;
        uint16[5] survivorMints;
        uint16[5] zombieMints;
    }
    LevelMeta[NUMBER_OF_LEVELS] public levelMeta;

    address private signerAddress; // Minting signer

    event Devolve(
        uint256 indexed tokenId1,
        uint256 indexed tokenId2,
        uint256 indexed resultTokenId,
        uint256 devolvedTokenId
    );

    constructor() ERC721D("Devolve Collectible", "DEVOLVE") {
        wisemanPrice = 60000000000000000; //0.06 ETH
        maxWisemanPurchase = 0; // When set public mint is active
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721D, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function generateTokenURI(
        uint8 level,
        uint8 bloodline,
        uint16 sequenceId,
        bool devolved
    ) internal pure returns (string memory) {
        string memory uri = strConcat(
            strConcat(strConcat(strConcat(Strings.toString(level), "-"), Strings.toString(bloodline)), "-"),
            Strings.toString(sequenceId)
        );

        if (devolved) {
            return strConcat(uri, "-D");
        } else {
            return uri;
        }
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        if (_signerAddress == address(0)) revert SettingsInvalidSignerAddress();
        signerAddress = _signerAddress;
    }

    function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    /*
     * Pause level devolving if active, make active if paused
     */
    function toggleDevolveState(uint256 level, bool devolved) public onlyOwner {
        if (level >= NUMBER_OF_LEVELS - 1) revert SettingsInvalidLevel();
        if (devolved) {
            levelMeta[level].zombieDevolveIsActive = !levelMeta[level].zombieDevolveIsActive;
        } else {
            levelMeta[level].survivorDevolveIsActive = !levelMeta[level].survivorDevolveIsActive;
        }
    }

    /**
     * Set price to mint a wiseman
     */
    function setMintPrice(uint256 price) external onlyOwner {
        wisemanPrice = price;
    }

    /**
     * Set max purchase qty
     */
    function setMaxPurchase(uint256 qty) external onlyOwner {
        maxWisemanPurchase = qty;
    }

    function setResAllocation(uint256 qty) external onlyOwner {
        // New allocation already fully minted?
        if (qty < resMinted) revert SettingsInvalidResAllocation();
        // Allocating more than is left?
        if (mintTotal(0) + qty > MAX_WISEMEN) revert SettingsInvalidResAllocation();

        resAllocation = qty;
    }

    function mintWL(
        address to,
        uint8 bloodline,
        bool og,
        uint256 amount,
        uint256 min,
        uint256 max,
        uint256 price,
        uint256 start,
        uint256 end,
        bytes32 proof,
        bytes calldata signature
    ) external payable {
        if (block.timestamp < start || block.timestamp > end) revert MintSaleNotActive();
        if (_addressData[to].numberMinted + amount > max) revert MintExceedsMaxAllocation();
        if (amount < min) revert MintUnderMinimumRequirement();
        if (price * amount > msg.value) revert MintInsufficientFunds();

        // Check proof and signature
        bytes32 messageHash = keccak256(abi.encodePacked(to, og, min, max, price, start, end));
        if (proof != messageHash) revert MintInvalidProof();
        if (!verifyAddressSigner(proof, signature)) revert MintInvalidSignature();

        if (price == 0) {
            resMinted += amount;
            if (resMinted > resAllocation) revert MintExceedsReservedAllocation();
        }

        _mint(to, bloodline, og ? 128 : 0, amount);
    }

    function mintWiseman(uint8 bloodline, uint256 numberOfTokens) public payable {
        if (maxWisemanPurchase == 0) revert MintSaleNotActive();
        if (numberOfTokens > maxWisemanPurchase) revert MintExceedsMaxPerTx();
        if (wisemanPrice * numberOfTokens > msg.value) revert MintInsufficientFunds();
        _mint(msg.sender, bloodline, 0, numberOfTokens);
    }

    function _mint(
        address to,
        uint8 bloodline,
        uint8 og,
        uint256 numberOfTokens
    ) internal {
        if (bloodline > 4) revert MintInvalidBloodline();

        uint256 bloodlineTotalBefore = levelMeta[0].survivorMints[bloodline];
        uint256 bloodlineTotalAfter = bloodlineTotalBefore + numberOfTokens;

        // Safety to ensure no mint call can exceed max supply, regardless of mint origin
        if (bloodlineTotalAfter > MAX_WISEMEN_PER_BLOODLINE[bloodline]) revert MintExceedsMaxBloodlineSupply();
        if (mintTotal(0) + numberOfTokens + resAllocation - resMinted > MAX_WISEMEN) revert MintExceedsMaxSupply();

        _safeMint(to, numberOfTokens, 0, bloodline, og, 0, uint16(bloodlineTotalBefore));

        levelMeta[0].survivorMints[bloodline] = uint16(bloodlineTotalAfter);
    }

    /* Devolve
    Select two of the same level and bloodline then
    burn them and create a new 'devolve'
    token1 -> zombie
    token2 -> burnt
    */

    function devolve(uint256 tokenId1, uint256 tokenId2) public {
        // Get token info
        (, , uint256 token1Pos) = tokenIdToMeta(tokenId1);
        (, , uint256 token2Pos) = tokenIdToMeta(tokenId2);
        TokenOwnership memory token1Info = _ownershipOf(tokenId1);
        TokenOwnership memory token2Info = _ownershipOf(tokenId2);

        if (token1Info.addr != msg.sender || token2Info.addr != msg.sender) revert DevolveTokenNotOwned();
        if (tokenId1 == tokenId2) revert DevolveTokensSameId();
        if (token1Info.level != token2Info.level) revert DevolveTokensNotSameLevel();
        if (token1Info.bloodline != token2Info.bloodline) revert DevolveTokensNotSameBloodline();
        if (token1Info.devolved != token2Info.devolved) revert DevolveTokensNotSameDevolveState();
        if (token1Info.level >= NUMBER_OF_LEVELS - 1) revert DevolveNoMoreLevels();

        uint256 devolvedTokenId;

        if (token1Info.devolved == 0) {
            if (!levelMeta[token1Info.level].survivorDevolveIsActive) revert DevolveLevelNotActive();

            // Transpose devolved nft onto first token
            token1Info.devolved = 1;
            _transpose(tokenId1, token1Info);

            // Only set devolvedTokenId for survivor devolving
            devolvedTokenId = metaToTokenId(token1Info.level, token1Info.devolved, token1Pos);

            // Set the sequenceId in the new level and increment token level
            token2Info.sequenceId = levelMeta[++token2Info.level].survivorMints[token2Info.bloodline]++;
        } else {
            if (!levelMeta[token1Info.level].zombieDevolveIsActive) revert DevolveLevelNotActive();

            // Devolving two already devolved NFTs, so burn the first one as we don't generate a zombie
            _burn(tokenId1);

            // Set the sequenceId in the new level and increment token level
            uint256 offset = MAX_WISEMEN_PER_BLOODLINE[token2Info.bloodline] / 2**((token2Info.level + 1));
            token2Info.sequenceId = uint16(offset) + levelMeta[++token2Info.level].zombieMints[token2Info.bloodline]++;
        }

        // Transpose next level nft onto second token
        token2Info.og = (token1Info.og >> 1) + (token2Info.og >> 1);
        _transpose(tokenId2, token2Info);

        uint256 resultTokenId = metaToTokenId(token2Info.level, token2Info.devolved, token2Pos);

        // devolvedTokenId is only set for survivor devolving
        emit Devolve(tokenId1, tokenId2, resultTokenId, devolvedTokenId);
    }

    function burn(uint256 tokenId) public onlyOwner {
        super._burn(tokenId, true);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        string memory _tokenURI = generateTokenURI(
            ownership.level,
            ownership.bloodline,
            ownership.sequenceId,
            (ownership.devolved == 1)
        );
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return "";
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenMeta(uint256 tokenId) public view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function addressData(address owner) public view returns (AddressData memory) {
        return _addressData[owner];
    }

    function mintTotal(uint16 level) public view returns (uint16) {
        uint16[5] memory totals = levelMeta[level].survivorMints;
        return (totals[0] + totals[1] + totals[2] + totals[3] + totals[4]);
    }

    function getLevelMintTotals(uint16 level)
        public
        view
        returns (uint16[5] memory survivors, uint16[5] memory zombies)
    {
        survivors = levelMeta[level].survivorMints;
        zombies = levelMeta[level].zombieMints;
        return (survivors, zombies);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        super._deleteDefaultRoyalty();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        require(address(token) != address(0));
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    receive() external payable {}
}
