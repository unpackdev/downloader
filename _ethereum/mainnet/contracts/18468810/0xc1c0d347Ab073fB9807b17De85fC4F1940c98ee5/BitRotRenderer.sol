// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16;

import "./Ownable.sol"; 
import "./DynamicBuffer.sol"; // Used to generate the array of links to the artworks
import "./Strings.sol";
import "./Base64.sol";



contract BitRotRenderer is Ownable {

  using DynamicBuffer for bytes;

  // init traits
  uint256[] public billValues = [1,2,3,4,5,6,7,8,9,10,20,50,69,100,200,420,500];
  uint256[] public peopleDecentralizedRates = [0,2,5,50,30,43,47,31,25,38,26,35,38,50,3,40,32,50,41,38,1,46,44];
  uint256 nbBuildings = 11;
  uint256[] public buildingDecentralizedRates = [0,3,15,13,5,3,35,6,3,47,50];
  string[] public colorSchemes = ["SILVER", "COPPER", "GOLDEN", "DUSK", "ROYAL", "KUSH", "DEEPPURPLE", "LAVENDER", "TWILIGHT", "HONEY", "SUNNY", "MUSTARD", "DAWN", "BLOODY", "AUTUMN", "CRIMSON", "HORIZON", "RED", "EMBER", "CITRUS", "COAL", "BLOSSOM", "LIME", "MIDNIGHT", "BAHAMAS", "PATRIOT", "COSMOS", "OCEAN", "LAGOON", "PINE", "FOREST", "ALGAE", "MOSS"];

  // trait infos
  string[] public peopleNames = ["FINK", "LAGARDE", "BUFFET", "FINNEY", "MUSK", "SZABO", "VITALIK", "TURING", "SHANNON", "LOVELACE", "BABBAGE", "ARMSTRONG", "CZ", "NAKAMOTO", "GENSLER", "PEPE", "SAYLOR", "WEI", "6529", "COZOMO", "SBF", "STALLMAN", "TORVALDS"];
  string[] public billValuesString = ['ONE','TWO','THREE','FOUR','FIVE','SIX','SEVEN','EIGHT','NINE','TEN','TWENTY','FIFTY','SIXTY-NINE','ONE HUNDRED','TWO HUNDRED','FOUR HUNDRED AND TWENTY','FIVE HUNDRED'];
  string[] public buildingNames = ["BLK","FED","IMF","ECB","CCB","NYSE","BULL","LDN","USDT","ETH","BTC"];
  string public thankyou = "FingerprintsDAO & Highlight for helping me make this possible. Special thanks to Ishan and Klamt. Raf Grassetti for the amazing PEPE artwork contribution. Americasroof at English Wikipedia, CC BY-SA 3.0 <https://creativecommons.org/licenses/by-sa/3.0>, via Wikimedia Commons. AgnosticPreachersKid, CC BY-SA 3.0 <https://creativecommons.org/licenses/by-sa/3.0>, via Wikimedia Commons. Norbert Nagel, CC BY-SA 3.0 <https://creativecommons.org/licenses/by-sa/3.0>, via Wikimedia Commons. Max12Max, CC BY-SA 4.0 <https://creativecommons.org/licenses/by-sa/4.0>, via Wikimedia Commons. Ken Lund from Reno, Nevada, USA, CC BY-SA 2.0 <https://creativecommons.org/licenses/by-sa/2.0>, via Wikimedia Commons. Sealy j, CC BY-SA 4.0 <https://creativecommons.org/licenses/by-sa/4.0>, via Wikimedia Commons";

  // init a bunch of variables
  address[] public contractList;
  string public arweaveGateway;
  string public ipfsGateway;

  constructor(
    address[] memory contractList_,
    string memory arweaveGateway_,
    string memory ipfsGateway_
  ){
    contractList = contractList_; // initialize the array of addresses at which to find the NFTs (example BAYC contract address)
    arweaveGateway = arweaveGateway_;
    ipfsGateway = ipfsGateway_;
  }


  // TRAIT GENERATION _________________________________________________________________________________

  function getSeed(bytes32 blockHash , uint256 tokenId , uint256 timestamp) internal pure returns(uint256) {
    bytes32 packedData = keccak256(abi.encodePacked(blockHash, tokenId, timestamp));
    return uint256(packedData) % (10 ** 6);
  }

  function next(uint256 seed) public pure returns (uint256 result) {
    return uint256(keccak256(abi.encodePacked(seed))) % (10 ** 6);
  }

  function getIndex(uint256 seed, uint256 upperLimit) public pure returns (uint256 newSeed, uint256 rndNumber) {
    require(upperLimit > 0, "Upper limit should be greater than 0");
    seed = next(seed);
    return ( seed , seed % (upperLimit+1));
  }


  // CONTRACT _________________________________________________________________________________

  function fetchTokenURIs() internal view returns (bytes memory) {
    bytes memory uriList = DynamicBuffer.allocate(2**16);
    for (uint i = 0; i < contractList.length; i++) {
      if(i>0){ uriList.appendSafe('","'); }
      if(i == 3) { // this collection starts at 160... 
        uriList.appendSafe(abi.encodePacked(ICaller(contractList[i]).tokenURI(160)));
      }
      else if(i == 10){ // this collection doesn't use tokenURI but uri
        uriList.appendSafe(abi.encodePacked(ICaller(contractList[i]).uri(1)));
      }
      else{
        uriList.appendSafe(abi.encodePacked(ICaller(contractList[i]).tokenURI(1)));
      }
    }
    uriList.appendSafe('","onchain","onchain","onchain","onchain","onchain","onchain'); // since even view functions have gas limit, these are hardcoded as it's known they are onchain
    return uriList;
  }

  function fetchImages(address storageContract) internal view returns (bytes memory){
    return abi.encodePacked('[',
        '"',ICaller(storageContract).fileContents("peopleLowres.avif"),'",',
        '"',ICaller(storageContract).fileContents("peopleSigLowres.avif"),'",',
        '"',ICaller(storageContract).fileContents("buildingsLowres.avif"),'",');
  }

  function getTraits(uint256 seed) public view returns (string[] memory traitList) {
      traitList = new string[](7);
      uint256 newSeed;
      uint256 index;
      uint256 decentralizedPercent;

      (newSeed,index) = getIndex(seed, billValues.length-1);
      traitList[0] = Strings.toString(billValues[index]);

      (newSeed,index) = getIndex(newSeed, peopleDecentralizedRates.length-1);
      traitList[1] = peopleNames[index];
      decentralizedPercent = peopleDecentralizedRates[index];

      (newSeed,index) = getIndex(newSeed, nbBuildings-1);
      traitList[2] = buildingNames[index];
      traitList[5] = Strings.toString( decentralizedPercent + buildingDecentralizedRates[index] );

      (newSeed, index) = getIndex(newSeed, 200);
      int indexTrend = int(index) - 100;
      traitList[3] = indexTrend < 0 ? string(abi.encodePacked("-", Strings.toString(uint(-indexTrend)))) : Strings.toString(uint(indexTrend));
      (int256(index) - 100) >= 0 ? traitList[6] = "Bullish" : traitList[6] = "Bearish";

      (newSeed,index) = getIndex(newSeed, colorSchemes.length-1);
      traitList[4] = colorSchemes[index];

      return traitList;
  }

  function generateHTML ( address storageContract, string memory injectedToken ) public view returns (bytes memory HTML) {

    string memory HTMLStart = '<!DOCTYPE html><html> <head> <meta charset="utf-8"> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <title>Bit Rot</title> <meta name="description" content=""> <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"> <link rel="icon" type="image/svg" href="data:image/svg+xml;charset=UTF-8,%3csvg xmlns=%22http://www.w3.org/2000/svg%22 xmlns:xlink=%22http://www.w3.org/1999/xlink%22 width=%2246px%22 height=%2246px%22%3e%3cpath fill-rule=%22evenodd%22 stroke=%22rgb(0, 0, 0)%22 stroke-width=%228px%22 stroke-linecap=%22butt%22 stroke-linejoin=%22miter%22 fill=%22rgb(255, 255, 255)%22 d=%22M7.993,7.993 L34.007,7.993 L34.007,34.007 L7.993,34.007 L7.993,7.993 Z%22/%3e%3c/svg%3e"/> <style>';
    string memory HTMLEnd = ' </head> <body> <div class="UI panzoom-exclude"> <div class="download loader"></div><div class="zoomUI panzoom-exclude"></div></div><dialog> <span id="modalText"></span> <div class="buttons"> <button onclick="modalChoice(false)">Cancel</button> <button onclick="modalChoice(true)">Continue</button> </div></dialog> </body></html>';

    HTML = abi.encodePacked(
      HTMLStart,
        ICaller(storageContract).fileContents("index.css"),
      '"</style><script src="https://cdn.ethers.io/lib/ethers-5.2.umd.min.js"></script>', // ethers
      '<script>',
        ICaller(storageContract).fileContents("hl-gen.js"),
      '</script><script>',
        ICaller(storageContract).fileContents("panzoom.min.js"),
      '</script><script>',
        injectedToken,
        ICaller(storageContract).fileContents("index.js"),
      '</script>',
      HTMLEnd 
    );

    return HTML;
    
  }

  function tokenURI( bytes32 blockHash , uint256 tokenId , uint256 timestamp, address storageContract, string memory previewsBaseUri) public view virtual returns (string memory) {

    uint256 seed = getSeed ( blockHash, tokenId, timestamp);
    string[] memory traitList = getTraits(seed);

    string memory traits =  string(abi.encodePacked(
      '[{"trait_type":"Value","value": "',
        traitList[0],' ETH',
      '"},{"trait_type":"Person","value": "',
        traitList[1],
      '"},{"trait_type":"Building","value": "',
        traitList[2],
      '"},{"trait_type":"Trend","value": "',
        traitList[3],
      '"},{"trait_type":"Color","value": "',
        traitList[4],
      '"},{"trait_type":"Decentralization","value": "',
        traitList[5],
      '"},{"trait_type":"Stance","value": "',
        traitList[6],
      '"}]'
    ));

    // prepare the token object to be injected into the HTML/JS
    string memory injectedToken = string(abi.encodePacked(
      'const injectedToken = {"blockHash": "',
        Strings.toHexString(uint(blockHash)),
      '", "',
      'tokenId": "',
        Strings.toString(tokenId),
      '", "',
      'timestamp": "',
        Strings.toString(timestamp),
      '", "',
      'seed": "',
        Strings.toString(seed),
      '", "',
      'traits": ',
        traits,
      ', "',
      'arweaveGateway": "',
        arweaveGateway,
      '", "',
      'ipfsGateway": "',
        ipfsGateway,
      '", "',
      'uriList": ["',
        fetchTokenURIs(),
      '"], "',
      'images": ',
        fetchImages(storageContract),
      "]};"
    ));

    bytes memory metadata =  abi.encodePacked(
      '{"name": "',
        traitList[0],"ETH ",traitList[4]," ",traitList[1],":",traitList[2],
      '", "',
      'description": "',
        'Bit Rot (noun): Refers to the stepwise corruption of digital information owing to an array of non-critical failures within a data storage device. Also termed as data decay or data rot.',
      '", "',
      'image": "',
        previewsBaseUri,'/',Strings.toString(tokenId),'.png',
      '", "',
      'animation_url": "data:text/html;base64,',
        Base64.encode(generateHTML(storageContract, injectedToken)),
      '", "',
      'attributes": ',
        traits,
      "}"
    );

    return encodeMetadataJSON(metadata);
  }

  // UTILS _________________________________________________________________________________
  function encodeMetadataJSON(bytes memory json) internal pure returns (string memory) {
      return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
  }

  function updateContractList(address[] memory _newContractList) public onlyOwner{
    contractList = _newContractList;
  }

  function updateIpfsGateway(string memory newIpfsGateway) public onlyOwner {
    ipfsGateway = newIpfsGateway;
  }

  function updateArweaveGateway(string memory newArweaveGateway) public onlyOwner {
    arweaveGateway = newArweaveGateway;
  }
}

interface ICaller{
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function uri(uint256 tokenId) external view returns (string memory);
    function fileContents(string calldata fileName) external view returns (string memory);
}