// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ECDSA.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
//import "./Base64.sol";

// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}


// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------


    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }



    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;

        }
    }


}
/* ///// */


contract Imitation is ERC721Enumerable, Ownable, ReentrancyGuard { 

  using SafeMath for uint256;
  using ECDSA for bytes32;
  address public adminAddress = 0x5D30e3eB3d8Cda028D43D3b70d3285dE20FD4a2F;
  uint256 public cost = 0.12 ether; 
  uint256 public PerfectOnSell = 1;
  uint256 public MAX = 251; 
  uint256 public token_id = 1;
  bool public freeze = false;
  bool public startWhitelistSale = false;
  bool public startOpenSale = false;
  mapping (uint256 => uint256) private times;
  mapping (uint256 => uint256) private genOrder;
  mapping(address => uint256) public whitelistMints;
  uint256[] Attributes = [3,10,10,10,10,10,10,10,10];
  uint256[] allVariants = [1,2,3];
  bool public isMaxSupply = true;

  bool public decentralized = false; 



  string dataURLbase = "https://arweave.net/nxpkWgxAoOdyZDOUEuy2atvm9OE1_QV2s-1_lmRjOQE/";
  string dataURL = string.concat(dataURLbase, "layers");
  string dataURLplaceholder = string.concat(dataURLbase, "placeholder.JPG");
  string dataURLplaceholderGen = string.concat(dataURLbase, "placeholder.html");
  string baseHTML = '<html><meta name="viewport" content="width=device-width, initial-scale=1"><head><link href="';
  string loadStyles = "https://arweave.net/5zgxA9cz19qu0wdyKL8CVKHvvZE1A2tFNjGFWv3PLtU/stt.css";
  string preloader = string.concat('" rel="stylesheet"></head><body style="background-color: #000;"> <div class="cen"><canvas id="canvas" width="1800px" height="2500px"></canvas></div><script> const seed = "');
  string renderScript =  string.concat('; </script> <script src="', dataURLbase, 'render.js"></script>    <script> const ctx=document.getElementById("canvas").getContext("2d");let im=new Image;function p(){ctx.drawImage(im,canvas.width/2.2,canvas.height/2.2)}im.src=document.images[0].src,im.onload=()=>{p()},p();let d=[],n=0,dr=[];function draw(){ctx.clearRect(0, 0, canvas.width, canvas.height); n++,n>d.length-1&&dr.forEach((e=>{ctx.drawImage(e,0,0)}))}for(let e=0;e<document.images.length;e++)e>0&&d.push(document.images[e].src);d.forEach((e=>{let n=new Image;n.src=e,n.onload=()=>{draw()},dr.push(n)}));</script>');
  string preloadURL = 'https://soulgenesis.art/projectx/loadmeta.php';









  constructor() ERC721 ("Perfect Imitation", "Imitations") {
   
  }

    
    function ActivationTime(uint256 _tokenId)public view returns(uint256 year, uint256 month, uint256 day, uint256 hour) {

        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        require(genOrder[_tokenId] > 0, "not active");
        uint256 timestamp = times[_tokenId];
        (year, month, day, hour) = DateTime.timestampToDateTime(timestamp);

    }

    function whitlistSale(uint256 numberOfTokens, bytes memory signature) public payable nonReentrant{
        require(startWhitelistSale, "Sale is stoped");
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(sender);
        address signer = ECDSA.recover(message, signature);
        require(signer==adminAddress, "Sign not verified");

        require(whitelistMints[msg.sender] + numberOfTokens <= PerfectOnSell, "mint limit exceeded");
        require(numberOfTokens <= PerfectOnSell, "Purchase would exceed max supply");
        require(totalSupply().add(numberOfTokens) < MAX, "Purchase would exceed max supply of Perfects");
        require(msg.value >= cost * numberOfTokens, "Ether value sent is not correct");

        whitelistMints[msg.sender] += numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, token_id);
                token_id++;
        }
    }

    function openSale(uint256 numberOfTokens) public payable nonReentrant{
        require(startOpenSale, "Sale is stoped");
        require(numberOfTokens <= PerfectOnSell, "Purchase would exceed max supply");
        require(totalSupply().add(numberOfTokens) < MAX, "Purchase would exceed max supply of Perfects");
        require(msg.value >= cost * numberOfTokens, "Ether value sent is not correct");

        whitelistMints[msg.sender] += numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, token_id);
                token_id++;
        }
    }


    function teamMint( address  user, uint numberOfTokens) public payable nonReentrant onlyOwner{
      require(totalSupply().add(numberOfTokens) < MAX, "Purchase would exceed max supply of Harmonies");
        for(uint i = 0; i < numberOfTokens; i++) {
                _safeMint(user, token_id);
                token_id++;
        }
    }

     function checkBalance(address user)  public view returns(uint256){
        return whitelistMints[user];
    }


    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setSource(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        dataURLbase  = _url;
    }

    function setSourceGraphics(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        dataURL  = _url;
    }

    function setSourceGraphicsPlaceholder(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        dataURLplaceholder  = _url;
    }

    function setSourceGraphicsPlaceholderHtml(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        dataURLplaceholderGen  = _url;
    }

     function setStyles(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        loadStyles  = _url;
    }

    function setFreeze() public onlyOwner {
      freeze = true;
    }

    function setDecentralized() public onlyOwner {
       decentralized = !decentralized;
    }

   
    function setScriptURL(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        renderScript  = _url;
    }

    function setPreloaderURL(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        preloader  = _url;
    }

    function setPreviewURL(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        preloadURL  = _url;
    }

    function setAdminAddress(address adress) public onlyOwner {
      adminAddress = adress;
    }

    function toogleSale() public onlyOwner {
      startWhitelistSale = !startWhitelistSale;
    }

     function toogleOpenSale() public onlyOwner {
      startOpenSale = !startOpenSale;
    }

    function setLimit(uint256 _newLimit) public onlyOwner {
      PerfectOnSell = _newLimit;
    }


    function closeSale() public onlyOwner {
      require(!isMaxSupply, "Allready Set!!");
      isMaxSupply = true;
      MAX = totalSupply();
    }

    function isActiveToken(uint256 _tokenId) public view returns(uint256) {
      return times[_tokenId];
    }



    

 
    address t1 = 0x91C744fa5D176e8c8c2243a952b75De90A5186bc; 

    address t2 = 0xE0D80FC054BC859b74546477344b152941902CB6; 

    address t3 = 0xae87B3506C1F48259705BA64DcB662Ed047575Bb; 
     
 
    function withdraw() public payable nonReentrant onlyOwner {

        uint256 _u1 = address(this).balance * 34/100;
        uint256 _u2 = address(this).balance * 33/100;
        uint256 _u3 = address(this).balance * 33/100;

          require(payable(t1).send(_u1));
          require(payable(t2).send(_u2));
          require(payable(t3).send(_u3));
    }




    function NewPainting(uint256 _tokenId)  public payable {

        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        require(ownerOf(_tokenId) == msg.sender, "Can only from owner!!");

        if(genOrder[_tokenId] > 0){
            uint256 alldays =  ((((block.timestamp / 1 days) - (times[_tokenId]) / 1 days)) + 1); 
            require(alldays > 7, "wait");

            if(genOrder[_tokenId] == 4){
                genOrder[_tokenId] = 2;
            }else{
                genOrder[_tokenId] = genOrder[_tokenId] + 1;
            }

        }else{
            require(genOrder[_tokenId] == 0, "Already activated!!"); 
            genOrder[_tokenId] = 1;
        }

        times[_tokenId] = block.timestamp;
    }

  




    function genPlaceholder(uint256 _tokenId) internal view returns(string memory ) {

         string memory json = Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                     abi.encodePacked(
                                    '{"name": "Perfect Imitation #',
                                    Strings.toString(_tokenId),
                                    '", "description": "Just run the algorithm and observe the deep process of creating a new painting in seven days. Admire the finished work indefinitely, or erase it and create something new.", "image": "',dataURLplaceholder,
                                    '", "animation_url": "', dataURLplaceholderGen, '"}'
                                )
                                )
                            )
                        )
                    ); 
            string memory tokenUri = string(abi.encodePacked("data:application/json;base64,", json));
            return tokenUri;
    }


    function generator(uint256 _tokenId) public view returns(string memory ) {

      if(!_exists(_tokenId)||genOrder[_tokenId] < 1){
         string memory tokenUri = genPlaceholder(_tokenId);
         return  tokenUri;
      }else{

          uint256 alldays =  ((((block.timestamp / 1 days) - (times[_tokenId]) / 1 days)) + 1);

          if(alldays>7){ 
              alldays = 7; 
           }

          string memory finalHTML;
          string memory allSeed;
                
          for (uint256 l = 1; l < alldays+1; l++) { 
              allSeed = string.concat(allSeed, '-', Strings.toString( ((uint256(keccak256(abi.encodePacked( ((times[_tokenId]+_tokenId)*l) )))))));
          }

          finalHTML = string(abi.encodePacked(baseHTML, loadStyles, preloader, allSeed, '"; const dataURL = "', dataURL, '"',  '; const tokenId = "', Strings.toString(_tokenId), '"' , '; const order="', Strings.toString(genOrder[_tokenId]), '"',  renderScript,  '</body></html>'));   
          return  finalHTML;
      }
 
    }


    function genJson(uint256 _tokenId, string memory html) internal view returns(string memory ) {

       string memory dataHtml;
       string memory dataImage;

      if(decentralized){
           dataHtml = string.concat('data:text/html;base64,', Base64.encode(bytes(html)));
           dataImage = string.concat(dataURLbase, 'thimb.jpg');
       }else{
           dataHtml = string.concat(preloadURL, '?nft=', Strings.toString(_tokenId));
           dataImage  = string.concat(preloadURL, '?id=', Strings.toString(_tokenId));
       }


        string memory json = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"name": "Perfect Imitation #',
                            Strings.toString(_tokenId),
                            '", "description": "Just run the algorithm and observe the deep process of creating a new painting in seven days. Admire the finished work indefinitely, or erase it and create something new.", "image": "',dataImage, '", "animation_url": "',dataHtml,
                            '"}'
                        )
                    )
                )
            ); 
        string memory tokenUri = string(abi.encodePacked("data:application/json;base64,", json));
        return tokenUri;

    } 


 



    function tokenURI(uint256 _tokenId) override public view returns(string memory ) {

     require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );

            if(genOrder[_tokenId] < 1){

                string memory tokenUri = genPlaceholder(_tokenId);
                return  tokenUri;

            }else{

                string memory finalHTML;
        
                if(decentralized){
                    string memory allSeed;

                    uint256 alldays =  ((((block.timestamp / 1 days) - (times[_tokenId]) / 1 days)) + 1); 
   
                    if(alldays>7){ 
                        alldays = 7; 
                     }

                    for (uint256 l = 1; l < alldays+1; l++) { 
                        allSeed = string.concat(allSeed, '-', Strings.toString( ((uint256(keccak256(abi.encodePacked( ((times[_tokenId]+_tokenId)*l) )))) )));
                    }

                    finalHTML = string(abi.encodePacked(baseHTML, loadStyles, preloader, allSeed, '"; const dataURL = "', dataURL, '"',  '; const tokenId = "', Strings.toString(_tokenId), '"' , '; const order="', Strings.toString(genOrder[_tokenId]), '"',  renderScript,  '</body></html>'));
                    string memory tokenUri = genJson(_tokenId,  finalHTML);
                    return  tokenUri;

                }else{
                    string memory tokenUri = genJson(_tokenId,  '0');
                    return  tokenUri;

                }
            }
     
          
    }

  
  }