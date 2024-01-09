//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

//   __________________    _____  .___.____     __________
//  /  _____/\______   \  /  _  \ |   |    |    \____    /
// /   \  ___ |       _/ /  /_\  \|   |    |      /     / 
// \    \_\  \|    |   \/    |    \   |    |___  /     /_ 
//  \______  /|____|_  /\____|__  /___|_______ \/_______ \
//         \/        \/         \/            \/        \/

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./console.sol";

import "./ERC721EnumerableChance.sol";


contract GrailzNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for string;
    using Counters for Counters.Counter;

    //  ##############
    //  # Initialize #
    //  ##############
    // 
    // * Enforce supply and price
    // * Control mint access
    // * Control base token URI
    //
    uint256 public constant GRAILZ_SUPPLY = 10000;
    uint256 public constant grailzPrice = 0.04 ether;
    uint256 public constant whitelistPrice = 0.01 ether;

    // 10 + 1 so that we can use less than operator
    uint256 public constant mintMax = 11;
    string public baseTokenURI;
    bool private isMintOpen = false;

    // Keep track of MINTED amount, not just total like _owners does
    mapping(address => uint256) private minted;

    // whitelist
    mapping(address => bool) private whitelistedAccounts;

    // Fairness guarantees
    string public GRAILZ_PROVENANCE;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    // address to retrieve balance
    address private _accounting;

    // Proxy approval for OpenSea
    address public proxyRegistryAddress;
    mapping(address => bool) public projectProxy;

    //  ##########
    //  # Events #
    //  ##########
    event PauseMint();
    event OpenMint();
    event ChangeBaseURL(string baseUrl);
    
    // ########################
    // # Safety and Modifiers #
    // ########################
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }


    function hasSupply(uint256 numberOfTokens) public view returns (bool) {
        return totalSupply() + numberOfTokens < GRAILZ_SUPPLY;
    }

    function isUnpausedAndSupplied() public view returns (bool) {
        return (hasSupply(1)) && (isMintOpen);
    }
    
    function canMint(uint256 numberOfTokens) public view returns (bool) {
        return (
            (isMintOpen) && 
            hasSupply(numberOfTokens) && 
            (minted[msg.sender] + numberOfTokens < mintMax)
        );
    }

    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        // DO NOT USE THIS INTERNALLY, VIEW ONLY
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf(i) == address(0x0) && _tokens[_balance - 1] == 0) { _loopThrough++; }
            if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
        }
        return _tokens;
    }

    modifier saleIsOpen {
        require(hasSupply(1), "Grailz Sold Out!");
        require(isMintOpen, "Sales not open");
        _;
    }

    // #####################
    // # Control Mint Open #
    // #####################
    function setPauseMint() public onlyOwner{
        isMintOpen = false;
        emit PauseMint();
    }

    function setOpenMint() public onlyOwner{
        isMintOpen = true;
        emit OpenMint();
    }

    function addToWhitelist(address targetAccount) public onlyOwner{
        whitelistedAccounts[targetAccount] = true;
    }

    function isWhitelisted() public view returns (bool) {
        return whitelistedAccounts[msg.sender];
    }

    // ############
    // # Fairness #
    // ############

    // This is exposed so that supporters can verify that the original order of
    // the tokens has not been tampered with
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        GRAILZ_PROVENANCE = provenanceHash;
    }

    // It has gone wrong and the presale didn't fully mint so this allows us to reveal
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }

    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % GRAILZ_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % GRAILZ_SUPPLY;
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit ChangeBaseURL(baseTokenURI);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    // # # # # # # # # # # #
    // # # # # # # # # # # #
    //    CONTRACT START
    // # # # # # # # # # # #
    // # # # # # # # # # # #
    constructor(
        string memory name,
        string memory baseURI, 
        address _accountingAddress,
        address _proxyRegistryAddress
    ) ERC721(name, name) {
        setBaseURI(baseURI);
        _accounting = _accountingAddress;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function getAddressPrice() public view returns (uint256) {
        if (whitelistedAccounts[msg.sender]) {
            return whitelistPrice;
        } else {
            return grailzPrice;
        }
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function mintGrailz(uint256 numberOfTokens) public payable saleIsOpen nonReentrant() {
        require(hasSupply(numberOfTokens), "Purchase exceeds avaialable");
        require(minted[msg.sender] + numberOfTokens < mintMax, "Max of 10 tokens per address");

        if (whitelistedAccounts[msg.sender]) {
            require(whitelistPrice * numberOfTokens <= msg.value, "ETH sent in transaction too low");
        } else {
            require(grailzPrice * numberOfTokens <= msg.value, "ETH sent in transaction too low");
        }
        
        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }

        minted[msg.sender] += numberOfTokens;

        // Set on last mint
        if (totalSupply() == GRAILZ_SUPPLY) {
            startingIndexBlock = block.number;
        }
    }
    
    // ##################
    // # Web3 Economics #
    // ##################
    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdrawAll() public {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(_accounting, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}