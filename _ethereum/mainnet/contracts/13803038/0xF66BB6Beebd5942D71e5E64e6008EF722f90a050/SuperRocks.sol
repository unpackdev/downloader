// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";

// Whitelist OpenSea Proxy
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title SuperRocks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract SuperRocks is ERC721Enumerable, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum SaleState {
        Paused,
        Collectors,
        Presale,
        Sale
    }
    SaleState public state;

    // Provenance
    string public provenanceHash = "";
    uint256 public randomStartingIndexBlock;
    uint256 public randomStartingIndex;
    bool public isProvenanceHashFrozen = false;

    // Presale lists
    mapping(address => uint8) private presaleList;
    mapping(address => uint8) private collectorsList;

    // Prices
    uint256 public price = 0.03 ether;

    // Limits
    uint256 public constant MAX_ROCKS = 8888;
    uint256 public constant TEAM_RESERVED_ROCKS_LIMIT = 100;
    uint8 public constant TRANSACTION_MINT_LIMIT = 10;
    uint8 public constant COLLECTORS_MINT_LIMIT = 1;
    uint256 private teamSupply = 0;

    // Metadata
    uint256 public revealTimeStamp;
    string public metadataURI;
    address public proxyRegistryAddress;

    // Team
    // Dev1, Dev2
    address private dev1 = 0x740EBD582c773C8EE050D053B1092b0075367F4A;
    address private dev2 = 0x9d9685eF83fF9bFCeDB6F039116665f14c469745;
    // Community, Marketing, Expenses, Creator
    address[] private teamWallets = [
        0x41cF69033470843fe53A10a36678348EaF474033,
        0x436736639eaACdC344Db6aAe2679858BF419D748,
        0xC3A289a4A4576DA6DA2414B70df7efb367Ea8C89,
        0x5dfD9Ebaf998EDc9d85291e1AF4b2ebF7e2Aae4B
    ];

    address public royaltyAddress = 0x5dfD9Ebaf998EDc9d85291e1AF4b2ebF7e2Aae4B;
    uint256 public royaltyBasis = 500; // 5%

    event Minted(address owner, uint256 tokenId);

    constructor(
        string memory name,
        string memory symbol,
        string memory _placeholderCID,
        address _proxyRegistryAddress
    ) ERC721(name, symbol) {
        metadataURI = _placeholderCID;
        state = SaleState.Paused;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    modifier whenSalePaused() {
        require(state == SaleState.Paused, "SuperRocks: Sale in progress");
        _;
    }

    // === URI ===

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataURI;
    }

    /// Set the base UIR for this collection.
    /// @param uri the new uri.
    /// @dev update the baseURI.
    function setBaseURI(string memory uri) public onlyOwner {
        metadataURI = uri;
    }

    // === Sale State ===

    /// Pause sale.
    function pauseSale() external onlyOwner {
        state = SaleState.Paused;
    }

    function addToPresaleList(address[] memory addresses)
        external
        onlyOwner
        whenSalePaused
    {
        uint256 length = addresses.length;
        for (uint256 i = 0; i < length; i++) {
            presaleList[addresses[i]] = TRANSACTION_MINT_LIMIT;
        }
    }

    function deleteFromPresaleList(address[] memory addresses)
        external
        onlyOwner
        whenSalePaused
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            presaleList[addresses[i]] = 0;
        }
    }

    function presaleListCount(address _address) public view returns (uint8) {
        return presaleList[_address];
    }

    /// Start Presale, if paused.
    function startPresale() external onlyOwner {
        state = SaleState.Presale;
    }

    function addToCollectorsList(address[] memory addresses)
        external
        onlyOwner
        whenSalePaused
    {
        uint256 length = addresses.length;
        for (uint256 i = 0; i < length; i++) {
            collectorsList[addresses[i]] = COLLECTORS_MINT_LIMIT;
        }
    }

    function deleteFromCollectorsList(address[] memory addresses)
        external
        onlyOwner
        whenSalePaused
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            collectorsList[addresses[i]] = 0;
        }
    }

    function collectorsListCount(address _address) public view returns (uint8) {
        return collectorsList[_address];
    }

    /// Start Collectors sale, if paused.
    function startCollectorsSale() external onlyOwner {
        state = SaleState.Collectors;
    }

    /// Start Sale, if paused.
    function startSale(uint256 timeStamp) external onlyOwner {
        state = SaleState.Sale;
        revealTimeStamp = timeStamp;
    }

    // === Minting ===

    function setPrice(uint256 _price) public onlyOwner whenSalePaused {
        require(_price > 0, "SuperRocks: Invalid price");
        price = _price;
    }

    /// Mints SuperRocks
    function mintSuperRock(uint8 numberOfTokens) public payable nonReentrant {
        require(state == SaleState.Sale, "SuperRocks: Minting not allowed");

        uint256 supply = totalSupply();
        require(
            supply + numberOfTokens <= MAX_ROCKS,
            "SuperRocks: More than max supply"
        );

        require(
            numberOfTokens <= TRANSACTION_MINT_LIMIT,
            "SuperRocks: Max 10 tokens"
        );

        require(
            price * numberOfTokens <= msg.value,
            "SuperRocks: Not enough ETH"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
            emit Minted(msg.sender, supply + i);
        }

        // - randomStartingIndexBlock is not already set
        // - the last token in supply or
        // - the first token to be sold after the end of the metadata reveal date
        if (
            randomStartingIndexBlock == 0 &&
            (totalSupply() == MAX_ROCKS || block.timestamp >= revealTimeStamp)
        ) {
            randomStartingIndexBlock = block.number;
        }
    }

    function presaleMintSuperRock(uint8 numberOfTokens)
        public
        payable
        nonReentrant
    {
        require(state == SaleState.Presale, "SuperRocks: Minting not allowed");

        uint256 supply = totalSupply();
        require(
            supply + numberOfTokens <= MAX_ROCKS,
            "SuperRocks: More than max supply"
        );

        require(
            numberOfTokens <= TRANSACTION_MINT_LIMIT,
            "SuperRocks: Max 10 tokens"
        );

        require(
            price * numberOfTokens <= msg.value,
            "SuperRocks: Not enough ETH"
        );

        require(presaleList[msg.sender] > 0, "SuperRocks: Not in presale list");
        require(
            presaleList[msg.sender] - numberOfTokens >= 0,
            "SuperRocks: Reached mint limit"
        );

        presaleList[msg.sender] -= numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
            emit Minted(msg.sender, supply + i);
        }
    }

    function claimSuperRock() public nonReentrant {
        require(
            state == SaleState.Collectors,
            "SuperRocks: Minting not allowed"
        );

        uint256 supply = totalSupply();
        require(supply + 1 <= MAX_ROCKS, "SuperRocks: More than max supply");
        require(collectorsList[msg.sender] > 0, "SuperRocks: Not in the list");
        require(
            collectorsList[msg.sender] - 1 >= 0,
            "SuperRocks: Reached claim limit"
        );

        collectorsList[msg.sender] -= 1;
        _safeMint(msg.sender, supply);
        emit Minted(msg.sender, supply);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensIDs = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensIDs[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensIDs;
    }

    // === Provenance ===

    /// Set provenance hash once it's calculated.
    function setProvenanceHash(string memory provenance) public onlyOwner {
        require(
            isProvenanceHashFrozen == false,
            "SuperRocks: Provenance is frozen"
        );
        provenanceHash = provenance;
    }

    function freezeProvenanceHash() public onlyOwner {
        isProvenanceHashFrozen = true;
    }

    function calculateStartingIndex(uint256 blockNumber)
        internal
        view
        returns (uint256)
    {
        return uint256(blockhash(blockNumber)) % MAX_ROCKS;
    }

    /// Set the random starting index for the collection.
    function setRandomStartingIndex() public {
        require(randomStartingIndex == 0, "SuperRocks: index is set");
        require(randomStartingIndexBlock != 0, "SuperRocks: block must be set");

        randomStartingIndex = calculateStartingIndex(randomStartingIndexBlock);

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - randomStartingIndexBlock > 255) {
            randomStartingIndex = calculateStartingIndex(block.number - 1);
        }

        // Prevent default sequence
        if (randomStartingIndex == 0) {
            randomStartingIndex++;
        }
    }

    /// Set the random starting index block for the collection.
    function emergencySetRandomStartingIndexBlock() public onlyOwner {
        require(randomStartingIndex == 0, "SuperRocks: index is set");
        randomStartingIndexBlock = block.number;
    }

    // === Team Helpers ===

    /// Set some tokens aside for marketing.
    function reserveTeamRocks(uint8 numberOfTokens) public onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + numberOfTokens <= MAX_ROCKS,
            "SuperRocks: More than max supply"
        );
        require(
            teamSupply + numberOfTokens <= TEAM_RESERVED_ROCKS_LIMIT,
            "SuperRocks: Reached team supply"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }

        teamSupply += numberOfTokens;
    }

    function setTeamWallets(address[] memory _teamWallets) public onlyOwner {
        require(_teamWallets.length == 4, "SuperRocks: Needs 4 wallets");
        teamWallets = [
            _teamWallets[0],
            _teamWallets[1],
            _teamWallets[2],
            _teamWallets[3]
        ];
    }

    event SplitsWithdrawn(address[6] _addresses, uint256[6] _amounts);

    /// Split the balance to all wallets.
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "SuperRocks: Nothing to split");

        uint256 split1 = (balance * 15) / 100;
        _widthdraw(dev1, split1);

        uint256 split2 = (balance * 15) / 100;
        _widthdraw(dev2, split2);

        uint256 split3 = (balance * 10) / 100;
        _widthdraw(teamWallets[0], split3);

        uint256 split4 = (balance * 10) / 100;
        _widthdraw(teamWallets[1], split4);

        uint256 split5 = (balance * 5) / 100;
        _widthdraw(teamWallets[2], split5);

        uint256 split6 = address(this).balance;
        _widthdraw(teamWallets[3], split6);

        emit SplitsWithdrawn(
            [
                dev1,
                dev2,
                teamWallets[0],
                teamWallets[1],
                teamWallets[2],
                teamWallets[3]
            ],
            [split1, split2, split3, split4, split5, split6]
        );
    }

    function _widthdraw(address to, uint256 _amount) private {
        (bool success, ) = to.call{value: _amount}("");
        require(success, "SuperRocks: Transfer failed");
    }

    // === OpenSea Proxy ===

    /// Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// Update the registry address in case of an error.
    function setProxyRegistryAddress(address _proxyRegistryAddress)
        public
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // === Royalties ===

    function setRoyalty(address _royaltyAddress, uint256 _royaltyBasis)
        public
        onlyOwner
    {
        royaltyAddress = _royaltyAddress;
        royaltyBasis = _royaltyBasis;
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyAddress, (salePrice * royaltyBasis) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}
