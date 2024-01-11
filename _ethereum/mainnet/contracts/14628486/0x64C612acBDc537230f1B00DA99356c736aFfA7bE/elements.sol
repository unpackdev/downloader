// SPDX-License-Identifier: GPL-3.0


//  ███████╗██╗     ███████╗███╗   ███╗███████╗███╗   ██╗████████╗███████╗
//  ██╔════╝██║     ██╔════╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
//  █████╗  ██║     █████╗  ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   ███████╗
//  ██╔══╝  ██║     ██╔══╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║
//  ███████╗███████╗███████╗██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   ███████║
//  ╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝

// Created By: https://elements.blue

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";



import "./meta.sol";


contract Elements is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event Mint(address indexed owner, uint256 indexed tokenId);

    receive() external payable {}

    mapping(bytes1 => Element) public elements;
    bytes1[] elementIds=[bytes1('1'),bytes1('2'),bytes1('3'),bytes1('4') ];

    uint randNonce = 1;
    uint32[] raritykeys=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,4,4,5];
    uint32 basicElementSupplyCap = 37500;
    uint32 basicElementPreMintCap = 24;
    uint32 artLevelWeight = 4;
    uint32 maxLevelWeight = 20;
    mapping(bytes1 => uint32) public basicElementMintedCount;

    // ----- Minting -----
    uint256 public mintPrice = 0.003 ether;
    uint256 private lastTokenId=1000;
    // Minting Stage:
    // 0 - Not open
    // 1 - freeMint
    // 2 - preMint
    // 3 - publicMint
    uint8 public mintingStage=0; 
    mapping(address => uint256) public preMintAddresses;


    mapping(uint256 => NFTDetails) public tokenInfo;
    string public baseURI = "";
    string public externalURI = "https://elements.blue";

    constructor() ERC721("Elements", "Elements") {
         // Adding basic Elements
         bytes1[] memory _parents;
         elements["1"] = Element({name: "Fire", parents:  _parents,supply: 0,supplyMass:0, tier:0 });
         elements["2"] = Element({name: "Water", parents:  _parents,supply: 0, supplyMass:0, tier:0 });
         elements["3"] = Element({name: "Air", parents:  _parents,supply: 0,supplyMass:0, tier:0 });
         elements["4"] = Element({name: "Earth", parents:  _parents,supply: 0,supplyMass:0, tier:0 });
          
 
        // Initial Creatures before mint
        bytes1[] memory _parents2=new bytes1[](2);
        _parents2[0]=bytes1('1');
        _parents2[1]=bytes1('4');
        elements["M"] = Element({name: "Roc", parents: _parents2,supply: 0,supplyMass:0, tier:1});
        elementIds.push(bytes1('M'));

        bytes1[] memory _parents3=new bytes1[](2);
        _parents3[0]=bytes1('2');
        _parents3[1]=bytes1('3');
        elements["L"] = Element({name: "Erawan", parents: _parents3,supply: 0,supplyMass:0, tier:1});
        elementIds.push(bytes1('l'));

        bytes1[] memory _parents4=new bytes1[](2);
        _parents4[0]=bytes1('2');
        _parents4[1]=bytes1('4');
        elements["E"] = Element({name: "Mandrake", parents: _parents4,supply: 0,supplyMass:0, tier:1});
        elementIds.push(bytes1('E'));


        bytes1[] memory _parents5=new bytes1[](2);
        _parents5[0]=bytes1('1');
        _parents5[1]=bytes1('3');
        elements["D"] = Element({name: "Vethal", parents: _parents5,supply: 0,supplyMass:0, tier:1});
        elementIds.push(bytes1('D'));


        bytes1[] memory _parents7=new bytes1[](2);
        _parents7[0]=bytes1('M');
        _parents7[1]=bytes1('3');
        elements["F"] = Element({name: "Anga", parents: _parents7,supply: 0,supplyMass:0, tier:2});
        elementIds.push(bytes1('F'));


        bytes1[] memory _parents8=new bytes1[](2);
        _parents8[0]=bytes1('L');
        _parents8[1]=bytes1('4');
        elements["O"] = Element({name: "Titan", parents: _parents8,supply: 0,supplyMass:0, tier:2});
        elementIds.push(bytes1('O'));

        bytes1[] memory _parents9=new bytes1[](2);
        _parents9[0]=bytes1('D');
        _parents9[1]=bytes1('2');
        elements["J"] = Element({name: "Wukong", parents: _parents9,supply: 0,supplyMass:0, tier:2});
        elementIds.push(bytes1('J'));

        bytes1[] memory _parents10=new bytes1[](2);
        _parents10[0]=bytes1('E');
        _parents10[1]=bytes1('1');
        elements["H"] = Element({name: "Herbant", parents: _parents10,supply: 0,supplyMass:0, tier:2});
        elementIds.push(bytes1('H'));

        bytes1[] memory _parents11=new bytes1[](2);
        _parents11[0]=bytes1('E');
        _parents11[1]=bytes1('D');
        elements["C"] = Element({name: "Flus", parents: _parents11,supply: 0,supplyMass:0, tier:2});
        elementIds.push(bytes1('C'));

        bytes1[] memory _parents12=new bytes1[](2);
        _parents12[0]=bytes1('M');
        _parents12[1]=bytes1('L');
        elements["G"] = Element({name: "Lado", parents: _parents12,supply: 0,supplyMass:0, tier:2});
        elementIds.push(bytes1('G'));

        bytes1[] memory _parents13=new bytes1[](2);
        _parents13[0]=bytes1('C');
        _parents13[1]=bytes1('G');
        elements["N"] = Element({name: "Demon", parents: _parents13,supply: 0,supplyMass:0, tier:3});
        elementIds.push(bytes1('N'));

        bytes1[] memory _parents14=new bytes1[](2);
        _parents14[0]=bytes1('O');
        _parents14[1]=bytes1('H');
        elements["K"] = Element({name: "Deacon", parents: _parents14,supply: 0,supplyMass:0, tier:1});
        elementIds.push(bytes1('K'));

        bytes1[] memory _parents15=new bytes1[](2);
        _parents15[0]=bytes1('F');
        _parents15[1]=bytes1('J');
        elements["I"] = Element({name: "Makara", parents: _parents15,supply: 0,supplyMass:0, tier:1});
        elementIds.push(bytes1('I'));

        bytes1[] memory _parents16=new bytes1[](2);
        _parents16[0]=bytes1('N');
        _parents16[1]=bytes1('K');
        elements["A"] = Element({name: "Vamp", parents: _parents16,supply: 0,supplyMass:0, tier:1});
        elementIds.push(bytes1('A'));

        bytes1[] memory _parents17=new bytes1[](2);
        _parents17[0]=bytes1('N');
        _parents17[1]=bytes1('I');
        elements["B"] = Element({name: "Dragon", parents: _parents17,supply: 0,supplyMass:0, tier:1});
        elementIds.push(bytes1('B')); 
    }

    function addToWhitelist(address[] memory toAdd) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            preMintAddresses[toAdd[i]] = basicElementPreMintCap;
            
        }
    }
   
    
    // Spit higher mass to one mass
    function split (uint256    _tokenId) external payable {
        require( _exists(_tokenId), "nonexistent token" );
        require(ownerOf(_tokenId)==msg.sender,"  token not owned");
        NFTDetails memory tokenDetails= tokenInfo[_tokenId];
        require(  tokenDetails.mass>= 2 , "low mass" );
        uint32 newImmunity=tokenDetails.immunity+1;  
        tokenInfo[_tokenId]=NFTDetails({elementId:tokenDetails.elementId, mass: 1, power:tokenDetails.power, immunity:newImmunity, experience:tokenDetails.experience});
        for (uint256 i = 1; i < tokenDetails.mass; i++) {
            _mintWithoutValidation(msg.sender, tokenDetails.elementId, 1,tokenDetails.power,newImmunity,tokenDetails.experience);
        }  
        addElementSupply(tokenDetails.elementId,(tokenDetails.mass-1),0,false,false);
        // No Change in Supply Mass
    }
    // Split NFT into parent NFTs
    function fision (uint256 _tokenId ) external payable {
        require( _exists(_tokenId), "nonexistent token" );
        require(ownerOf(_tokenId)==msg.sender,"  token not owned");
        NFTDetails memory tokenDetails= tokenInfo[_tokenId];
        require( elements[tokenDetails.elementId].parents.length>0, "should not be a base element" );
        //Adjust Mass
        addElementSupply(tokenDetails.elementId,1, tokenDetails.mass,true,true );
        addElementSupply(elements[tokenDetails.elementId].parents[0],1, tokenDetails.mass,false,false);
        tokenInfo[_tokenId]=NFTDetails({elementId:elements[tokenDetails.elementId].parents[0], mass: tokenDetails.mass, power:tokenDetails.power, immunity:tokenDetails.immunity+1, experience:tokenDetails.experience});
        for (uint256 i = 1; i < elements[tokenDetails.elementId].parents.length; i++) {
            addElementSupply(elements[tokenDetails.elementId].parents[i],1, tokenDetails.mass,false,false);
            _mintWithoutValidation(msg.sender, elements[tokenDetails.elementId].parents[i] , tokenDetails.mass,tokenDetails.power, tokenDetails.immunity+1, tokenDetails.experience);
        }
    }
    // Adjust Supply on every action
    function addElementSupply(bytes1 elementId, uint32 supply, uint32 supplyMass ,bool subSupply, bool subMass ) private {
        if(supply!=0){
            if(subSupply){
                require(elements[elementId].supply>=supply,"wrong supply");
                elements[elementId].supply-=supply;
            }else{
                elements[elementId].supply+=supply;
            }
        }
         if(supplyMass!=0){
            if(subMass){
                require(elements[elementId].supplyMass>=supplyMass,"wrong supplyMass");
                elements[elementId].supplyMass-=supplyMass;
            }else{
                elements[elementId].supplyMass+=supplyMass;
            } 
        }
    }
    // Combine Same Elements to increase mass
    function combine (uint256[]  memory  _tokenIds, uint256    _burnTokenId) external payable {
        require(_tokenIds.length>1,"atleast 2 elements required");
        require(_tokenIds.length<=10,"can't combine more than 10 elements");
        require(!hasDuplicates(_tokenIds,_burnTokenId),"duplicates tokens");
        if(_burnTokenId>0){
            require(_exists(_burnTokenId),"burn token not exist");
            require(ownerOf(_burnTokenId)==msg.sender,"burn token not owned");
        }
        bytes1 _resultElementId=tokenInfo[_tokenIds[0]].elementId;
        uint32 newMass=0;
        uint32 newPower=0;  
        uint32 newImmunity=0;  
        uint32 newExperience=0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]),"token not exist");
            require(ownerOf(_tokenIds[i])==msg.sender,"token not owned");
            NFTDetails memory tokenDetails= tokenInfo[_tokenIds[i]];
            require(tokenDetails.elementId==_resultElementId,"all should be same element"); 
            newMass+=tokenDetails.mass;
            newPower+=(tokenDetails.power*tokenDetails.mass);
            newImmunity+=(tokenDetails.immunity*tokenDetails.mass);
            newExperience+=(tokenDetails.experience*tokenDetails.mass);
        }
        newPower=(newPower/newMass)+1;  
        newImmunity=newImmunity/newMass;  
        newExperience=newExperience/newMass;
        // Burn all tokens
        if(_burnTokenId>0){
            //mass of burn id is greater than one
            if(tokenInfo[_burnTokenId].mass>1){
                tokenInfo[_burnTokenId].mass-=1;
                addElementSupply(tokenInfo[_burnTokenId].elementId,0,1,false,true);
            }else{ // burn token id mass is one
                addElementSupply(tokenInfo[_burnTokenId].elementId,1,1, true, true);
                _burnToken(_burnTokenId);
            }
            addElementSupply(_resultElementId,uint32(_tokenIds.length-1),0, true, false);
        }else{
            newMass-=1;
            require(newMass<=1,"add more elements to combine");
            addElementSupply(_resultElementId,uint32(_tokenIds.length-1),1, true, true);
        }
        for (uint256 i = 1; i < _tokenIds.length; i++) {
             _burnToken(_tokenIds[i]);
        }
        tokenInfo[_tokenIds[0]]=NFTDetails({elementId:_resultElementId, mass: newMass, power:newPower, immunity:newImmunity, experience:newExperience});
    }

 
    // Check duplicates
     function hasDuplicates(uint256[] memory _tokenIds,uint256 _burnTokenId) internal pure returns (bool) {
          for (uint256 i = 0; i < _tokenIds.length; i++) {
              for (uint256 j = i+1; j < _tokenIds.length; j++) {
                  if(_tokenIds[i]==_tokenIds[j]){
                      return true;
                  }
              }
              if(_burnTokenId>0 && _tokenIds[i]==_burnTokenId){
                      return true;
              }
          }
          return false;
     }
    
    
    // Combine nfts to create higher tier NFts
    function fusion (uint256[] memory _tokenIds, string memory __resultId, uint32 _resultMass, uint256 _burnTokenId) external payable {
        require(_tokenIds.length>1 
                && bytes(__resultId).length==1
                && _resultMass>0
                && _burnTokenId>0 , "tokens requiremnt not met" );
        bytes1 _resultId= bytes1( bytes(__resultId) );
        require(elements[_resultId].parents.length>1,"result token should not be a base element");
        require(ownerOf(_burnTokenId)==msg.sender,"burn token not owned");
        require(!hasDuplicates(_tokenIds,_burnTokenId),"duplicate tokens");
        uint32[] memory massToBurn  =new uint32[](_tokenIds.length) ; // Mass to burn for each token
        uint32[] memory massRequired =new uint32[](elements[_resultId].parents.length) ; // To Check enough elements added
        
        for (uint256 i = 0; i < _tokenIds.length; i++) {
             require(_exists(_tokenIds[i]),"token not exist");
             require(ownerOf(_tokenIds[i])==msg.sender,"token not owned");
             NFTDetails memory tokenDetails= tokenInfo[_tokenIds[i]];
            for (uint256 j = 0; j < elements[_resultId].parents.length; j++) {
                 
                if(elements[_resultId].parents[j]==tokenDetails.elementId  // incoming token contains required element 
                    && massRequired[j]<_resultMass){ // required mass not meet
                       
                        uint32 newMassRequirement=_resultMass-massRequired[j];
                        
                        if(tokenDetails.mass<=newMassRequirement){ // dont have enough mass or equal
                            massRequired[j]+=tokenDetails.mass;
                            massToBurn[i]+=tokenDetails.mass;
                        }else{
                            massRequired[j]+=newMassRequirement;
                            massToBurn[i]+=newMassRequirement;
                        }
                    }
             }
        }
         
        //Check input tokens have enough mass
        for (uint256 j = 0; j < elements[_resultId].parents.length; j++) {
             require(massRequired[j]==_resultMass, "mass requirement not met"); 
        }
        
        uint32 massBurned=0; 
        uint32 powerBurned=0;  
        uint32 immunityBurned=0;  
        uint32 experienceBurned=0;
        // Burn Parents and Mint if there is additional mass
         for (uint256 i = 0; i < _tokenIds.length; i++) {
             NFTDetails memory tokenDetails= tokenInfo[_tokenIds[i]];
             if(massToBurn[i]>0 ){
                 if(tokenDetails.mass>massToBurn[i]){
                     
                     tokenInfo[_tokenIds[i]].mass=tokenDetails.mass-massToBurn[i];
                     addElementSupply(tokenDetails.elementId,0,  massToBurn[i], false, true);
                      
                 }else{
                     addElementSupply(tokenDetails.elementId, 1,  massToBurn[i], true, true);
                     _burnToken(_tokenIds[i]);
                 }
                 massBurned+=massToBurn[i];
                 powerBurned+=(tokenDetails.power*massToBurn[i]);
                 immunityBurned+=(tokenDetails.immunity*massToBurn[i]);
                 experienceBurned+=(tokenDetails.experience*massToBurn[i]);

             }
         }
         // Burn Burn Element
          NFTDetails memory burnTokenDetails= tokenInfo[_burnTokenId];
          if(burnTokenDetails.mass>1){
                tokenInfo[_burnTokenId].mass-=1;
                addElementSupply(burnTokenDetails.elementId,0, 1, false, true);
          }else{
                addElementSupply(burnTokenDetails.elementId, 1, 1, true, true);
                _burnToken(_burnTokenId);
                
          }

          powerBurned =(powerBurned/massBurned)+1;
          immunityBurned=immunityBurned/massBurned;
          experienceBurned=experienceBurned/massBurned;

          // Mint result NFT
          _mintWithoutValidation(msg.sender, _resultId, _resultMass,powerBurned, immunityBurned, experienceBurned);
          addElementSupply(_resultId,1,_resultMass, false, false);
    }  
    
    function stringToBytes1(string memory source) public pure returns (bytes1  result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 1))
    }
}

    function mint (string[] memory _elements, uint8[] memory _mass) external payable {
        require(mintingStage>0, "premint/public mint not active" );
        require(_elements.length == _mass.length, "wrong elements/mass" );
        uint32 totalWeight=0;
        // Additional Validation
        for (uint256 i = 0; i < _elements.length; i++) {
             bytes1   elementId= bytes1( bytes(_elements[i]) );
            // Can Mint only Basic Elements
            require(elements[elementId].parents.length==0,   " Not a basic Element" );
            // Check Basic Elements Supply Cap : [ if parents is null, its a basic element]
             require(basicElementMintedCount[elementId]  + _mass[i] <= basicElementSupplyCap, "supply cap" );
            //changed to 
           // require(basicElementMintedCount[elementId]  + _mass[i] <= elements[elementId].totalSupply, "supply cap" );
            totalWeight+=_mass[i];
        }
        require( totalWeight >0, "No elements selected" );
        if(mintingStage==1){ // Is freemint
            //Check Whitelist
            require( totalWeight <= preMintAddresses[msg.sender], "WL Alloc Cap" );
        }else {
            if(mintingStage==2){ //Is Pre Mint
                
                require( totalWeight <= preMintAddresses[msg.sender], "WL Alloc Cap" );
            
            }else if(mintingStage==3){ //Is public Mint
                // do nothing
            }
            // Check payable amount
            require( totalWeight * mintPrice <= msg.value, "amount low" );
        }

        // Check max mint per transaction
        require(totalWeight<=basicElementPreMintCap, "user mint cap" );

        // --------- START MINTING -------------------
        if(mintingStage<=2){ // Is premint
            preMintAddresses[msg.sender] -= totalWeight;
        }else if(mintingStage==3){ // Is public Mint
            
        }
        for (uint256 i = 0; i < _elements.length; i++) {
            bytes1   elementId= bytes1( bytes(_elements[i]) );
            // For basic element mint Count
            basicElementMintedCount[elementId]+=_mass[i];
             addElementSupply(elementId,1,_mass[i], false, false);
            _mintWithoutValidation(msg.sender,elementId,_mass[i],_randomRarity(uint(_mass[i])),_randomRarity(uint(_mass[i])),0);
        }
       
     }

    
    function _randomRarity(uint checks) private returns (uint32){
        uint totalR=0;
        for(uint i=0;i<checks;i++){
            totalR+=uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce++))) %  (raritykeys.length);
        }
        if(checks>1){
            totalR=totalR/checks;
        }
        return raritykeys[totalR]  ;
    }
    
    function _getArtWeight(  uint32 mass, uint32 power,  uint32 immunity) private view  returns (uint256){
       uint256 totalWeight= (mass+power+immunity)/artLevelWeight;
       if(totalWeight<maxLevelWeight){
           return totalWeight;
       }else{
           return maxLevelWeight;
       }
    }

    function _burnToken(uint256 tokenId  ) internal {
        delete tokenInfo[tokenId] ;
        _burn(tokenId );
    }

    function _mintWithoutValidation(address to, bytes1 elementId, uint32 mass, uint32 power,  uint32 immunity,  uint32 experience) internal {
        // Element Should Exist
        require(elementExists(elementId), "Element Not Exists");
        // Add token Count
        lastTokenId++;
        // Add token metadata
        tokenInfo[lastTokenId]=NFTDetails({elementId:elementId, mass: mass, power:power, immunity:immunity, experience:experience});
        // Mint
        _safeMint(to, lastTokenId);
        emit Mint(to, lastTokenId);
    }
 

    function tokenURI(uint256 tokenId) public view  virtual  override  returns (string memory)
    {
        require( _exists(tokenId), "nonexistent token" );
        require( bytes(baseURI).length >0,"baseuri error");
        return  Meta.getMeta(tokenId,_getArtWeight( tokenInfo[tokenId].mass, tokenInfo[tokenId].power, tokenInfo[tokenId].immunity) , tokenInfo[tokenId],elements[tokenInfo[tokenId].elementId],externalURI,baseURI);
    }


  

    // Update Elements Master error
    function addNftElement(
        string memory _elementId,
        string memory _elementName,
        string[] memory _parents,
        uint8 tier
    ) external onlyOwner {
        bytes1   elementId= bytes1( bytes(_elementId) );
        require( !elementExists(elementId), "Exist" );
        bytes1[]  memory parents =new  bytes1[](_parents.length);
        for(uint i=0;i<_parents.length;i++){
            parents[0]= (bytes1( bytes(_parents[i]) ));
        }
        elements[elementId] = Element({name: bytes(_elementName), parents: parents, supply:0, supplyMass:0, tier:tier});
        elementIds.push(elementId);
    }
    function updateNftElement(
        string memory _elementId,
        string memory _elementName,
        string[] memory _parents,
        uint8 tier
    ) external onlyOwner {
         bytes1   elementId= bytes1( bytes(_elementId) );
        require( elementExists(elementId), "Not Exist" );
        bytes1[] memory parents=new  bytes1[](_parents.length);
        for(uint i=0;i<_parents.length;i++){
            bytes1   parentId=bytes1( bytes(_parents[i]) );
            require( elementExists(parentId), "Not Exist" );
            parents[i]=parentId;
        }
        elements[elementId].name =bytes(_elementName);
        elements[elementId].parents =parents; 
        elements[elementId].tier =tier; 
    }
    // Other basic Utilities
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    function setBaseURI(string memory _newURI,bool  isExternal) public onlyOwner {
        if(isExternal){
            externalURI=_newURI;
        }else{
            baseURI = _newURI;
        }
        
    }
    function setCost(uint256   _newCost) public onlyOwner {
        mintPrice = _newCost;
    }
    function setLevelWeight( uint32 _artLevelWeight,uint32 _maxLevelWeight) public onlyOwner {
        if(_artLevelWeight>0){
            artLevelWeight = _artLevelWeight;
        }
        if(_maxLevelWeight>0){
            maxLevelWeight = _maxLevelWeight;
        }
    }
    function setSupplyCap(uint32 _basicElementSupplyCap ) public onlyOwner {
          basicElementSupplyCap =_basicElementSupplyCap;
    }
    function setMintCap(  uint32 _basicElementPreMintCap) public onlyOwner {  
      basicElementPreMintCap = _basicElementPreMintCap;
    }
    function setMintingStage(uint8   _stage) public onlyOwner {
        mintingStage = _stage;
    }
    function elementExists(bytes1  _elementId) internal view returns (bool ){
        bool doesListContainElement = false;
        for (uint i=0; i < elementIds.length; i++) {
            if (_elementId == elementIds[i]) {
                doesListContainElement = true;
            }
        }
        return doesListContainElement;
    }

 

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override{
        super._beforeTokenTransfer(from, to, tokenId);
        if(to!=address(0) && from!=address(0)){
             tokenInfo[tokenId].experience+=1;
        }
    }
 
}



