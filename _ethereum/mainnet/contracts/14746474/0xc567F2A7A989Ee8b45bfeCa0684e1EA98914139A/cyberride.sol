// SPDX-License-Identifier: MIT

// File: contracts/CyberRide.sol


pragma solidity ^0.8.0;



//.------..------..------..------..------..------..------..------..------.
//|C.--. ||Y.--. ||B.--. ||E.--. ||R.--. ||R.--. ||I.--. ||D.--. ||E.--. |
//| :/\: || (\/) || :(): || (\/) || :(): || :(): || (\/) || :/\: || (\/) |
//| :\/: || :\/: || ()() || :\/: || ()() || ()() || :\/: || (__) || :\/: |
//| '--'C|| '--'Y|| '--'B|| '--'E|| '--'R|| '--'R|| '--'I|| '--'D|| '--'E|
//`------'`------'`------'`------'`------'`------'`------'`------'`------'
//dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
//dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
//dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
//dddddddddddddddddddddddddooooooddddddddddddddddddddddddddddddddddddddddddddddddd
//dddddddddddddddddddddoc:;,,'..'cdddddooodddddolododddddddddddddddddddddddddddddd
//dddddddddddddddoc;;;;,'.....   .;oddollooollcccllllooddddddddddddddddddddddddddd
//dddddddddddddo;'......'.....    ..;loooc::,,'',;:c::cloddddddddddddddddddddddddd
//ddddddddddddl;;cloddl,''''...     ..,::'........,;:;;;:coddddddddddddddddddddddd
//dddddddddddo;',''',lo:,,''''..     ..','..........'''',,;clddddddddddddddddddddd
//dddddddddddl,........,oxkl,''..    ....''''''............',,;coddddddddddddddddd
//dddddddddddo:........';;,,'''..    .........'''''.............,loddddddddddddddd
//ddddddddddddl,.......;lc,'.....     ............'''''..';;..  ..,ldddddddddddddd
//dddddddddddddl;,,,,;cdkOxc,.......     .............'..,cdxo,.   .cddddddddddddd
//ddddddddddddddoc:;,:coKNNO:'........      ..............',:xk:.   .ldddddddddddd
//dddddddddododdol:,....cxko,'...........   ................';xO:.  .;oddddddddddd
//ddddddddddddol:;;,,'.......................................'c0o.   ,oddddddddddd
//ddddddddddddoc:cclllc;'......................,;cc:;,'.......lOl.  .;oddddddddddd
//ddddddddddddc:;;;;:coo:,'......              .';:ccll;,''.'ckx,   'ldddddddddddd
//dddddddddddoc;;,,,,,:looo:,'...........       .....,clc:;,:lc'  .,lddddddddddddd
//dddddddddddoc;;,,,,,;cdxxo:,,,,,,'''''..............';:;'....  .cddddddddddddddd
//ddddddddddddl:;;;;,,,;lool:;,,,,,,,,,,,,,,,,''''''''',;:c::;'''';ldddddddddddddd
//ddddddddddddol:;;;;;;;clc:;;,,,,,,,,,,''',,,,,,''''',;:ccclol;,'';codddddddddddd
//dddddddddddddolc:::;;:looc;;;;,,,,,,;;,,''',,,,,,,,,,,,,,,;cdl;''';ldddddddddddd
//ddddddddddddddoollc:;:looc;;;;,,,,,;cc:,,'',,,,,,,,,,,,,,,,;loc,'',cdddddddddddd
//ddddddddddddddddoolc::ccc:;;;,,,;;:cllc;,,,,,,,,,,,,,,,,,,;;cdl,',,cdddddddddddd
//ddddddddddddddddddoolccc::;;;,;;cllcc:;;,,,,,,,,,,,,,,,;;;;:loc,,,;ldddddddddddd
//ddddddddddddddddddddoollcc::;;:clol:;;;;;;,;;;;;;;;;,,;;;:clol:,;:codddddddddddd
//ddddddddddddddddddddddooollcccloodoc:;;;;;;;;;;;;;;;;;;;:cclcc::cloddddddddddddd
//ddddddddddddddddddddddddooooooooddolcc:::;;;;;;;;;;;;;;;::cccllooodddddddddddddd
//dddddddddddddddddddddddddddddddddddollccc:::::::::::::::cclloooddddddddddddddddd
//ddddddddddddddddddddddddddddddddddddoollllcccccccccccccllooddddddddddddddddddddd
//dddddddddddddddddddddddddddddddddddddooolllllllllllllloooodddddddddddddddddddddd
//
// The CyberRide Gen-1: 
// 9,999 unique 3D voxel rides designed to be your first ride in the Metaverse.
// Each CyberRide Gen-1 NFT in your wallet will grant one free CyberRide on every future release. You will only have to pay the gas fee.
// Visit https://cyberride.io for details. 
//



