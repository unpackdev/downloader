pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

/**
 * NFT Contract, 2022.
 * Scotland, UK.
 *    ___  __________ ___  __
 *   / _ \/  _/ __/ //_| \/ /
 *  / , _// /_\ \/ ,<   \  /
 * /_/|_/___/___/_/|_|__/_/_  _  __
 *  / ___/ _ \/ _ \ \/ / __ \/ |/ /
 * / /__/ , _/ __ |\  / /_/ /    /
 * \___/_/|_/_/ |_|/_/\____/_/|_/
 * by Risky Crayon.
 */

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Counters.sol";

contract NFTContract is ERC721Upgradeable, OwnableUpgradeable {
    using Counters for Counters.Counter;

    uint256 public tokenPrice;
    uint256 public maxMintsPerUser;
    uint256 public maxTokens;
    bool public saleIsActive;
    string private baseURI;

    Counters.Counter public tokenSupply;

    uint256[] private _allTokens;
    /*
     * Creates a map of key: address, value: number allowed to mint
     */
    mapping(address => uint8) private _userMints;
    /*
     * Creates a map of key: address, value: a map of key: tokenID, value: # mints
     */
    mapping(address => mapping(uint256 => uint256)) public usedEligibleMints;

    function initialize(
        string calldata collectionName,
        string calldata tokenName,
        uint256 _maxTokens,
        uint256 _tokenPrice,
        uint256 _maxMintsPerUser,
        string calldata _uri
    ) public initializer {
        __ERC721_init(collectionName, tokenName);
        __Ownable_init();
        saleIsActive = false;
        baseURI = _uri;
        maxTokens = _maxTokens;
        tokenPrice = _tokenPrice;
        maxMintsPerUser = _maxMintsPerUser;
    }

    /*
     * Allows for changing the number of tokens available to mint
     */
    function setMaxTokens(uint256 _maxTokens) external onlyOwner {
        uint256 supply = tokenSupply.current();
        require(_maxTokens >= supply, "Max cannot be less than supply");
        maxTokens = _maxTokens;
    }

    /*
     * Allows for changing the token price while minting
     */
    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    /*
     * Allows for changing the maximum number of tokens a user can mint
     */
    function setMaxMintsPerUser(uint256 _maxMintsPerUser) external onlyOwner {
        maxMintsPerUser = _maxMintsPerUser;
    }

    /*
     * Sets the baseURI for all tokens metadata
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /*
     * Getter for the baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*
     * Returns total number of existing tokens. Only used in test
     */
    function totalSupply() public view returns (uint256) {
        return tokenSupply.current();
    }

    /*
     * Start the general sale
     */
    function startSale() external onlyOwner {
        require(saleIsActive == false, "Sale already started");
        saleIsActive = true;
    }

    /*
     * Pause the general sale
     */
    function pauseSale() external onlyOwner {
        require(saleIsActive == true, "Sale already paused");
        saleIsActive = false;
    }

    /*
     * Mints a given number of tokens
     */
    function mint(uint8 numberOfTokens) external payable {
        uint256 supply = tokenSupply.current();
        require(saleIsActive, "Sale is not active");
        require(
            _userMints[msg.sender] + numberOfTokens <= maxMintsPerUser,
            "Exceeded mints per user"
        );
        require(supply + numberOfTokens <= maxTokens, "Not enough tokens left");
        require(
            tokenPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _userMints[msg.sender] += numberOfTokens;
        for (uint8 i = 1; i <= numberOfTokens; i++) {
            tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * Give away a number of tokens from the reserved amount to an address
     */
    function giveAway(address _to, uint16 _amount) external onlyOwner {
        uint256 supply = tokenSupply.current();
        require(_amount + supply <= maxTokens, "Not enough tokens left");
        for (uint16 i = 1; i <= _amount; i++) {
            tokenSupply.increment();
            _safeMint(_to, supply + i);
        }
    }

    /*
     * Withdraw the money from the contract
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }
}
