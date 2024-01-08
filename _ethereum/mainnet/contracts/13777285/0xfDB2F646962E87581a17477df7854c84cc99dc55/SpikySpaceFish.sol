//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract SpikySpaceFish is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using SafeMath for uint256;

    /* Contract param */
    uint256 public MAX_TOKEN=10000; 
    uint256 public constant tokenPrice = 60000000000000000; //0.06 ETH on mint day
        
    /* Fairness param */
    string public PROVENANCE = "";//IPFS adress to provenance file
    uint256 public startingIndexBlock;//block number at the sold out time or after REVEAL_TIMESTAMP time
    uint256 public startingIndex;//derived from startingIndexBlock
    uint256 public REVEAL_TIMESTAMP;//it is the maximun time after presale before reveal 

    /* Presale and sale param */
    uint public constant maxTokenPurchase = 10;//Per request
    uint256 constant public maxTokenPurchasePresale = 3;//Per whitekist account

    bool public saleIsActive = false;//required to be true to mint (even in presale)
    bool public privateSaleIsActive = false;//required to be true to mint in presale and false otherwise

    struct Whitelist {
        address addr;
        uint hasMinted;//nb of minted token
    }
    mapping(address => Whitelist) public whitelist;
    address[] public whitelistAddr;

    constructor() public ERC721("SpikySpaceFish", "SSF") {
    }

     function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * Set some Tokens aside
     */
        struct ReserveList {
            address addr;
            uint nbOfToken;//nb of minted token
        } 
    
    /* to be called 5 times */
    function reserveToken() public onlyOwner {        
        uint supply = totalSupply()+1;
                uint i;
        uint j;
           
        ReserveList[] memory _acc = new ReserveList[](5);
        _acc[0].addr=msg.sender; _acc[0].nbOfToken=20;
        _acc[1].addr= address(0xa5cbD48F84BB626B32b49aC2c7479b88Cd871567);_acc[1].nbOfToken=5;
        _acc[2].addr= address(0xc06695Ce0AED905A3a3C24Ce99ab75C4bd8b7466);_acc[2].nbOfToken=5;
        _acc[3].addr= address(0xe72bf39949CD3D56031895c152B2168ca73b50e9);_acc[3].nbOfToken=5;
        _acc[4].addr= address(0x425f1E9bcCdC796f36190b5933d6319c78BA9f19);_acc[4].nbOfToken=5;

        
        for (j=0;j<_acc.length;j++){
            for (i = 0; i < _acc[j].nbOfToken; i++) {
                _safeMint(_acc[j].addr, supply);
                supply++;
            }
        }
    }

    /**
     * RevealTime set manually by the owner at he begining of the presale .
     * Ovverdies if the collection is sold out
     */
    function setRevealTimestamp(uint256 revealTimeStampInSec) public onlyOwner {
        REVEAL_TIMESTAMP = block.timestamp + revealTimeStampInSec;
    } 

    /*     
    * Set provenance. It is calculated and saved before the presale.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    /* 
    * To manage the reveal -The baseUri will be modified after
    * the startingIndex has been calculated.
    */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner returns (bool) {
        saleIsActive = !saleIsActive;
        return  saleIsActive;
    }

    /*
    * Pause presale if active, make active if paused - 
    * Presale for whitelisted only
    */
    function flipPrivateSaleState() public onlyOwner {
        privateSaleIsActive = !privateSaleIsActive;
    }




    /**
    * Mints token
    */
    function mintToken(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKEN, "Purchase would exceed max supply.");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
       if(privateSaleIsActive) {
            require(numberOfTokens <= maxTokenPurchasePresale, "Presale Purchase would not exeed maxTokenWhiteList at a time");
            require(isWhitelisted(msg.sender), "Is not whitelisted");
            require(whitelist[msg.sender].hasMinted.add(numberOfTokens) <= maxTokenPurchasePresale, "Above presale maxToken.");
            whitelist[msg.sender].hasMinted = whitelist[msg.sender].hasMinted.add(numberOfTokens);
        } else {
            require(numberOfTokens <= maxTokenPurchase, "Can only mint maxTokenPurchase tokens at a time");
        }
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply()+1;
            if (totalSupply() <= MAX_TOKEN) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_TOKEN || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    /**
     * Set the starting index once the startingBlox index is known
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_TOKEN;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_TOKEN;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

/******** WHITELIST */
    /**
    * @dev add an address to the whitelist
    * @param addr address
    */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        require(!isWhitelisted(addr), "Already whitelisted");
        whitelist[addr].addr = addr;
        whitelist[addr].hasMinted = 0;
        success = true;
        whitelistAddr.push(addr);
    }

    /*
    *   Add an array of adresses 
    */
    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
       
        for(uint i = 0; i < addrs.length; i++) {
            addAddressToWhitelist(addrs[i]);
        }
    }

    /*
    * Are you an happy Early Believer?
    */
    function isWhitelisted(address addr) public view returns (bool isWhiteListed) {
        return whitelist[addr].addr == addr;
    }

    /*
    * Returns the list of Whitelisted / Early Believers
    */
    function getWhiteListedAdrrs() view public returns(address[] memory ) {
        return whitelistAddr;
    }

    function getWhitelistedData(address _address) view public returns ( uint) {
        return ( whitelist[_address].hasMinted);
    }

    /*
    * Number of whitemisted / Early Believers
    */
    function countWhitelisted() view public returns (uint) {
        return whitelistAddr.length;
    }


/******** UTILS */

     /**
     * Get owner list order by token nb
     */
    function getOwners() public onlyOwner returns(address[] memory )  {        
        address[] memory _owners = new address[](totalSupply());
        uint i;
        for (i = 1; i <= totalSupply(); i++) {
            _owners[i-1]=ownerOf(i);
        }
        return _owners;
    }




}