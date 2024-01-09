// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

import "./ERC721A.sol";
import "./console.sol";

interface IOldBaby {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BabyCoterie is ERC721A {
    
   
    mapping(address => bool) whitelistedAddresses;

    string public BABY_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN BABIES ARE ALL SOLD OUT
    string public LICENSE_TEXT = ""; // IT IS WHAT IT SAYS
    string public _baseTokenURI;
   
    uint256 public babyPrice = 20000000000000000; // 0.02 ETH
    uint256 public constant MAX_BABIES = 10000;
    //uint256 public oldSupply = 871; 
   

    bool public saleIsActive = false;
    bool public uriIsFrozen = false;
    bool public whitelistSaleIsActive = false;
    bool licenseLocked = false; // TEAM CAN'T EDIT THE LICENSE AFTER THIS GETS TRUE

    address public constant ADDRESS_DEV     = 0x7DF76FDEedE91d3cB80e4a86158dD9f6D206c98E;
    address public constant ADDRESS_HUSKY   = 0xCcB6D1e4ACec2373077Cb4A6151b1506F873a1a5;
    address public constant ADDRESS_ART     = 0xE1F04a8e7609482B0A96a4636bb2d0211e3A4fF9;
    address public ADDRESS_TEAM             = 0x2A393a7f50339bF11F42cE332f41148d467eA1Ad;
    address oldContract                     = 0x0d5b56Fdc49E853AD6865A1FBf248ABEFE9866dd;
    
    
    IOldBaby public oldContractInterface = IOldBaby(oldContract);

    event licenseisLocked(string _licenseText);

        
    constructor() ERC721A("Baby Coterie", "BABY", 20) { }
    
    function withdraw() public {
        uint balance = address(this).balance;
        uint dev_cut   = balance * 25/1000;
        uint husky_cut = balance * 75/1000;
        uint art_cut   = balance/10;

        payable(ADDRESS_DEV).transfer(dev_cut);
        payable(ADDRESS_HUSKY).transfer(husky_cut);
        payable(ADDRESS_ART).transfer(art_cut);
        payable(ADDRESS_TEAM).transfer(address(this).balance);
    }

     function claimFromOld(uint256[] calldata ids) external{
        
        uint256 numberOfTokens = 0;

        for(uint i = 0; i < ids.length; i++){
            
            address oldOwner = oldContractInterface.ownerOf(ids[i]);
            if(oldOwner == msg.sender){               
                numberOfTokens++;             
            }
        }

        numberOfTokens > 0 ? _safeMint(msg.sender, numberOfTokens) : revert("You don't own any of these babies");       

    }
    


    function setProvenanceHash(string memory provenanceHash) public {
        onlyOwner();
        BABY_PROVENANCE = provenanceHash;
    }

    function setBabyPrice(uint256 _babyPrice) public {
        onlyOwner();
        babyPrice = _babyPrice;
    }
   

    function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external  {
      onlyOwner();
      require(uriIsFrozen == false, "The BaseURI has been frozen and can not be changed.");
      _baseTokenURI = baseURI;
   }
    
    function freezeBaseURI() public {
        onlyOwner();
        require(uriIsFrozen == false, "The BaseURI has already been frozen.");
        uriIsFrozen = true;
    }

    function flipSaleState() public  {
        onlyOwner();
        saleIsActive = !saleIsActive;
    }

       
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    
    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "CHOOSE A BABY WITHIN RANGE");
        return LICENSE_TEXT;
    }
    
    // Locks the license to prevent further changes 
    function lockLicense() public {
        onlyOwner();
        licenseLocked =  true;
        emit licenseisLocked(LICENSE_TEXT);
    }
    
    // Change the license
    function changeLicense(string memory _license) public {
        onlyOwner();
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }
    

    function publicMintBaby(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint a Baby");
        
        uint256 totalSupply_ = this.totalSupply();
        console.log("totalSupply_", totalSupply_);
        
        require((totalSupply() + numberOfTokens) <= MAX_BABIES, "Purchase would exceed max supply of Babies");
        
            if (totalSupply_ > 600)
            {
                require(msg.value >= babyPrice * (numberOfTokens), "Ether value sent is not correct");
            } 

        _safeMint(msg.sender, numberOfTokens);
    }
    
    function ownerMintBaby(address _receiver, uint numberOfTokens) public  {
        onlyOwner();
        require(totalSupply() + (numberOfTokens) <= MAX_BABIES);
        _safeMint(_receiver, numberOfTokens);
    }

    function onlyOwner() internal view returns (bool) {
        return msg.sender == admin;
    }


}