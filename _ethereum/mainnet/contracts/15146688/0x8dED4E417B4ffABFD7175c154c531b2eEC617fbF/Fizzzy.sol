// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ReentrancyGuard.sol";

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Fizzzy is ERC721, Ownable, VRFConsumerBaseV2, ReentrancyGuard{
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    address vrfCoordinator = 	0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint64 public s_subscriptionId;
    address s_owner;

    uint256 private chainlinkRandomSeed;
    bool public reveal = false;

    constructor(uint64 subscriptionId)
    VRFConsumerBaseV2(vrfCoordinator)
    ERC721("Fizzzy","Fizzzy")
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    function startReveal() public onlyOwner {
        require(!reveal, "REVEAL_ALREADY_DONE");
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
            );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
        ) internal override {
            chainlinkRandomSeed = randomWords[0];
            reveal = true;
        }
    
    function claim(uint256 tokenId) public nonReentrant {
        require(balanceOf(_msgSender()) < 5 && tokenId < 125, "Unable to mint");
        _safeMint(_msgSender(), tokenId);
    }
    


    // TOKENURI AND ATTRIBUTE FUNCTIONS
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string(
                abi.encodePacked(
                  '{"name": "Fizzzy #',
                    Strings.toString(tokenId),
                    '", "description": "Metadata is generated fully on-chain, and the color is determined by chainlink VRF","image": "data:image/svg+xml;base64,',
                    Base64.encode(
                        bytes(generateSvg(tokenId))
                    ),
                    '"}'
                )
              )
            )
          )
        ));
    }


    // SVG generator function
    function generateSvg(uint256 tokenId) internal view returns (string memory) {
        uint256 R = 100;
        uint256 G = 100;
        uint256 B = 100;
        if(reveal){
            R = uint256(keccak256(abi.encodePacked(tokenId,chainlinkRandomSeed,'R'))) % 200;
            G = uint256(keccak256(abi.encodePacked(tokenId,chainlinkRandomSeed,'G'))) % 200;
            B = uint256(keccak256(abi.encodePacked(tokenId,chainlinkRandomSeed,'B'))) % 200;
        }
        

        return string(abi.encodePacked(
          '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">',
          '<rect x="0" y="0" width="1000" height="1000" fill="rgb(',Strings.toString(R),',',Strings.toString(G),',',Strings.toString(B),')"/>',
          recursionDot(101,1,50),
          '</svg>'
        ));
    }
    

    function recursionDot(uint256 x, uint256 y, uint256 st) internal view returns (string memory) {
        if(y>1000){
            return string(abi.encodePacked('<circle cx="',Strings.toString(x),'" cy="',Strings.toString(y),'" r="1" fill="white" />'));
        }

        if(x>1000){
            x -= 950;
            y += st;
            st += st/10;
        }

        return string(abi.encodePacked('<circle cx="',Strings.toString(x),'" cy="',Strings.toString(y),'" r="20" fill="white" />',
        recursionDot(x+100,y,st)));
    }

}
