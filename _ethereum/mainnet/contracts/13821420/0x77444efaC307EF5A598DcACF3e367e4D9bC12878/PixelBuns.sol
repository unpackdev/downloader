// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721EnumerableB.sol";
import "./Ownable.sol";
import "./Strings.sol";

//Join the RareBunniClub 5500k RareBunnies!
//FREE MINT PIXELBUNS born with $CARROTS

//Web rarebunniclub.com
//Twitter @rarebunniclub
//Linktree https://linktr.ee/RareBunniClub

interface IRBCUtility {    
    function burn(address _from, uint256 _amount) external;
}

contract PixelBuns is ERC721EnumerableB, Ownable {        
    using Strings for uint256;

    uint16 MAX_SUPPLY = 10000;
    
    uint256 nextPixelBun;
    uint256 public tokensBurnt;
    
    uint16 basePrice;
    uint16 superPrice;

    uint16 levelUpPrice;
    uint16 reRollPrice;
    uint16 reNamePrice;
    

    struct TokenData 
    {                          
        uint8 Trait_Shirt;
        uint8 Trait_Face;        
        uint8 Trait_Hat;        

        uint8 Level;                

        uint256 birthDay;                                      
    }

    struct NameData 
    {
        string Name;
        string Bio;  
    }

    struct pixelBunData
    {        
        uint8 faceTraits;
        uint8 hatTraits;
        uint8 shirtTraits;                                
    }

    mapping (uint256 => TokenData) public allTokenData;
    mapping (uint256 => NameData) public allNameData;

    mapping (uint256 => uint8) public activeRewards;
    mapping (uint256 => uint8) public passiveRewards;    

    pixelBunData public pixData;    

    bool usingMeta;        
    uint256 price;

    address UtilityAddress;
    string baseTokenURI;
    

    constructor(address _UtilityAddress, string memory _baseURI) ERC721B("PXLBUN", "PXLBUN") //init with Utility Contract address
    {        
        basePrice = 850;
        superPrice = 1199;

        levelUpPrice = 125;
        reRollPrice = 175;
        reNamePrice = 200;
        
        pixData = pixelBunData(44, 43, 54);
        
        UtilityAddress = _UtilityAddress;        
        baseTokenURI = _baseURI;
    }

    function levelUp(uint256 _tokenId, uint8 _levels) external {
        require(ownerOf(_tokenId) == msg.sender, "You Dont Own This Token");
        require(allTokenData[_tokenId].Level + _levels < 11, "Exceeding Max Level");
                     
        IRBCUtility(UtilityAddress).burn(msg.sender, _levels * levelUpPrice);

        allTokenData[_tokenId].Level += _levels;
    }

    function reRoll(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "You Dont Own This Token");

        pixelBunData memory pData = pixData;    
        TokenData storage currentToken = allTokenData[_tokenId];
        IRBCUtility(UtilityAddress).burn(msg.sender, reRollPrice);
        
        //Basic Randocalrisian
        uint256 rando = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId)));        
        currentToken.Trait_Shirt = uint8(rando % pData.shirtTraits);
        currentToken.Trait_Hat = uint8(rando % pData.hatTraits);
	    currentToken.Trait_Face = uint8(rando % pData.faceTraits);
    }

    function setNameAndBio(uint256 _tokenId, string calldata _name, string calldata _bio) external {        
        require(ownerOf(_tokenId) == msg.sender, "You Dont Own This Token");
        require(validateName(_name), "BAD NAME");
                  
        NameData storage currentToken = allNameData[_tokenId];

        IRBCUtility(UtilityAddress).burn(msg.sender, reNamePrice);

        currentToken.Name = _name;
        currentToken.Bio = _bio;        
    }

    //Credit to the Kongz
    function validateName(string memory str) private pure returns (bool) {
		bytes memory b = bytes(str);
		if(b.length < 1) return false;
		if(b.length > 25) return false; // Cannot be longer than 25 characters
		if(b[0] == 0x20) return false; // Leading space
		if (b[b.length - 1] == 0x20) return false; // Trailing space

		bytes1 lastChar = b[0];

		for(uint i; i<b.length; i++){
			bytes1 char = b[i];

			if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

			if(
				!(char >= 0x30 && char <= 0x39) && //9-0
				!(char >= 0x41 && char <= 0x5A) && //A-Z
				!(char >= 0x61 && char <= 0x7A) && //a-z
				!(char == 0x20) //space
			)
				return false;

			lastChar = char;
		}

		return true;
	}

    function doMint(address _to, uint256 _amount, bool _superMint) private {       	
        uint256 current = nextPixelBun;        
        
        require( current + _amount <= MAX_SUPPLY, "SORRY MAX MINTED" );

        for(uint256 i; i < _amount; i++)
        {
            pixelBunData memory pData = pixData;
            uint256 currentMint = current + i;            

            _safeMint( _to, currentMint);

            //Basic Randocalrisian
            uint256 rando = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, currentMint)));
            
            TokenData memory newToken;

            newToken.Trait_Shirt = uint8(rando % pData.shirtTraits);
			newToken.Trait_Hat = uint8(rando % pData.hatTraits);        
            newToken.Trait_Face = uint8(rando % pData.faceTraits);			

            if (_superMint)
            {
                newToken.Level = 10 - uint8(rando % 5);                    
            }
            else
            {
                newToken.Level = 1 + uint8(rando % 4);                    
            }
            
            newToken.birthDay = block.timestamp;

            allTokenData[currentMint] = newToken;
        }             

        nextPixelBun += _amount; 
    }

    function mint(uint256 _amount) external {
        require( _amount <= 10, "CANNOT MINT MORE THAN 10 AT ONCE" );
        //Burn will fail transaction if not enough Carrots
        IRBCUtility(UtilityAddress).burn(msg.sender, _amount * basePrice);
		
        doMint(msg.sender, _amount, false);
	}

    function superMint(uint256 _amount) external {  
        require( _amount <= 10, "CANNOT MINT MORE THAN 10 AT ONCE" );      
        //Burn will fail transaction if not enough Carrots
        IRBCUtility(UtilityAddress).burn(msg.sender, _amount * superPrice); //Super Price
        			
        doMint(msg.sender, _amount, true);
	}
	
    function paidMint(uint256 _amount) external payable { 
        require(price > 10, "Paid Mints Not Available");
        require( _amount <= 10, "CANNOT MINT MORE THAN 10 AT ONCE" );

        require(msg.value == price * _amount, "Wrong amount of ETH sent");		
        doMint(msg.sender, _amount, false);
	}
