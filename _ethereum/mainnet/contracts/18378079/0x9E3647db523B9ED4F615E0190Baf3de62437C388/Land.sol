// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

error InsufficientBalance();

contract WincityLand is ERC721A, Pausable, Ownable {
    enum LandType {
        AFRICA,
        AMERICA,
        ASIA,
        EUROPE
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Constants
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    uint256 public constant LIMIT_DECIMALS = 10 ** 9; // Use 9 decimals for precision.

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Variables
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    string private _tokenBaseURI;

    uint256 public cycle = 2 hours;
    uint256 public limit = (10 * LIMIT_DECIMALS) / 100;
    uint256 public mintPrice = 0.034 ether;
    uint256 public reservedSupply = 0;
    uint256 public steepModifier = 0;

    // Public mint starting time in seconds
    uint256 public publicSaleStartTimestamp;
    uint256[] public mintTimestamps;

    bytes32 public freeMintMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    // Mapping to keep track of whitelist addresses that have already been claimed
    mapping(address => bool) private freeMintClaimed;

    // Mapping to keep track of which tokenId is which LandType
    mapping(uint256 => LandType) public landTypeTokens;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Events
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    event MintMessage(
        address to,
        uint256[] tokenIds,
        uint256 quantity,
        LandType landType,
        uint256 totalPrice
    );

    event AdminMintMessage(
        address to,
        uint256[] tokenIds,
        uint256 quantity,
        LandType landType
    );

    event ClaimFreeMint(address to, uint256 tokenId, LandType landType);

    constructor(string memory _uri) ERC721A("WincityLand", "WLAND") {
        _tokenBaseURI = _uri;
        uint256[] memory africaTokens = _handleMint(
            msg.sender,
            LandType.AFRICA,
            300,
            true
        );
        uint256[] memory americaTokens = _handleMint(
            msg.sender,
            LandType.AMERICA,
            300,
            true
        );
        uint256[] memory asiaTokens = _handleMint(
            msg.sender,
            LandType.ASIA,
            300,
            true
        );
        uint256[] memory europeTokens = _handleMint(
            msg.sender,
            LandType.EUROPE,
            300,
            true
        );

        reservedSupply += 1200;

        emit AdminMintMessage(msg.sender, africaTokens, 300, LandType.AFRICA);
        emit AdminMintMessage(msg.sender, americaTokens, 300, LandType.AMERICA);
        emit AdminMintMessage(msg.sender, asiaTokens, 300, LandType.ASIA);
        emit AdminMintMessage(msg.sender, europeTokens, 300, LandType.EUROPE);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Modifiers
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    modifier whenPublicSaleActive() {
        require(isPublicSaleOpen(), "Public sale not opened.");
        _;
    }
    modifier whenPreSaleActive() {
        require(isPreSaleOpen(), "Presale not opened.");
        _;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Getters / Setters
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function isPublicSaleOpen() public view returns (bool) {
        return
            block.timestamp >= publicSaleStartTimestamp &&
            publicSaleStartTimestamp != 0;
    }

    function isPreSaleOpen() public view returns (bool) {
        return
            publicSaleStartTimestamp > 0
                ? block.timestamp >= (publicSaleStartTimestamp - 1 hours)
                : false;
    }

    function isWhitelisted(
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    function isFreeMintEligible(
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        if (freeMintClaimed[msg.sender] == true) {
            return false;
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        return MerkleProof.verify(_merkleProof, freeMintMerkleRoot, leaf);
    }

    function landTypeOf(uint256 _tokenId) public view returns (LandType) {
        return landTypeTokens[_tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Setters (Ownable)
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function setPublicSaleTimestamp(uint256 _timestamp) external onlyOwner {
        publicSaleStartTimestamp = _timestamp;
    }

    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        mintPrice = _newMintPrice;
    }

    function setCycle(uint256 _newCycle) external onlyOwner {
        cycle = _newCycle;
    }

    function setSteepModifier(uint256 _newSteepModifier) external onlyOwner {
        steepModifier = _newSteepModifier;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setFreeMintMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        freeMintMerkleRoot = _merkleRoot;
    }

    function setURI(string calldata _newURI) external onlyOwner {
        _tokenBaseURI = _newURI;
    }

    function resetMintTimestamps() external onlyOwner {
        delete mintTimestamps;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Admin
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function adminMint(
        address _recipient,
        LandType _landType,
        uint256 _quantity
    ) external onlyOwner {
        reservedSupply += _quantity;

        uint256[] memory mintedTokens = _handleMint(
            _recipient,
            _landType,
            _quantity,
            true
        );

        emit AdminMintMessage(_recipient, mintedTokens, _quantity, _landType);
    }

    function updateLimit(uint8 _limit) external onlyOwner {
        require(
            _limit <= 100,
            "Invalid percentage. Limit must be comprised between 0 and 100"
        );

        limit = (_limit * LIMIT_DECIMALS) / 100;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Minting
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function cleanCurrentCycleSupply() internal {
        // If the most recent mint is older than one cycle, clear the whole array.
        if (
            mintTimestamps.length > 0 &&
            mintTimestamps[mintTimestamps.length - 1] <= block.timestamp - cycle
        ) {
            delete mintTimestamps;
            return;
        }

        // Update currentCycleSupplyCount and mintTimestamps to match the correct cycle supply at mint time.
        while (
            mintTimestamps.length > 0 &&
            mintTimestamps[0] <= block.timestamp - cycle
        ) {
            // Remove the oldest timestamp.
            for (uint256 i = 0; i < mintTimestamps.length - 1; i++) {
                mintTimestamps[i] = mintTimestamps[i + 1];
            }
            mintTimestamps.pop();
        }
    }

    function getCurrentCycleSupply(
        uint256 _timestamp
    ) public view returns (uint256) {
        uint256 currentCycleSupply = 0;

        for (uint256 i = 0; i < mintTimestamps.length; i++) {
            if (mintTimestamps[i] + cycle > _timestamp) currentCycleSupply++;
        }

        return currentCycleSupply;
    }

    function computeMintPrice(
        uint256 _quantity,
        uint256 _timestamp
    ) public view returns (uint256) {
        // Prevent price scale while first cycle isn't elapsed.
        if (_timestamp < publicSaleStartTimestamp + 2 hours) {
            return mintPrice * _quantity;
        }

        uint256 computedPrice = 0;
        uint256 currentCycleSupply = getCurrentCycleSupply(_timestamp);

        for (uint8 i = 0; i < _quantity; i++) {
            uint256 cycleSupply = (currentCycleSupply + i) * LIMIT_DECIMALS;
            uint256 supply = ((totalSupply() - reservedSupply) -
                currentCycleSupply +
                i) + steepModifier;

            // Calculate proportion of emitted NFT for the ongoing cycle
            uint256 z = (((cycleSupply * 100) / supply)) / 100;

            // Ensure proportion can't overflow the mint limit.
            if (z > limit) z = limit - 1;

            uint256 variance = (((limit * LIMIT_DECIMALS) / (limit - z))) *
                LIMIT_DECIMALS;

            // Compute mint price via current cycle emission against max cycle emission (limit).
            computedPrice += mintPrice + variance - (1 * (LIMIT_DECIMALS ** 2));
        }

        return computedPrice;
    }

    function _handleMint(
        address recipient,
        LandType _landType,
        uint256 _quantity,
        bool _isAdmin
    ) private whenNotPaused returns (uint256[] memory) {
        uint256 firstToken = _nextTokenId();

        // Process minting.
        _safeMint(recipient, _quantity);

        uint256[] memory mintedTokens = new uint256[](_quantity);

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = i + firstToken;
            landTypeTokens[tokenId] = _landType;
            mintedTokens[i] = tokenId;

            // Add newest mint to last cycle count to be evaluated on next mint price.
            if (
                block.timestamp < publicSaleStartTimestamp + 2 hours ||
                !_isAdmin
            ) {
                mintTimestamps.push(block.timestamp);
            }
        }

        return mintedTokens;
    }

    function _purchaseMint(
        LandType _landType,
        uint256 _quantity
    ) internal whenNotPaused {
        require(
            _quantity > 0 && _quantity <= 10,
            "Quantity must be comprised between 1 and 10"
        );

        uint totalMintPrice = 0;

        // Ensure computed mint price to be exact.
        cleanCurrentCycleSupply();
        totalMintPrice = computeMintPrice(_quantity, block.timestamp);

        // Ensure sender sent enough ether to mint.
        if (msg.value < totalMintPrice) {
            revert InsufficientBalance();
        }

        uint256[] memory mintedTokens = _handleMint(
            msg.sender,
            _landType,
            _quantity,
            false
        );

        emit MintMessage(
            msg.sender,
            mintedTokens,
            _quantity,
            _landType,
            totalMintPrice
        );

        // Refund excess ether.
        uint256 refund = msg.value - totalMintPrice;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    function mint(
        LandType _landType,
        uint256 _quantity
    ) external payable whenPublicSaleActive whenNotPaused {
        _purchaseMint(_landType, _quantity);
    }

    function preMint(
        LandType _landType,
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    ) external payable whenPreSaleActive whenNotPaused {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Address is not whitelisted."
        );

        _purchaseMint(_landType, _quantity);
    }

    function freeMint(
        LandType _landType,
        bytes32[] calldata _merkleProof
    ) external whenPreSaleActive whenNotPaused {
        require(
            freeMintClaimed[msg.sender] == false,
            "Address has already claimed."
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, freeMintMerkleRoot, leaf),
            "Address is not whitelisted."
        );

        freeMintClaimed[msg.sender] = true;
        uint256 tokenId = _nextTokenId();

        _safeMint(msg.sender, 1);

        landTypeTokens[tokenId] = _landType;

        emit ClaimFreeMint(msg.sender, tokenId, _landType);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Withdrawls
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function withdrawAmount(
        address payable recipient,
        uint256 amount
    ) external onlyOwner {
        (bool succeed, ) = recipient.call{value: amount}("");
        require(succeed, "Failed to withdraw Ether");
    }
}
