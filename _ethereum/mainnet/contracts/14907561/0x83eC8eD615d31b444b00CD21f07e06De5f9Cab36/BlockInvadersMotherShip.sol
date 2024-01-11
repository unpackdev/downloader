// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./stringutils.sol";
import "./stringutils2.sol";


//
//
//                              ///                                      
//                           ////////                                    
//                         /////////////                                 
//                     //////////////////                               
//                   ///////////////////////                            
//                ////////////////////////////                          
//    &&&&&&&&&     ////////////////////////     &&&&&&&&&&             
//                     ///////////////////                              
//      &&&&&&&&&&&      //////////////      &&&&&&&&&&&&               
//      &&&&&&&&&&&&&&      /////////     &&&&&&&&&&&&&&&               
//                &&&&&&      ////      &&&&&&&                         
//                  &&&&&&&          &&&&&&&                            
//            &&&&&    &&&&&&      &&&&&&&   &&&&&                      
//               &&&&&   &&&&&&&&&&&&&&    &&&&&                        
//                 &&&&&    &&&&&&&&&   &&&&&                           
//                    &&&&&   &&&&    &&&&&                             
//                      &&&&&      &&&&&                                
//                         &&&&& &&&&&                                  
//                           &&&&&&                                     
//                             &&                                       
//                                                                      
//                                                                      
//                      &&&     &&&&&    &&                             
//                    &&   &&   &&   &&  &&                             
//                   &&     &&  &&&&&&&  &&                             
//                    &&   &&   &&&   && &&                             
//                      &&&     &&&& &&  &&            
//
//========================================================================
// ONCHAIN BLOCK INVADERS - Upgradable Skin Renderer and Storage contract

interface ICargoShip  {
    function isCargoShip() external pure returns (bool);
    function unloadChroma(uint256 idx) external view returns (string[] memory,string[] memory,string[] memory,string[] memory,string memory,string memory);
}

