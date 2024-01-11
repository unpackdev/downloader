// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
 * @title AITG NFT Contract
 * @author Lem Canady, Nazariy Dumanskyy
 *        ___                                       ___
 *       /\  \                                     /\__\
 *      /::\  \        ___            ___         /:/ _/_
 *     /:/\:\  \      /\__\          /\__\       /:/ /\  \
 *    /:/ /::\  \    /:/__/         /:/  /      /:/ /::\  \
 *   /:/_/:/\:\__\  /::\  \        /:/__/      /:/__\/\:\__\
 *   \:\/:/  \/__/  \/\:\  \__    /::\  \      \:\  \ /:/  /
 *    \::/__/        ~~\:\/\__\  /:/\:\  \      \:\  /:/  /
 *     \:\  \           \::/  /  \/__\:\  \      \:\/:/  /
 *      \:\__\          /:/  /        \:\__\      \::/  /
 *       \/__/          \/__/          \/__/       \/__/
 *
 *
 * ERC1155 NFT Contract
 */

import "./ERC1155.sol";
import "./Strings.sol";
import "./BaseAITG.sol";

contract AITGNFT is BaseAITG {
    uint256 constant COMMON = 0;
    uint256 constant RARE = 1;
    uint256 public publicPrice = 150000000000000000;
    uint256 public wlPrice = 150000000000000000;
    uint256 public totalCount = 0;
    uint256[] public maxSupply;
    uint256 public  maxPerTx = 5;

    bool public publicMintOpen = false;
    bool public wlMintOpen = true;

    mapping(address => bool) public whiteList;
    mapping(address => uint256) public purchaseTxs;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        uint256[] memory _maxSupply
    ) ERC1155(_uri) PaymentSplitter(_payees, _shares) {
        name_ = _name;
        symbol_ = _symbol;
        maxSupply = _maxSupply;
        _mint(0xDE21BEB973213F34fBCb3B132BbCc63DB7d04c68, COMMON, 50, "0x0");
        _mint(0xDE21BEB973213F34fBCb3B132BbCc63DB7d04c68, RARE, 5, "0x0");
    }

    /**
    * @notice edit mint windows
    *
    * @param _publicMintOpen the time public mint is open
    * @param _wlMintOpen the time whitelist mint is open
    */
    function editMintWindows(
        bool _publicMintOpen,
        bool _wlMintOpen
    ) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        wlMintOpen = _wlMintOpen;
    }

    /**
    * @notice edit mint settings
    *
    * @param _maxPerTx max nfts per transaction
    * @param _publicPrice the price of the public mint
    * @param _wlPrice per the price of the whitelist mint
    * @param _maxSupply maxSupply for every token
    */
    function editMintSettings(
        uint8 _maxPerTx,
        uint256 _publicPrice,
        uint256 _wlPrice,
        uint256[] memory _maxSupply
    ) external onlyOwner {
        maxPerTx = _maxPerTx;
        publicPrice = _publicPrice;
        wlPrice = _wlPrice;
        maxSupply = _maxSupply;
    }

    /**
    * @notice adds addresses into a whitelist
    *
    * @param addresses an array of addresses to add to whitelist
    */
    function setWhiteList(address[] calldata addresses ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whiteList[addresses[i]] = true;
        }
    }

    /**
     * @notice Generates a semi-random number from 0 - 3.
     *
     * @param _seed The seed number used to generate the semi-random result.
     * @param _length The largest number that the randomize can return.
     */
    function random(uint256 _seed, uint256 _length)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, _seed)
                )
            ) % _length;
    }

     /**
     * @notice get the ids avaliable for minting.
     */
    function getAvailableIds()
        internal
        view
        returns (uint256[] memory, uint256)
    {
        uint256[] memory availableIds = new uint256[](2);
        uint256 count = 0;

        for (uint256 i = 0; i < 2; i++) {
            if (totalSupply(i) + 1 <= maxSupply[i]) {
                availableIds[count] = i;
                count++;
            }
        }
        return (availableIds, count);
    }

    /**
     * @notice Mint NFTs during whitelist mint
     * @param _amt the number of nfts to mint.
     */
    function whitelistMint(uint256 _amt) public payable whenNotPaused {
        require(wlMintOpen, "Whitelist mint closed");
        require(msg.value >= wlPrice * _amt, "Not enough eth to mint");
        require(whiteList[msg.sender], "Not on the whitelist.");
        mint(_amt);
    }

    /**
     * @notice Mint NFTs during public mint 
     * @param _amt the number of nfts to mint.
     */
    function publicMint(uint256 _amt) public payable whenNotPaused {
        require(publicMintOpen, "Public mint closed");
        require(msg.value >= publicPrice * _amt, "Not enough eth to mint");
        mint(_amt);
    }

    /**
    * @notice global mint function used in early access and public sale
    *
    * @param amount the amount of tokens to mint
    */
    function mint(uint256 amount) private {
        require(amount > 0, "Need to request at least 1 NFT");
        require(purchaseTxs[msg.sender] + amount <= maxPerTx, "Wallet mint limit");
        
        for(uint256 i = 0; i < amount; i++){
            (uint256[] memory availableIds, uint256 count) = getAvailableIds();
            require(count > 0, "NO NFTS");
            uint256 num = random(totalCount, count);
            _mint(msg.sender, availableIds[num], 1, "");
            totalCount++;
        }

        purchaseTxs[msg.sender] += amount;
    }

    /**
    * @notice returns the metadata uri for a given id
    *
    * @param _id the NFT id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
    }
}