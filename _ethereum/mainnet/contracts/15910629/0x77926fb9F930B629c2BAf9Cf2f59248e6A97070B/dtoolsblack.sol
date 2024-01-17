// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract dToolsBlack is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // contract dynamics
    string public baseURI;
    uint256 public immutable totalSupply;
    uint256 public allowListDtoolsGoldSupply;
    uint256 public publicInitialSupply;

    // mint dynamics
    uint256 public maxSaleMint = 1;
    uint256 public mintPricePublicInitial = 800000000000000000; // 0.80 ETH
    uint256 public mintPriceDtoolsGold = 600000000000000000; // 0.60 ETH

    // we setup two maps to track the minting by wallets
    mapping(address => bool) private _allowListDtoolsGold;
    mapping(address => bool) private _hasMinted;

    mapping(address => string) public telegramUsername;

    // state of mint dynamics
    bool public initialSaleIsActive = false; 
    bool public hasBurnedUnsoldEndOfDay = false; 

    // counters for faster use by frontend
    Counters.Counter private totalMintedCounter;
    Counters.Counter private allowListMintedCounter;
    Counters.Counter private publicMintedCounter;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _totalSupply
    ) ERC721(_name, _symbol) {
        baseURI = _baseTokenURI;
        totalSupply = _totalSupply;
        publicInitialSupply = _totalSupply;
        doMint();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // dtools gold discount
    function setAllowListDtoolsGold(address[] calldata dtoolsGoldAddr) external onlyOwner {
        for (uint256 i = 0; i < dtoolsGoldAddr.length; i++) {
            _allowListDtoolsGold[dtoolsGoldAddr[i]] = true;
            allowListDtoolsGoldSupply += 1;
            publicInitialSupply -= 1;
        }
    }

    // start initial sale
    function toggleInitialSaleState() external onlyOwner {
        require(!initialSaleIsActive, "Too late in cycle.");
        initialSaleIsActive = true;
    }

    // burn any unsold nfts end of day
    function burnUnsoldTokens() external onlyOwner {
        hasBurnedUnsoldEndOfDay = true;
        initialSaleIsActive = false;
    }

    function mint() public payable nonReentrant {
        require(totalMintedCounter.current() < totalSupply, "Minted out.");
        require(initialSaleIsActive, "Mint not open.");
        require(!hasBurnedUnsoldEndOfDay, "Sale period has ended, all unsold NFTs were burned.");
        require(!hasMinted(_msgSender()), "You've minted, ser.");

        if (hasAllowList(_msgSender())) {
            require( // we'll never not satisfy this if hasMinted guard works
                allowListMintedCounter.current() < allowListDtoolsGoldSupply,
                "AllowList minted out."
            );
            require(
                msg.value >= mintPriceDtoolsGold,
                "Send more ether for allowlist."
            );
            doMint();
            allowListMintedCounter._value += 1;
            return;
        }
        require(
            publicMintedCounter.current() < publicInitialSupply,
            "Public minted out."
        );
        require(
            msg.value >= mintPricePublicInitial,
            "Send more ether for public."
        );
        doMint();
        publicMintedCounter._value += 1;
    }

    // Returns the current amount of NFTs minted in total.
    function totalMinted() public view returns (uint256) {
        return totalMintedCounter.current();
    }

    // Returns the current amount of NFTs minted from the allow list tranche.
    function allowListMinted() public view returns (uint256) {
        return allowListMintedCounter.current();
    }

    // Returns the current amount of NFTs minted from the public tranche.
    function publicMinted() public view returns (uint256) {
        return publicMintedCounter.current();
    }

    // Returns whether the address is on the allow list
    function hasAllowList(address _addy) public view returns (bool) {
        return _allowListDtoolsGold[_addy];
    }

    // Returns whether the address has minted
    function hasMinted(address _addy) public view returns (bool) {
        return _hasMinted[_addy];
    }

    // helper function to do the mint
    function doMint() internal {
        _safeMint(_msgSender(), (totalMintedCounter.current() + 1));
        totalMintedCounter._value += 1;
        _hasMinted[_msgSender()] = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // user sets telegram username to gain access to dapp
    // mechanism will be moved to seperate contract in the
    // future that allows user to rent out their utility
    // to other people.
    function setTelegramUsername(string memory _username) public {
        telegramUsername[msg.sender] = _username;
    }
}