contract BlockInvadersMotherShip is ReentrancyGuard, Ownable {
    using strings for *;
        
    uint256 constant BODY_COUNT  = 17;
    uint256 constant HEAD_COUNT  = 17;
    uint256 constant EYES_COUNT  = 32;
    uint256 constant MOUTH_COUNT = 21;
    
    struct dataStruct {
        string buffer;
        string prop;
        uint8 Cnt;
        uint8 tCnt;
        uint8 oCnt;
    }
    
   struct compIndexStruct {
        uint256 id0;  
        uint256 id1; 
        uint256 id2; 
        uint256 id3; 
        uint256 id4;
        uint256 idColH;
        uint256 idColB;
        }   

    //main data storage
    struct skinStruct{
    dataStruct[BODY_COUNT] bodies;
    dataStruct[HEAD_COUNT] heads;
    dataStruct[EYES_COUNT] eyes;
    dataStruct[MOUTH_COUNT] mouths;
    string skinName;
    }

    struct paintStruct{
    string[] eyesColor;
    string[] color;
    string[] backgroundColor;
    string[] colName;
    string   effect;
    string  chromaName;
    }
    mapping(uint256 => skinStruct) skin;
      
    //cuting the storing cost and execution costs to more than half using this neet SVG trick !
    //string mirror = ' transform= "scale(-1,1) translate(-350,0)"/>';
    string mirror = 'IHRyYW5zZm9ybT0gJ3NjYWxlKC0xLDEpIHRyYW5zbGF0ZSgtMzUwLDApJy8+';
    //string mirror2 = 'scale(-1,1) translate(-350,0)';
    string mirror2 = 'c2NhbGUoLTEsMSkgIHRyYW5zbGF0ZSgtMzUwLDAp';

    address private masterAddress ;
    address private cargoShipAddress;
      
    
    event MatterStorredLayer1();
    event MatterStorredLayer2();
    event MasterAddressSet(address masterAddress);
    event CargoShipAddressSet(address cargoShipAddress);
    
    //we lock the contract to be used only with the master address,the mint contract
    modifier onlyMaster() {
        require(masterAddress == _msgSender(), "Intruder Alert: Access denied in to the mothership");
        _;
    }
   
    constructor() Ownable(){ }
    
    function setMasterAddress(address _masterAddress) public onlyOwner {
        //store the address of the mothership contract
        masterAddress = _masterAddress;
         // Emit the event
        emit MasterAddressSet(masterAddress);
    }
    
    function setCargoShipAddress(address _cargoShipAddress) public onlyOwner {
        //store the address of the mothership contract
        cargoShipAddress = _cargoShipAddress;
         // Emit the event
        emit CargoShipAddressSet(cargoShipAddress);
    }
 
    //Acknowledge contract is `BlockInvadersMothership`;return always true
    function isMotherShip() external pure returns (bool) {return true;}
  
    function storeMatterLayer1(dataStruct[] memory _data,uint256 _idx,string memory _skinName ) external onlyOwner   {
        for (uint i = 0; i < BODY_COUNT; i++){
        skin[_idx].bodies[i] = _data[i];
        }
        for (uint i = BODY_COUNT; i < _data.length; i++){
            skin[_idx].eyes[i-BODY_COUNT] = _data[i];
        }
        skin[_idx].skinName= _skinName;
        emit MatterStorredLayer1();
    }
    
    function storeMatterLayer2(dataStruct[] memory _data,uint256 _idx ) external onlyOwner   {
        for (uint i = 0; i < HEAD_COUNT; i++){
            skin[_idx].heads[i] = _data[i];
        }
        for (uint i = HEAD_COUNT; i < _data.length; i++){
            skin[_idx].mouths[i-HEAD_COUNT] = _data[i];
        }
        emit MatterStorredLayer2();
    }

    function splitR(strings.slice memory slc,strings.slice memory rune,string memory col) internal pure returns(string memory)
    {
        return string(abi.encodePacked('PHJlY3QgeD0n',slc.split(rune).toString(),       //<rect x='
                                       'JyB5PSAn', slc.split(rune).toString(),          //'y='
                                       'JyB3aWR0aD0n',slc.split(rune).toString(),       //'width='
                                       'JyBoZWlnaHQ9ICAn',slc.split(rune).toString(),   //'height='
                                       'JyAgZmlsbD0g',col ));                           //'fill= 
    }

    function spiltRT(strings.slice memory slc,strings.slice memory rune,string memory col) internal pure returns(string memory)
    {
        return string(abi.encodePacked('PHJlY3QgeD0n',slc.split(rune).toString(),       //<rect x='
                                       'JyB5PSAn', slc.split(rune).toString(),          //'y= '  
                                       'JyB3aWR0aD0n',slc.split(rune).toString(),       //'width=' 
                                       'JyBoZWlnaHQ9ICAn',slc.split(rune).toString(),   //'height='
                                       'JyAgZmlsbD0g',col,                              //'fill=
                                       'IHRyYW5zZm9ybSA9ICcg' ));                       //'transform='
    }

    function splitO(strings.slice memory slc,strings.slice memory rune,string memory col) internal pure returns(string memory)
    {
        return string(abi.encodePacked('PGNpcmNsZSBjeD0n',slc.split(rune).toString(),      //<circle cx='
                                       'JyBjeT0n', slc.split(rune).toString(),             //'cy='
                                       'JyByID0n',slc.split(rune).toString(),              //'r=' 
                                       'JyAgZmlsbD0g',col ));                              //'fill='
    }

    function splitT(strings.slice memory slc,strings.slice memory rune)  internal pure returns(string memory)
    {
        return string(abi.encodePacked('IHRyYW5zbGF0ZSgg',slc.split(rune).toString(),      // translate(    
                                       'ICwg',slc.split(rune).toString(),                  // ,  
                                       'ICkgcm90YXRlICgg',slc.split(rune).toString(),      //) rotate ( 
                                       'KScgIC8+' ));                                      //)'  />
    }

    function joinR4(uint256 count,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
         for(uint i = 0; i < count;) {
             string memory ot  = splitR(slc,rune,col);
             om=string(abi.encodePacked(om,ot,mirror));
             o= string(abi.encodePacked(o,ot,'IC8+')); 
             i=i+4;
          }
        return (o,om);
    }

    function joinR16(uint256 count,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
         string memory o;
         string memory om;
         for(uint i = 0; i < count;) {
             string memory ot  = splitR(slc,rune,col);
             string memory ot1 = splitR(slc,rune,col);
             string memory ot2 = splitR(slc,rune,col);
             string memory ot3 = splitR(slc,rune,col);
             om = string(abi.encodePacked(om,ot,mirror,ot1,mirror,ot2,mirror,ot3,mirror));
             o  = string(abi.encodePacked(o,ot,'IC8+',ot1,'IC8+',ot2,'IC8+',ot3,'IC8+'));
             i=i+16;
          }
        return (o,om);
    }

    function joinO3(uint256 count,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
         for(uint i = 0; i < count;) {
             string memory ot  = splitO(slc,rune,col);
             om=string(abi.encodePacked(om,ot,mirror));
             o= string(abi.encodePacked(o,ot,'IC8+'));
             i=i+3;
          }
        return (o,om);
    }
 
    function joinO9(uint256 count,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
         
         for(uint i = 0; i < count;) {
             string memory c1 = splitO(slc,rune,col);
             string memory c2 = splitO(slc,rune,col);
             string memory c3 = splitO(slc,rune,col);
             om = string(abi.encodePacked(om,c1,mirror,c2,mirror,c3,mirror));
             o  = string(abi.encodePacked(o,c1,'IC8+',c2,'IC8+',c3,'IC8+'));
             i=i+9;
          }
        return (o,om);
    }
    function joinT7(uint256 count ,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
        for(uint i = 0; i < count;) {
             string memory ot  = spiltRT(slc,rune,col);
             string memory  t  = splitT (slc,rune);
             om=string(abi.encodePacked(om,ot,mirror2,t));
             o= string(abi.encodePacked(o,ot,t));
             i=i+7;
          }
        return (o,om);
    }

    function joinT21(uint256 count ,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
        string[6] memory sp;
        for(uint i = 0; i < count;) {
             sp[0]  = spiltRT(slc,rune,col);
             sp[1]  = splitT (slc,rune);
             sp[2]  = spiltRT(slc,rune,col);
             sp[3]  = splitT (slc,rune);
             sp[4]  = spiltRT(slc,rune,col);
             sp[5]  = splitT (slc,rune);
             om=string(abi.encodePacked(om,sp[0],mirror2,sp[1],sp[2] ));
             om=string(abi.encodePacked(om,mirror2,sp[3],sp[4],mirror2,sp[5]));
             o= string(abi.encodePacked(o,sp[0],sp[1],sp[2],sp[3],sp[4],sp[5]));
             i=i+21;
          }
        return (o,om);
    }
    
    function random(string memory input,uint max) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)))%max;
    }
     
    function randomW(string memory input,uint max) internal pure returns (uint256) {
        uint16[17] memory w = [3330,3200,3274,3264,3244,2234,2214,1594,1574,1564,554,544,334,324,315,205,44];
        
        uint256 rnd = uint256(keccak256(abi.encodePacked(input)))%27812;
        for (uint i=0;i<max;i++){
            if(rnd<w[i]){
                return i;
            }
            rnd -= w[i];
        }
        return 0;
    }

    function convertMattertoEnergy(dataStruct memory part,uint256 tokenId,string[] memory colorList,uint256 dataType) public view onlyMaster returns (string memory,uint256) {
       string memory o;
       string memory om;
  
       strings.slice memory slc = strings.toSlice( part.buffer);
       strings.slice memory rune =   strings.toSlice(",");
       uint256 did = 10; 

       uint256 id = random(stringutils2.UtoString(tokenId*2+dataType),colorList.length);
       did = id;
       uint256 offset = part.Cnt % 16;
       string memory col = colorList[id];
       if (dataType == 10){
           col = string(abi.encodePacked(col,'IGZpbHRlcj0ndXJsKCNuZW9uKScg')); //filter='url(#neon)' 
       }
       if ( part.Cnt >=16){
        (o,om) = joinR16(part.Cnt-offset,slc,rune,col);
       }
       (o,om) = joinR4(offset,o,om,slc,rune,col); 

       id = random(stringutils2.UtoString(tokenId*3+dataType),colorList.length);
       //check predominant color
       if ( part.Cnt < part.tCnt){
       did = id;}

       offset = part.tCnt % 21;
       col = colorList[id];
       if (dataType == 10){
           col = string(abi.encodePacked(col,'IGZpbHRlcj0ndXJsKCNuZW9uKScg')); //filter='url(#neon)' 
       }
       if (part.tCnt >=21){
       (o,om) = joinT21(part.tCnt-offset,o,om,slc,rune,col);
       }
       (o,om) = joinT7(offset,o,om,slc,rune,col);
      
       id = random(stringutils2.UtoString(tokenId*4+dataType),colorList.length);
       offset = part.oCnt % 9;
       col = colorList[id];
       if (dataType == 10){
           col = string(abi.encodePacked(col,'IGZpbHRlcj0ndXJsKCNuZW9uKScg'));//filter='url(#neon)' 
       }
       if (part.oCnt >=9){
       (o,om) = joinO9(part.oCnt-offset,o,om,slc,rune,col);
       }
       (o,om) = joinO3(offset,o,om,slc,rune,col);
       o = string(abi.encodePacked(o,om));

       return (o,did);

    }
    
    function generateBluePrint(skinStruct memory skn,paintStruct memory pnt,compIndexStruct memory p,uint8 cnt1,uint8 cnt2) public view onlyMaster returns (string memory) {
        string memory bp;
           
        bp = string(abi.encodePacked('PC9nPjwvc3ZnPiIsICJhdHRyaWJ1dGVzIjpbIHsidHJhaXRfdHlwZSI6IjAuQk9EWSIsInZhbHVlIjoi', skn.bodies[p.id1].prop,             //</g></svg> ","attributes": [ {"trait_type":"1.BODY", "value":"'
                                     'In0gLCB7InRyYWl0X3R5cGUiOiIxLkhFQUQiICwgInZhbHVlIjoi' ,skn.heads[p.id2].prop,                                                          //""} , {"trait_type":"2.HEAD" , "value":"
                                     'In0seyJ0cmFpdF90eXBlIjoiMi5CT0RZIENPTE9SIiwgInZhbHVlIjoi',pnt.colName[p.idColB],                                                                       
                                     'In0seyJ0cmFpdF90eXBlIjoiMy5IRUFEIENPTE9SIiwgInZhbHVlIjoi',pnt.colName[p.idColH],                                                                
                                     'In0gICwgIHsidHJhaXRfdHlwZSI6IjQuRVlFUyIsInZhbHVlIjoi',skn.eyes[p.id3].prop,                                                                    //"}  ,  {"trait_type":"3.EYES","value":"
                                     'In0seyJ0cmFpdF90eXBlIjoiNS5NT1VUSCIsInZhbHVlIjoi',skn.mouths[p.id4].prop ));                                                              //"} , {"trait_type":"4.MOUTH"," value":"
                                     
                                     
        bp = string(abi.encodePacked( bp,
                                     'In0gLCB7ICJ0cmFpdF90eXBlIjoiNi5TS0lOIiwgInZhbHVlIjoi',skn.skinName,                                                                        //" },{"trait_type":"Skin Name", "value":"
                                     'In0sIHsidHJhaXRfdHlwZSI6IjcuQ09MT1IgUEFMRVRURSIsInZhbHVlIjoi',pnt.chromaName,    
                                     'In0sIHsidHJhaXRfdHlwZSI6IjguVE9UQUwgU0tJTlMiLCJ2YWx1ZSIgOiAi', Base64.encode(stringutils2.uintToByteString(cnt1, 3)),                                        //"},{"trait_type":"Skins Count","value":"
                                     'In0seyJ0cmFpdF90eXBlIjoiOS5UT1RBTCBDT0xPUiBQQUxFVFRFUyIsInZhbHVlIjoi',Base64.encode(stringutils2.uintToByteString(cnt2, 3))                                 //"},{"trait_type":"Color Pallets Count","value":"
                                      ));
        return bp;
    }

    function launchPad(uint256 tokenId,uint8 idxSkin,uint8 idxChroma,uint8 cnt1,uint8 cnt2) public view onlyMaster returns (string memory) {
        string[5] memory p; 
        compIndexStruct memory part;
        paintStruct memory paint;
        
        ICargoShip cargoShip = ICargoShip (cargoShipAddress);
        (paint.eyesColor,paint.color,paint.backgroundColor,paint.colName,paint.effect,paint.chromaName) = cargoShip.unloadChroma(idxChroma);

        part.id0 = random  ( stringutils2.UtoString(tokenId),paint.backgroundColor.length);
        part.id1 = randomW ( stringutils2.UtoString(tokenId+36723),BODY_COUNT);
        part.id2 = randomW ( stringutils2.UtoString(tokenId+12323),HEAD_COUNT);
        part.id3 = random  ( stringutils2.UtoString(tokenId+232)  ,EYES_COUNT);
        part.id4 = random  ( stringutils2.UtoString(tokenId+3993) ,MOUTH_COUNT);
        
        p[0] = string(abi.encodePacked('PHJlY3Qgd2lkdGg9JzEwMCUnICBoZWlnaHQ9JzEwMCUnIGZpbGw9',paint.backgroundColor[part.id0],'Lz4gPGcgZmlsdGVyPSd1cmwoI25lb24pJyA+'));
        
        (p[4],part.idColH) = convertMattertoEnergy(skin[idxSkin].eyes[part.id3],tokenId,paint.eyesColor,10);
        (p[3],part.idColH) = convertMattertoEnergy(skin[idxSkin].mouths[part.id4],tokenId,paint.color,15);
        (p[2],part.idColH) = convertMattertoEnergy(skin[idxSkin].heads[part.id2],tokenId,paint.color,5);
        (p[1],part.idColB) = convertMattertoEnergy(skin[idxSkin].bodies[part.id1],tokenId,paint.color,1);

        p[0] = string(abi.encodePacked(p[0], p[1], p[2], p[3],"PC9nPjxnIGZpbGwtb3BhY2l0eT0nMC44NSc+",p[4])); 

        return string(abi.encodePacked(
                //"image_data": "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'>
                'data:application/json;base64,eyAgImltYWdlX2RhdGEiOiAiPHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHByZXNlcnZlQXNwZWN0UmF0aW89J3hNaW5ZTWluIG1lZXQnIHZpZXdCb3g9JzAgMCAzNTAgMzUwJz4g',
                paint.effect,
                p[0],
                generateBluePrint(skin[idxSkin],paint,part,cnt1,cnt2),
                //"}], "name":"OBI #,
                'In0gXSwibmFtZSI6Ik9CSSAj',
                 Base64.encode(stringutils2.uintToByteString(tokenId, 6)),
                //", "description": "OBI ..."} 
                'IiwiZGVzY3JpcHRpb24iOiAiVGhlIGZpcnN0IDEwMCUgT04gQ0hBSU4gcGZwIGNvbGxlY3Rpb24gd2l0aCBpbnRlcmNoYW5nZWFibGUgc2tpbnMgYW5kIGNvbG9yIHBhbGV0dGVzLiJ9'
            ));
    }
    
}

