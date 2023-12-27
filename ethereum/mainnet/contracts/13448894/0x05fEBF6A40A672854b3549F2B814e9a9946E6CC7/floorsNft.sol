// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";


interface ISpacePunksTreasureKeys {
    function burnKeyForAddress(uint256 typeId, address burnTokenAddress) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract FloorNFT is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public maxMintsPerTxn = 5;

    uint256 public constant TREASURE_KEYS_LIMIT = 350;

    uint256 public mintPrice = 0.07 ether;

    bool public saleIsActive = false;

    bool public preSaleIsActive = false;

    bool public buildingIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    address public _withdrawalWallet;

    address private _manager;

    mapping (address => bool) public presaleWallets;

    event FloorBuilt(uint256 firstTokenId, uint256 secondTokenId, uint256 builtFloorTokenId);

    event PaymentReleased(address to, uint256 amount);

    event EthClaimed(address to, uint256 amount);

    event PreSaleMint(address owner, uint qty);

    constructor(string memory name, string memory symbol, uint256 maxFloorSupply) ERC721(name, symbol) {
        maxTokenSupply = maxFloorSupply;
        _withdrawalWallet = 0x495192b1718475F1e3619Efd3c7d9A8ba3ef6F63;
    }

    function setWithdrawalWallet(address _wallet) public onlyOwner {
        _withdrawalWallet = _wallet;
    }

    function setMaxMintsPerTxn(uint256 amount) public onlyOwner {
        maxMintsPerTxn = amount;
    }

    function setMaxTokenSupply(uint256 maxFloorSupply) public onlyOwner {
        maxTokenSupply = maxFloorSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        require(payable(_withdrawalWallet).send(amount));

        emit PaymentReleased(_withdrawalWallet, amount);
    }

    /*
    | Reserve to contract creator
    */
    function reserveMint(uint256 reservedAmount) public onlyOwner {
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(msg.sender, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    | Mint to address, eg. giveaway
    */
    function mintToAddress(uint256 reservedAmount, address mintAddress) public onlyOwner {
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    | Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    | Pause pre-sale if active, make active if paused.
    */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /*
    | Set presale wallets
    */
    function setPresaleWallets(address[] memory _a) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            presaleWallets[_a[i]] = true;
        }
    }

    function cleanPresaleWallets(address[] memory _a) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            presaleWallets[_a[i]] = false;
        }
    }

    function buyPresale(uint numberOfTokens) external payable {
        require(preSaleIsActive, "Presale is not active");
        require(numberOfTokens <= maxMintsPerTxn, "You can not mint that many at a time");
        require(totalSupply() + numberOfTokens <= maxTokenSupply - TREASURE_KEYS_LIMIT, "Purchase would exceed max available floors");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(presaleWallets[msg.sender] == true, "You are not in the presale whitelist");
        for(uint i = 0; i < numberOfTokens; i++){
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            _safeMint(msg.sender, mintIndex);
            _tokenIdCounter.increment();
        }
        emit PreSaleMint(msg.sender, numberOfTokens);
    }

    /*
    | Pause building if active, make active if paused.
    */
    function flipBuildingState() public onlyOwner {
        buildingIsActive = !buildingIsActive;
    }

    /*
    | Mint Floor NFTs
    */
    function mintFloors(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint floors");
        require(numberOfTokens <= maxMintsPerTxn, "You can not mint that many at a time");
        require(totalSupply() + numberOfTokens <= maxTokenSupply - TREASURE_KEYS_LIMIT, "Purchase would exceed max available floors");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }

        // If we haven't set the starting index, set the starting index block.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }

    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }

    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller is not the owner or manager");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Set the starting index for the collection.
     */
    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % maxTokenSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % maxTokenSupply;
        }
        // Prevent default sequence.
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    /**
     * Set the starting index block for the collection. Usually, this will be set after the first sale mint.
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    /*
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    function buildFloor(uint256 firstTokenId, uint256 secondTokenId) public {
        require(buildingIsActive && !saleIsActive, "Either sale is currently active or building is inactive");
        require(_isApprovedOrOwner(_msgSender(), firstTokenId) && _isApprovedOrOwner(_msgSender(), secondTokenId), "Caller is not owner nor approved");

        _burn(firstTokenId);
        _burn(secondTokenId);

        uint256 builtFloorTokenId = _tokenIdCounter.current() + 1;
        _safeMint(msg.sender, builtFloorTokenId);
        _tokenIdCounter.increment();

        emit FloorBuilt(firstTokenId, secondTokenId, builtFloorTokenId);
    }

    function mintWithTreasureKey() external {
        ISpacePunksTreasureKeys keys = ISpacePunksTreasureKeys(0x4bc87F553fcE25bd613a7C31b17d6D224A84c7bF);

        require(keys.balanceOf(msg.sender, 7) > 0, "SPC Treasure Keys: must own at least one key");

        keys.burnKeyForAddress(7, msg.sender);
        _mintWithSpacePunksTreasureKey(msg.sender);
    }

    function _mintWithSpacePunksTreasureKey(address _to) private {
        uint256 mintIndex = _tokenIdCounter.current() + 1;
        if (mintIndex <= maxTokenSupply) {
            _safeMint(_to, mintIndex);
            _tokenIdCounter.increment();
        }
    }
}