//SPDX-License-Identifier: MIT
/*
  QQQQQQQQQ     PPPPPPPPP         AA
 QQ       QQ    PP      PP       AAAA
QQ         QQ   PP       PP     AA  AA
QQ         QQ   PP       PP    AA    AA
QQ         QQ   PP      PP    AA      AA
QQ         QQ   PPPPPPPPP    AAAAAAAAAAAA
QQ      QQ QQ   PP           AA        AA
 QQ      QQQ    PP           AA        AA
  QQQQQQQQ QQ   PP           AA        AA

 ---- Quirky Plants Association 2021 ----
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title QuirkyPlantsAssociation contract
 */
contract QuirkyPlantsAssociation is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string public provenanceHash = "7774da9c874538d274fecf60aa0797b7b5da4b5744a721a6317d832c17946531";
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    string private baseURI;

    uint256 public maxSupply;

    uint256 public constant PLANT_PRICE = 50000000000000000; //0.05 ETH
    uint256 public constant NUM_MINTS_MAX = 10;

    bool public presaleActive = false;
    bool public saleActive = false;

    mapping(address => uint256) public presaleWhitelist;

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC721(name, symbol) {
        maxSupply = supply;
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setWhitelistEntries(address[] calldata presaleAddresses, uint256 amount) external onlyOwner {
        for (uint256 i; i < presaleAddresses.length; i++) {
            presaleWhitelist[presaleAddresses[i]] = amount;
        }
    }

    /**
     * Set provenance hash
     */
    function setProvenanceHash(string memory hash) public onlyOwner {
        provenanceHash = hash;
    }

    function mint(uint256 numMints) public payable {
        uint256 supply = totalSupply();
        require(saleActive || presaleActive, "Sale must be active to mint");
        require(numMints > 0 && numMints <= NUM_MINTS_MAX, "Invalid purchase amount");
        require(supply.add(numMints) <= maxSupply, "Purchase would exceed max supply");
        require(PLANT_PRICE.mul(numMints) == msg.value, "Ether value sent is not correct");

        // whitelist for pre-sale
        if (!saleActive) {
            uint256 numLeft = presaleWhitelist[msg.sender];
            require(numLeft > 0, "No pre-sale tokens available for this address");
            require(numLeft >= numMints, "Not enough pre-sale tokens left");
            presaleWhitelist[msg.sender] = numLeft - numMints;
        }

        for (uint256 i = 0; i < numMints; i++) {
            _safeMint(msg.sender, supply + i);
        }

        // set if not already set and this is the last saleable token
        if (startingIndexBlock == 0 && (totalSupply() == maxSupply)) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * Manually trigger setting of startingIndexBlock
     */
    function setStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index already set");
        require(startingIndexBlock == 0, "Starting index block already set");

        startingIndexBlock = block.number;
    }

    /**
     * Set the starting index.
     * See: https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % maxSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % maxSupply;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Reserve tokens
     */
    function reserveTokens(uint256 num) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply.add(num) <= maxSupply, "Cannot exceed max supply");
        uint256 i;
        for (i = 0; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
