// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./MerkleProof.sol";

/**
 *  - a contract for my non-fungible creatures.
 */
contract ChipFactory is ERC721Tradable, MerkleProof{
  using SafeMath for uint256;
  
  constructor(address _proxyRegistryAddress) ERC721Tradable("CNK World", "CHIPS", _proxyRegistryAddress) public {  
  }

    uint MINTMAX = 5000; 
    uint CUSTOMMINTMAX = 50; 
    uint256 DISCOUNT_FEE = 0.06 ether; 
    uint256 MINT_FEE =  0.08 ether; 
    string BASEURI = ""; 
    
    mapping(address => uint8) public hasMinted; 
    mapping(uint => bool) public isntMergable; 

    bytes32 whitelistRoot; 
    bytes32 discountRoot; 

    bool whitelistRequired = true; 
    bool mergingAllowed = false; 

    event chipsMerged(uint _tokenID1, uint _tokenID2, address _owner);

    //Function modifier so that only the owner of a certain token can call the function. 
    modifier onlyOwnerOf(uint _tokenID) {
        require(msg.sender == ownerOf(_tokenID)); 
         _;
    }

    //Checks the merging is currently allowed. 
    modifier mergingIsAllowed() {
        require(mergingAllowed); 
        _; 
    }


    //Checks that both tokens are mergable; 
    modifier areMergable(uint _tokenID1, uint _tokenID2) {
        require(!isntMergable[_tokenID1]); 
        require(!isntMergable[_tokenID2]); 
        _;
    }

    //Checks that both tokens are unique. 
    modifier areUnique(uint _tokenID1, uint _tokenID2) {
         require(_tokenID1 != _tokenID2); 
        _;
    }


    //same thing as onlyOwnerOf but with two tokens. 
    modifier onlyOwnerOfBoth(uint _tokenID1, uint _tokenID2) {
        require(msg.sender == ownerOf(_tokenID1)); 
        require(msg.sender == ownerOf(_tokenID2));
        _;
    }
    
    function baseTokenURI() public view override (ERC721Tradable) returns (string memory) {
        return BASEURI;
    }

    // Creates a randomly generated chip for people who are included in on the whitelist. 
    function createChipFromWhitelist(uint8 numToMint, bytes32[] memory whitelistProof, bytes32[] memory discountProof) public payable {

        require(verifyProof(getWhitelistRoot(), msg.sender, whitelistProof)); 
        require(totalSupply() + numToMint <= MINTMAX); 
        require(numToMint == 1 || numToMint == 2); 
        require(hasMinted[msg.sender] + numToMint <= 2); 

        if (verifyProof(getDiscountRoot(), msg.sender, discountProof)) {
            require(msg.value == DISCOUNT_FEE * numToMint); 
        } else {
            require(msg.value == MINT_FEE * numToMint);
        }
        
        hasMinted[msg.sender] += numToMint; 

        for (uint i = 0; i < numToMint; i++) {
            if (1 == (_generateRandomRarity() % 255)) {
                isntMergable[_getNextTokenId()] = true; 
            } 
            _mint(msg.sender, _getNextTokenId()); 
            _incrementTokenId();
        }
    }

    // Creates a chip can only be called once the whitelist has been disabled. 
    function createChip(uint8 numToMint) external payable {

        require(totalSupply() + numToMint <= MINTMAX); 
        require(!whitelistRequired);
        require(numToMint == 1 || numToMint == 2); 
        require(msg.value == MINT_FEE * numToMint); 

        for (uint i = 0; i < numToMint; i++ ) {
            if (1 == (_generateRandomRarity() % 255)) {
                isntMergable[_getNextTokenId()] = true; 
            } 
            _mint(msg.sender, _getNextTokenId()); 
            _incrementTokenId();
        }  

    }

    // Generates a rarity hash based on the last blocknumber. Returns the rarity hash modulo rarityModulo.
    function _generateRandomRarity() private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked((blockhash(block.number - 1)), abi.encodePacked(totalSupply()))));
        return rand;
    }
    
    //creates a customChip and sends to the specified recipient. 
    function createCustomChip(uint numToMint, address _recipient, bool _mergable) onlyOwner public {
        
        //NO more custom chips after the inital 50. 
        require(totalSupply() + numToMint <= CUSTOMMINTMAX, "CUSTOMMINTMAX Reached");
    
        for (uint i = 0; i < numToMint; i++ ) {
            isntMergable[ _getNextTokenId()] = _mergable; 
            _mint(_recipient, _getNextTokenId()); 
            _incrementTokenId();
        }
    }

    //This takes two chips. Merges their characteristics. Creates a new chip based on that merge. 
    //Burns their previous chip. 
    function mergeChips(uint _tokenID1, uint _tokenID2) 
        public onlyOwnerOfBoth(_tokenID1, _tokenID2) 
                areMergable(_tokenID1, _tokenID2)
                areUnique(_tokenID1, _tokenID2)
                mergingIsAllowed {
            
        require(balanceOf(msg.sender) >= 2); 

        _burn(_tokenID1);
        _burn(_tokenID2);  

        _mint(msg.sender, _getNextTokenId()); 
        _incrementTokenId();

        emit chipsMerged(_tokenID1, _tokenID2, msg.sender);
    }

    //Transfer the ETH from bought Chips to owner of contract. 
    function transferBalanceToOwner() onlyOwner public {
        address payable wallet =  payable(owner()); 
        wallet.transfer(address(this).balance); 
    }

    // this will set the base URI for the chip once all the chips have been created and uploaded. 
    function setBaseURI(string memory uri) onlyOwner public {
        BASEURI = uri; 
    }

    //Turn off need for a mint pass. 
    function whitelistNoLongerRequired() onlyOwner public {
        whitelistRequired = false; 
    }

    //gets the whitelistRoot for the whitelist function. 
    function getWhitelistRoot() view public returns (bytes32) {
        return whitelistRoot;
    }
       
    //gets the whitelistRoot for the whitelist function. 
    function getDiscountRoot() view public returns (bytes32) {
        return discountRoot;
    }

    //Sets the whitelistRoot for the whitelist of the function. 
    function setWhitelistRoot(bytes32 _whitelistRoot) onlyOwner public {
        whitelistRoot = _whitelistRoot; 
    }

    //Sets the discountRoot for the whitelist of the function. 
    function setDiscountRoot(bytes32 _discountRoot) onlyOwner public {
        discountRoot = _discountRoot; 
    }

    //Set merges allowed. 
    function allowMerging() onlyOwner public {
        mergingAllowed = true; 
    }

    //Chips owned by _chipOwner.
    function viewChipsOwnedBy(address _chipOwner) view public returns (uint[] memory) {
        uint[] memory chipsOwned = new uint[](balanceOf(_chipOwner));
        for (uint i = 0; i < balanceOf(_chipOwner); i++) {
            chipsOwned[i] = tokenOfOwnerByIndex(_chipOwner, i);  
        }
        return chipsOwned; 
    }
    
    //Check that a given Token is a mergable token.  
    function viewTokenIsntMergable(uint256 tokenID) view public returns (bool) {
        require(_exists(tokenID), "token doesn't exist"); 
        return (isntMergable[tokenID]); 
    }
}

