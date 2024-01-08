// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/*

..................................................
..................................................
..................................................
..................................................
..................................................
...............                    ...............
...............                    ...............
...............                    ...............
...............      MANIFEST      ...............
...............                    ...............
...............                    ...............
...............                    ...............
...................................
...................................
...................................
...................................
...................................

*/

contract Manifest is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 public constant MAX_MANIFESTS = 1_000;

    // Public sale params
    uint256 public maxPerTransaction = 20;
    uint256 public manifestPrice = 0.07 ether;
    bool public publicSaleActive;

    // Provenance + Fairness
    string public baseURI;
    string public provenanceHash;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public revealTimestamp;

    event ProvenanceSubmitted(
        string provenanceHash,
        uint256 timestamp
    );
    event BaseURISubmitted(
        string baseURI,
        uint256 timestamp
    );

    modifier whenPublicSaleActive {
        require(publicSaleActive, "Public sale not active");
        _;
    }

    constructor() ERC721("Manifest", "MANI") {
        // Mint 30 for airdrops and giveaways.
        for(uint i = 0; i < 30; i++) {
            _safeMint(0x9221966c2575F5EE2C4c0510F8c14A185e01D494, totalSupply() + 1);
        }
    }

    function mintManifest(uint256 purchaseAmount)
        external
        payable
        whenPublicSaleActive
        nonReentrant
    {
        require(purchasableSupply() > 0, "Sold out");

        if (purchaseAmount > purchasableSupply()) {
            purchaseAmount = purchasableSupply();
        }

        if (purchaseAmount > maxPerTransaction) {
            purchaseAmount = maxPerTransaction;
        }

        uint256 totalCost = purchaseAmount*manifestPrice;
        require(msg.value >= totalCost, "Not enough ETH sent");

        for(uint i = 0; i < purchaseAmount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }

        // Refund any extra ETH sent.
        if (msg.value > totalCost) {
            Address.sendValue(payable(msg.sender), msg.value - totalCost);
        }

        _setStartingIndexBlock();
    }

    function togglePublicSaleActive() external onlyOwner {
        if (revealTimestamp == 0) {
            revealTimestamp = block.timestamp + (86400 * 7);
        }

        publicSaleActive = !publicSaleActive;
    }

    // In case we need to bring the reveal forward.
    function setReveal(uint256 timestamp) external onlyOwner {
        revealTimestamp = block.timestamp + timestamp;
    }

    function setStartingIndex() external {
        require(startingIndex == 0, "Starting index already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_MANIFESTS;

        if ((block.number - startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_MANIFESTS;
        }

        if (startingIndex == 0) {
            startingIndex += 1;
        }
    }

    function setProvenance(string memory provenance)
        external
        onlyOwner
    {
        provenanceHash = provenance;
        emit ProvenanceSubmitted(provenance, block.timestamp);
    }

    function setBaseURI(string memory uri)
        external
        onlyOwner
    {
        baseURI = uri;
        emit BaseURISubmitted(uri, block.timestamp);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function purchasableSupply() public view returns(uint256) {
        return (MAX_MANIFESTS - totalSupply());
    }

    // Set the starting index block once all public supply has been minted or
    // 1 week after public sale begins.
    function _setStartingIndexBlock() internal {
        bool timeToReveal = block.timestamp > revealTimestamp;
        bool soldOut = totalSupply() == MAX_MANIFESTS;

        if (startingIndexBlock == 0 && soldOut || timeToReveal) {
            startingIndexBlock = block.number;
        }
    }

    function _baseURI() internal view override returns(string memory) {
        return baseURI;
    }
}
