
// SPDX-License-Identifier: BUSL-1.1
// Copyleft: The NFTs minted by RECT.ART are free works, you can copy, distribute, and modify them under the terms of the Free Art License https://artlibre.org/licence/lal/en/

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./ownable.sol";
import "./IERC20.sol";


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}


contract MondrianNFT is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    using Strings for uint256;

    address  bidToken;

    address constant cfoAddress=0xC37f3a8c511329C9028b8D82f491847256B56dE7;
    address constant cooAddress=0xC37f3a8c511329C9028b8D82f491847256B56dE7;
    address  bonusPoolAddress;
    address  devPoolAddress; 
      
    event MLOG_AUCTION(
        uint256  artid,
        uint256  lastPrice, 
        uint256  curPrice,
        uint256  bid,
        address  lastOwner,
        address  buyer,
        address  inviterAddress
    );
    event MLOG_NEWNFT(
        uint256  artid,
        address  artist,
        uint256  id
    );
    
    //Mondrian NFT
    //following items could be changed by coo
    uint256 private bidAward;
    uint256 private invitationAwardShare;
    uint256 private bonusAwardShare;
    uint256 private send_gas_limit;
    
    mapping(uint256 => uint256) private  maxMap;
    mapping(uint256 => uint256) private mRects1;
    mapping(uint256 => uint256) private mRects2;
    
    mapping(uint256 => uint256) private rounds;
    mapping(uint256 => address) private artists;
    
    function creatMondrianNFT(uint256 parent, uint256 rect1, uint256 rect2,uint256 id)external {
        require((rect1!=0)&&(rect2!=0), "rect can not be zero");
        require(_exists(parent), "parent not existed");

        uint256 newid=0;
        for(uint256 i=0;;i++){
            require(i<32, "parent must < 32byte");
            
            uint256 p=getNByte(parent,i);
            
            if(p==0){
                uint256 max=maxMap[parent];
                require(max<255, "can not set parent for already max 255");
                
                newid=setNByte(parent,i,max+1);
                maxMap[parent]=max+1;
                
                break;
            }
            
        }
        
        mRects1[newid]=rect1;
        mRects2[newid]=rect2;
        
        _safeMint(msg.sender, newid);
        artists[newid]=msg.sender;
        emit MLOG_NEWNFT(newid,msg.sender,id);
        
    }

    //0 is first byte
    function getNByte(uint256 u, uint256 n)internal pure returns (uint256) {
        uint256 firstN = (u>>((n)*8))&0xff;
        return firstN;
    } 
    //0 is first byte
    function setNByte(uint256 u, uint256 n,uint256 b)internal pure returns (uint256) {
        //clear the byte to zero
        uint256 mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00;
    
        if(n>0){
            mask=mask<<(n*8)|(mask>>((32-n)*8));
        }
        u=u&mask;
        //set the byte
        u=u|(b<<(n*8));
        return u;
    } 
    
    function getNByteUint24(uint256 u, uint256 n)internal pure returns (uint256) {
        uint256 firstN = (u>>((n)*8))&0xffffff;
        return firstN;
    } 
    
    function getParent(uint256 u, uint256 n)internal pure returns (uint256) {
        if(n==0){
            return 0;
        }
        uint256 mask=0xff;
        for(uint256 i=0;i<n;i++){
            mask=mask|(0xff<<(i*8));
        }
       
        return u&mask;
    } 
    function getLastParent(uint256 u)internal pure returns (uint256) {
        uint256 mask=0xff;
        for(uint256 i=0;i<32;i++){
            if(u&(0xff<<(i*8))==0){
                break;
            }
            mask=mask|(0xff<<(i*8));
        }
        return u&(mask>>8);
    } 
    
    string constant p0='<svg width="240" height="240" xmlns="http://www.w3.org/2000/svg" version="1.1">';
    string constant p1='<rect x="';
    string constant p2='" y="';
    string constant p3='" width="';
    string constant p4='" height="';
    string constant p5='" style="fill:#';
    string constant p6='" />';
    string constant p9 = '</svg>';
    
    struct Ri{       
        uint256 px;
        uint256 py;
        uint256 w;
        uint256 h;       
        uint256 c;
    }   
     
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
   

        string memory output = string(abi.encodePacked(p0));
 

        uint256 rect1;
        uint256 p;
        uint256 x;
        Ri memory ri;
        
        for(uint256  i=1;;i++){
            p=getParent(tokenId,i);
           
            for(uint j=0;j<2;j++){
                rect1=j==0?mRects1[p]:mRects2[p];
                
                for(x=0;x<4;x++){                  
                    ri.px=rect1&0xff;
                    rect1>>=8;
                    
                    ri.py=rect1&0xff;
                    rect1>>=8;
                   
                    ri.w=rect1&0xff;
                    rect1>>=8;
                    
                    ri.h=rect1&0xff;
                    rect1>>=8;
                    //skip zero rect
                    if((ri.w==0)&&(ri.h==0)){
                        continue;
                    }
                    
                    ri.c=rect1&0xffffff;
                    rect1>>=24;
                    
                    //output = string(abi.encodePacked(output, p1,ri.px.toString(), p2,ri.py.toString(),p3,ri.w.toString(),p4,ri.h.toString(),p5,uint24tohexstr(ri.c),p6));

                    output = string(abi.encodePacked(output, p1,ri.px.toString(), p2,ri.py.toString(),p3));
                    output = string(abi.encodePacked(output,ri.w.toString(),p4,ri.h.toString(),p5,uint24tohexstr(ri.c),p6));
                }
            }
            
            
            if(p==tokenId){
                break;
            }
            
        }
        
        bytes memory bytesStringTrimmed = new bytes(8);
        for (uint j = 0; j < 4; j++) {
            bytesStringTrimmed[j] = bytes1(uint8(getNByte(mRects1[tokenId],28+j)));
        }
        for (uint j = 0; j < 4; j++) {
            bytesStringTrimmed[4+j] = bytes1(uint8(getNByte(mRects2[tokenId],28+j)));
        }


        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "',string(bytesStringTrimmed), '", "description": "Collaborative, Evolvable & Self-Financing NFT, Powered by TopBidder", "image": "data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(output, p9)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    uint256[] private priceList;
     function price(uint256 _round) internal
     returns (uint256)
     {
         if(_round>priceList.length){
             uint256 lastValue=priceList[priceList.length-1];
             for(uint256 i=priceList.length;i<_round;i++){
                 lastValue=lastValue*11/10;
                 priceList.push(lastValue);
             }
             return lastValue;
         }
         return priceList[_round-1];
     }     
     
     function initRoundPrice() internal
     {
         uint256 lastValue=0;
         for(uint256 i=1;i<12;i++){
            if(i<11){
                lastValue=i*0.05 ether;
            }else{
                lastValue=lastValue*11/10;
            }
            priceList.push(lastValue);
         }
     } 
    function bid(address inviterAddress, uint256 artid) nonReentrant public payable
    {
         require(_exists(artid),"artid not exist");
         require(artid>0,"art 0 can not bid");
         address lastOwner=ownerOf(artid);
         require(lastOwner!=msg.sender, "ERR_CAN_NOT_PURCHASE_OWN_ART");       
         uint256 r=rounds[artid];
         uint256 curprice=0;
         if(r>0){
             curprice=price(r); 
         }
        uint256 payprice=price(r+1);
        require(msg.value>=payprice, "ERR_NOT_ENOUGH_MONEY");
        
         //refund extra money
         payable(msg.sender).call{value:msg.value-payprice,gas:send_gas_limit}("");
         
         uint256 smoney=payprice-curprice;
         
         payable(artists[artid]).call{value:smoney/2,gas:send_gas_limit}("");

         uint256 parent=getLastParent(artid);
         if(parent==0){
             payable(devPoolAddress).call{value:smoney/10,gas:send_gas_limit}("");
         }else{
             payable(ownerOf(parent)).call{value:smoney/10,gas:send_gas_limit}("");
         }
         
         payable(bonusPoolAddress).call{value:smoney*bonusAwardShare/100,gas:send_gas_limit}("");
        
         payable(inviterAddress).call{value:smoney*invitationAwardShare/100,gas:send_gas_limit}("");
        
         payable(lastOwner).call{value:smoney*3/10+curprice,gas:send_gas_limit}("");

         if(IERC20(bidToken).balanceOf(cfoAddress)>=bidAward){
                  IERC20(bidToken).transferFrom(cfoAddress,msg.sender,bidAward);                  
          }
         
         rounds[artid]++;
         _transfer(lastOwner, msg.sender, artid);

         emit MLOG_AUCTION(artid, curprice,payprice,bidAward,lastOwner,msg.sender,inviterAddress );

    }
    
    function uint8tohexchar(uint8 i) internal pure returns (uint8) {
        return (i > 9) ?
            (i + 87) : // ascii a-f
            (i + 48); // ascii 0-9
    }
    
    function uint24tohexstr(uint256 i) internal pure returns (string memory) {
        bytes memory o = new bytes(6);
        uint24 mask = 0x00000f;
        o[5] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[4] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[3] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[2] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[1] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[0] = bytes1(uint8tohexchar(uint8(i & mask)));
        return string(o);
    }
    
    function changeBidAward(uint256 newBidAward)external{
        require(cooAddress==msg.sender, "ERR_MUST_COO"); 
        bidAward=newBidAward;
    }
    function changeShare(uint256 newInvitationShare,uint256 newBonusShare)external{
        require(cooAddress==msg.sender, "ERR_MUST_COO"); 
        invitationAwardShare=newInvitationShare;
        bonusAwardShare=newBonusShare;
    }
    function changePoolAddress(address _bonuspool,address _devpool)external{
        require(cooAddress==msg.sender, "ERR_MUST_COO"); 
        bonusPoolAddress=_bonuspool;
        devPoolAddress=_devpool;
    }
    function changeGasLimit(uint256 _gas_limit)external{
        require(cooAddress==msg.sender, "ERR_MUST_COO"); 
        send_gas_limit=_gas_limit;
    }

    constructor(address _bid) ERC721("Rect.Art", "RECT") Ownable() {
        bidToken=_bid;

        initRoundPrice();
        devPoolAddress=msg.sender;
        bonusPoolAddress=msg.sender;
        send_gas_limit=21000;
        artists[0]=devPoolAddress;
        //this address should not be contract as receive ERC721
        _safeMint(devPoolAddress, 0);
        bidAward=50 ether;
        invitationAwardShare=2;
        bonusAwardShare=8;
    }
}