////////APPROVED OR OWNER
    function burn(uint256 _tokenId) external
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        tokensBurnt++;

        delete allTokenData[_tokenId];
        delete allNameData[_tokenId];

        _burn(_tokenId);
    }    

////////ONLY OWNER BELOW SOZ
        
    function setUtilityAddress(address _UtilityAddress) external onlyOwner {
		UtilityAddress = _UtilityAddress;
	}	

    function setTraitCounts(uint8 _shirt, uint8 _hat, uint8 _face) external onlyOwner {
		pixData.shirtTraits = _shirt;
        pixData.hatTraits = _hat;
        pixData.faceTraits = _face;
	} 
    
    // Free Bunnies!
    function giveAway(address _to, uint256 _amount, bool _superMint) external onlyOwner() {               
        doMint(_to, _amount, _superMint);
    }

    // Set new baseURI
    function setBaseURI(string memory _baseURIVar, bool _usingMeta) external onlyOwner {
        baseTokenURI = _baseURIVar;
        usingMeta = _usingMeta;
    }
    
    function updatePrices(uint16 _base, uint16 _super, uint16 _levelUp, uint16 _reRoll, uint16 _rename) external onlyOwner {        
        basePrice = _base;
        superPrice = _super;

        levelUpPrice = _levelUp;
        reRollPrice = _reRoll;
        reNamePrice = _rename;
    }

    function updatePaid(uint256 _price) external onlyOwner {        
        price = _price;
    }

    function withDraw() public payable onlyOwner {    
        uint256 balance = address(this).balance;    
        payable(msg.sender).transfer(balance);
    }

    //For Naughties
    function deleteNameAndBio(uint256 _tokenId) external onlyOwner {        
        delete allNameData[_tokenId];
    }

    function setActiveRewards(uint256[] memory _level, uint8[] memory _amount) external onlyOwner {
        uint256 length = _level.length;
        for(uint256 i; i < length; i++)
        {
            activeRewards[_level[i]] = _amount[i];
        }
        delete length;
    }  

    function setPassiveRewards(uint256[] memory _level, uint8[] memory _amount) external onlyOwner {
        uint256 length = _level.length;
        for(uint256 i; i < length; i++)
        {
            passiveRewards[_level[i]] = _amount[i];
        }
        delete length;
    }    

/////////////////VIEWING

    function getBonus(uint256 _tokenId) external view returns (uint16 _bonus)
    {
        return activeRewards[allTokenData[_tokenId].Level];
    }

    function getPassiveBonus(uint256 _tokenId) external view returns (uint16 _bonus)
    {
        return passiveRewards[allTokenData[_tokenId].Level];
    }

    function getTokenData(uint256 _tokenId) external view returns (TokenData memory _tokenData)
    {
        return allTokenData[_tokenId];
    }

    function getNameData(uint256 _tokenId) external view returns (NameData memory _nameData)
    {
        return allNameData[_tokenId];
    }

    function getTokenLevel(uint256 _tokenId) external view returns (uint16 _level)
    {
        return allTokenData[_tokenId].Level;
    }

    function tokensOfOwner(address addr) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }        

    function getAPIMetaData(uint256 _tokenId) internal view returns (string memory) {            
        return string(abi.encodePacked(
        '&Level=', uint256(allTokenData[_tokenId].Level).toString(),
        '&Shirt=', uint256(allTokenData[_tokenId].Trait_Shirt).toString(),
        '&Face=', uint256(allTokenData[_tokenId].Trait_Face).toString(),        
        '&Hat=', uint256(allTokenData[_tokenId].Trait_Hat).toString()        
        ));
    }

    function getTokenMeta(uint256 _tokenId) internal view returns (string memory) {            
        return string(abi.encodePacked( 'T', _tokenId.toString(),               
        '_L', uint256(allTokenData[_tokenId].Level).toString(),
        '_S', uint256(allTokenData[_tokenId].Trait_Shirt).toString(),
        '_F', uint256(allTokenData[_tokenId].Trait_Face).toString(),
        '_H', uint256(allTokenData[_tokenId].Trait_Hat).toString()
        ));
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {    
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (usingMeta)
        {
            return string(abi.encodePacked(baseTokenURI, getTokenMeta(_tokenId), '.meta'));
        }
                
        return string(abi.encodePacked(baseTokenURI, 
            '?Token=', _tokenId.toString(),
            '&Name=', allNameData[_tokenId].Name,
            '&Bio=', allNameData[_tokenId].Bio,
            getAPIMetaData(_tokenId)
            ));
    }    

}
