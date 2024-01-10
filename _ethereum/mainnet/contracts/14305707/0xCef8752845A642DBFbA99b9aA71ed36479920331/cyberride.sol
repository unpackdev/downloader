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


import "ERC721.sol";
import "Ownable.sol";
import "ERC721Enumerable.sol";


/**
 * @title CyberRide contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract CyberRide is ERC721, ERC721Enumerable, Ownable {


    //provenance hash calculated before deploying smart contract to ensure fairness, see https://cyberride.io/provenance for more details
    string public PROVENANCE = "ad07f9786888624602395a5d85c8b018206d19e179eb9681fdcc083cd3e5ce2b";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public publicSalePrice = 0.1 ether; //0.1 ETH

    uint256 public allowListPrice = 0.08 ether; //0.08 ETH

    uint public constant maxRidePurchase = 5;

    uint256 public constant MAX_RIDES = 9999;

    bool public saleIsActive = false;

    bool public isAllowListActive = false;

    string public _baseTokenURI;

    mapping(address => uint8) private _allowList;

    constructor() ERC721('CyberRide Gen-1', 'RIDE') {

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

     //
     // Reserve rides for future development and collabs
     //
    function reserveRides(uint256 numberOfTokens) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + numberOfTokens <= MAX_RIDES, "Reserve amount would exceed max rides");
        uint256 i;
        for (i = 0; i <numberOfTokens; i++) {
            _mint(msg.sender, supply + i);
        }
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

    //
    //  Set Public Sale State
    //
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    //
    // Set if allow list is active  
    //
    function setIsAllowListActive(bool newState) external onlyOwner {
        isAllowListActive = newState;
    }


    // just in case if Eth price goes crazy
    function setPublicSalePrice(uint256 newSalePrice) public onlyOwner {
        publicSalePrice = newSalePrice;
    }

    // just in case if Eth price goes crazy
    function setAllowlistSalePrice(uint256 newSalePrice) public onlyOwner {
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
    // Mints CyberRide based on the number of tokens
    //
    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 supply = totalSupply();
        require(isAllowListActive, "Allowlist is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(supply + numberOfTokens <= MAX_RIDES, "Purchase would exceed max tokens");
        require(allowListPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Only real users minting are supported");
        
        _allowList[msg.sender] -= numberOfTokens;


        // set starting index block if it is the first mint
        if (startingIndexBlock==0 && supply==0) {
            startingIndexBlock = block.number;
        } 

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }


    //
    // Mints CyberRide based on the number of tokens
    //
    function mintRide(uint numberOfTokens) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale must be active to mint a CyberRide");
        require(numberOfTokens <= maxRidePurchase, "Can only mint 10 rides at a time");
        require(supply + numberOfTokens <= MAX_RIDES, "Purchase would exceed max supply of CyberRide Gen-1");
        require(publicSalePrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Only real users minting are supported");
     

        for(uint i = 0; i < numberOfTokens; i++) {
             _safeMint(msg.sender, supply + i);
        }
        
    }

    //
    // Set the starting index for the collection
    //
    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_RIDES;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number-startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_RIDES;
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
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}