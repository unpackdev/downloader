pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

/**
 * Thingdoms, 2021.
 * Scotland, UK.
 */

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Counters.sol";
import "./console.sol";
import "./ERC721URIStorage.sol";

contract Thingdoms is ERC721Upgradeable, OwnableUpgradeable {
    using Counters for Counters.Counter;

    uint256 public constant THING_PRICE = 0.1 ether;
    uint8 public constant MAX_PUBLIC_MINTS = 5;
    uint8 public constant MAX_ALLOWLIST_MINTS = 2;

    uint16 public MAX_THINGS;
    uint16 public reservedTokens;
    bool public saleIsActive;
    bool public allowListSaleIsActive;
    bytes32 public merkleRoot;

    string private baseURI;

    /*
     * Creates a map of key: address, value: number allowed to mint
     */
    mapping(address => uint8) private _userMints;

    Counters.Counter public tokenSupply;

    uint256[] private _allTokens;

    function initialize(
        string calldata collectionName,
        string calldata tokenName,
        uint16 maxNumber,
        bytes32 _merkleRoot
    ) public initializer {
        __ERC721_init(collectionName, tokenName);
        __Ownable_init();
        baseURI = "https://thingdoms-server.herokuapp.com/pre-reveal-metadata/";
        reservedTokens = 360;
        saleIsActive = false;
        allowListSaleIsActive = false;
        merkleRoot = _merkleRoot;
        MAX_THINGS = maxNumber;
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

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(
            index < _allTokens.length,
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /*
     * Set the number of reserved tokens
     */
    function setReservedTokens(uint16 reservedNumber) external onlyOwner {
        require(
            reservedNumber <= MAX_THINGS - tokenSupply.current(),
            "Not enough things left to reserve that amount"
        );
        reservedTokens = reservedNumber;
    }

    /*
     * Start the allow list sale
     */
    function startAllowListSale() external onlyOwner {
        require(
            allowListSaleIsActive == false,
            "Allow list sale already started"
        );
        allowListSaleIsActive = true;
    }

    /*
     * Pause the allow list sale
     */
    function pauseAllowListSale() external onlyOwner {
        require(
            allowListSaleIsActive == true,
            "Allow list sale already paused"
        );
        allowListSaleIsActive = false;
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
     * Get the number of already minted tokens for an address on the whitelist
     */
    function getMintsForAddress(address _address)
        external
        view
        onlyOwner
        returns (uint8)
    {
        return _userMints[_address];
    }

    /*
     * Mints tokens to the allowList users
     */
    function mintAllowList(uint8 numberOfTokens, bytes32[] calldata proof)
        external
        payable
    {
        uint256 supply = tokenSupply.current();
        require(allowListSaleIsActive, "Allow list sale is not active");
        require(
            _userMints[msg.sender] + numberOfTokens <= MAX_ALLOWLIST_MINTS,
            "Exceeded mints per allowList user"
        );
        require(
            THING_PRICE * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );
        require(isWhitelisted(msg.sender, proof), "Invalid proof");

        _userMints[msg.sender] += numberOfTokens;
        for (uint8 i = 1; i <= numberOfTokens; i++) {
            tokenSupply.increment();
            _allTokens.push(supply + i);
            _safeMint(msg.sender, supply + i);
        }
    }

    /*
     * Mints a given number of tokens
     */
    function mint(uint8 numberOfTokens) external payable {
        uint256 supply = tokenSupply.current();
        require(saleIsActive, "Sale is not active");
        require(
            _userMints[msg.sender] + numberOfTokens <= MAX_PUBLIC_MINTS,
            "Exceeded mints per user"
        );
        require(
            supply + numberOfTokens <= MAX_THINGS,
            "Not enough things left"
        );
        require(
            THING_PRICE * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _userMints[msg.sender] += numberOfTokens;
        for (uint8 i = 1; i <= numberOfTokens; i++) {
            tokenSupply.increment();
            _allTokens.push(supply + i);
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * Give away a number of tokens from the reserved amount to an address
     */
    function giveAway(address _to, uint16 _amount) external onlyOwner {
        require(_amount <= reservedTokens, "Exceeds reserved Thing supply");

        uint256 supply = tokenSupply.current();
        for (uint16 i = 1; i <= _amount; i++) {
            tokenSupply.increment();
            _allTokens.push(supply + i); // supply + i is the TOKEN_ID
            _safeMint(_to, supply + i);
        }

        reservedTokens -= _amount;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function isWhitelisted(address address_, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof.length; i++) {
            leaf = leaf <= proof[i]
                ? keccak256(abi.encodePacked(leaf, proof[i]))
                : keccak256(abi.encodePacked(proof[i], leaf));
        }
        return leaf == merkleRoot;
    }

    /*
     * Withdraw the money from the contract
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