import "ERC721A.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";

/**
 * @title CyberRide Gen-1 contract
 * @dev Extends ERC721A Non-Fungible Token Standard basic implementation
 */
contract CyberRide is ERC721A, Ownable, ReentrancyGuard{


    //provenance hash calculated before sale open to ensure fairness, see https://cyberride.io/provenance for more details
    string public cyberRideProvenance = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public publicSalePrice = 0.1 ether; //0.1 ETH

    uint256 public allowListPrice = 0.08 ether; //0.08 ETH

    uint public constant maxRidePurchase = 5; // 5 max ride per transaction during public sale

    uint256 public constant totalRides = 9999; // total 9,999 rides for the metaverse

    bool public saleIsActive = false;

    bool public isAllowListActive = false;

    string private _baseTokenURI;

    mapping(address => uint8) private _allowList;


    constructor() ERC721A("CyberRide Gen-1", "RIDE") {}

     //
     // Reserve rides for future development and collabs
     //
    function reserveRides(uint256 numberOfTokens) external onlyOwner {   
        require(totalSupply() + numberOfTokens <= totalRides, "Reserve amount would exceed max supply of CyberRide Gen-1");
    
         _safeMint(msg.sender,  numberOfTokens);
    }

    
  

    // @notice Set baseURI
    /// @param baseURI URI of the ipfs folder
    function setBaseURI(string memory baseURI) external onlyOwner {
            _baseTokenURI = baseURI;
    }

    /// @notice Get uri of tokens
    /// @return string Uri
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    //  Set CyberRide provenance
    function setProvenance(string  memory newProvenance) external onlyOwner {
        cyberRideProvenance = newProvenance;
    }

    //
    //  Set Public Sale State
    //
    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
    }

    //
    // Set if allow list is active  
    //
    function setIsAllowListActive(bool newState) external onlyOwner {
        isAllowListActive = newState;
    }


    // just in case if eth price goes crazy
    function setPublicSalePrice(uint256 newSalePrice) external onlyOwner {
        publicSalePrice = newSalePrice;
    }

    // just in case if eth price goes crazy
    function setAllowlistSalePrice(uint256 newSalePrice) external onlyOwner {
        allowListPrice = newSalePrice;
    }


    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 2;
        }
    }


    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    //
    // Mints CyberRide based on the number of tokens. This is allowlist only
    //
    function mintAllowList(uint8 numberOfTokens) external payable nonReentrant{
        uint256 supply = totalSupply();
        require(isAllowListActive, "Allowlist is not yet active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available allowlist quota to purchase");
        require(numberOfTokens > 0, "Can only mint a positive amount");
        require(supply + numberOfTokens <= totalRides, "Purchase would exceed max supply of CyberRide Gen-1");
        require(allowListPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Only real users minting are supported");
        
        _allowList[msg.sender] -= numberOfTokens;


        // set starting index block if it is the first mint
        if (startingIndexBlock==0 && supply==0) {
            startingIndexBlock = block.number;
        } 

        _safeMint(msg.sender, numberOfTokens);

        
    }


    //
    // Mints CyberRide based on the number of tokens, public sale only
    //
    function mintRide(uint numberOfTokens) external payable nonReentrant {
        require(saleIsActive, "Sale must be active to mint a CyberRide");
        require(numberOfTokens <= maxRidePurchase, "Can only mint 5 rides at a time");
        require(numberOfTokens > 0, "Can only mint a positive amount");
        require(totalSupply() + numberOfTokens <= totalRides, "Purchase would exceed max supply of CyberRide Gen-1");
        require(publicSalePrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Only real users minting are supported");

        _safeMint(msg.sender, numberOfTokens);
        
    }
    
    //
    // Set the starting index for the collection
    //
    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % totalRides;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number-startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % totalRides;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex+1;
        }
    }

    //
    // Set the starting index block for the collection, essentially unblocking
    // setting starting index
    //
    function emergencySetStartingIndexBlock() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }

    
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}