// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./base64.sol";
import "./VRFConsumerBase.sol";

contract VectorField is ERC721URIStorage, VRFConsumerBase, Ownable {
    uint256 public tokenCounter;
    uint256 public constant MAX_SUPPLY = 300;
    uint256 public constant PRICE = .25 ether;
    
    mapping(bytes32 => address) public requestIdToSender;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public height;
    uint256 public price;
    uint256 public width;
    string[] public colors;

    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash, uint256 _fee) 
    VRFConsumerBase(_VRFCoordinator, _LinkToken)
    ERC721("Vector Field", "VCFD")
    {
        keyHash = _keyhash;
        fee = _fee;
        tokenCounter = 1;
        price = PRICE;
        height = 2000;
        width = 1500;
        colors = [
"#FAFAFA",
"#F5F5F5",
"#EEEEEE",
"#E0E0E0",
"#BDBDBD",
"#9E9E9E",
"#757575",
"#616161",
"#424242",
"#212121",
"#ECEFF1",
"#CFD8DC",
"#B0BEC5",
"#90A4AE",
"#78909C",
"#607D8B",
"#546E7A",
"#455A64",
"#37474F",
"#263238",
"#b71c1c",
"#DB3A3D",
"#E1C1A7",
"#D88C73",
"#D0C1AB"
];
    }
    
       
 function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
   
    function Claim() public payable returns (bytes32 requestId) {
        require(msg.value >= price, "Please send more ETH");
        require(tokenCounter <= MAX_SUPPLY, "All Fields have been minted");
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = tokenCounter; 
        requestIdToTokenId[requestId] = tokenId;
        tokenCounter = tokenCounter + 1;
        
    }

    

    function Mint(uint256 tokenId) public {
        
        require(bytes(tokenURI(tokenId)).length <= 0, "tokenURI is already set!"); 
        require(tokenCounter > tokenId, "TokenId has not been minted yet!");
        require(tokenIdToRandomNumber[tokenId] > 0, "Need to wait for the Chainlink node to respond!");
        uint256 randomNumber = tokenIdToRandomNumber[tokenId];
        string memory svg = generateSVG(randomNumber);
        string memory TokenID = uint2str(tokenId);
        string memory imageURI = svgToImageURI(svg);
        _setTokenURI(tokenId, formatTokenURI(imageURI, TokenID));
        
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        address nftOwner = requestIdToSender[requestId];
        uint256 tokenId = requestIdToTokenId[requestId];
        _safeMint(nftOwner, tokenId);
        tokenIdToRandomNumber[tokenId] = randomNumber;
        
    }

    function generateSVG(uint256 _randomness) public view returns (string memory finalSvg) {

       uint256 bgopacity = uint256(keccak256(abi.encode(_randomness + 1))) % 6;
        finalSvg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='", uint2str(height), "' width='", uint2str(width), "' fill='none' viewBox='500 100 1500 2000'><path d='M500 100h1500v2000H0z' fill= '#f4ebe2'/><path d='M500 100h1500v2000H0z'"));
        string memory color = colors[_randomness % colors.length];
        
        finalSvg = string(abi.encodePacked(finalSvg, " fill='", color, "' opacity='.", uint2str(bgopacity), "'/>"));
        
        for(uint i = 0; i < 3; i++) {
           
            string memory pathSvg = generatePath(uint256(keccak256(abi.encode(_randomness, i))));
            finalSvg = string(abi.encodePacked(finalSvg, pathSvg));
        }
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
    }

    function generatePath(uint256 _randomness) public view returns(string memory pathSvg) {
        
        uint256 x = uint256(keccak256(abi.encode(_randomness, height * 2 + 1))) % width;
        uint256 y = uint256(keccak256(abi.encode(_randomness, width + 1))) % height;
        uint256 w = uint256(keccak256(abi.encode(_randomness, width + 3))) % width;
        uint256 h = uint256(keccak256(abi.encode(_randomness, height * 3 + 1))) % height;
        uint256 opacity = uint256(keccak256(abi.encode(_randomness + 2))) % 9;

        pathSvg = string(abi.encodePacked( "<rect x='", uint2str(x), "' y= '", uint2str(y),"' width= '", uint2str(w), "' height='", uint2str(h), "' opacity='.", uint2str(opacity), "'"));

        string memory color = colors[_randomness % colors.length];
        pathSvg = string(abi.encodePacked(pathSvg, " fill='", color,"'/>"));
    }

      
    // From: https://stackoverflow.com/a/65707309/11969592
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }




    
    function svgToImageURI(string memory svg) public pure returns (string memory) {
        
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function formatTokenURI(string memory imageURI, string memory TokenID) public pure returns (string memory) {
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Field #',TokenID,'", "description":"300 Vector Fields randomly generated and stored on the Ethereum blockchain", "attributes":"", "image":"',imageURI,'"}'
                            )
                        )
                    )
                )
            );
    }

    }