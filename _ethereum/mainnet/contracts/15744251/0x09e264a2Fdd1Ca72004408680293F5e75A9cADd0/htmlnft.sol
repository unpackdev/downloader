// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

// import some OpenZeppelin Contracts.
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./console.sol";

import "./Base64.sol";

contract htmlnft is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public owner;

    event NewDance(string dancedata);

    constructor() ERC721 ("Disco Dance", "DISCODANCE") {
        owner = msg.sender;
     }

    function generateDance(string memory _dancedata) public payable{

        require(msg.value == 0.01 ether, "Need to send exactly 0.01 ether");
        uint256 newItemId = _tokenIds.current();
        string memory finalDance = string(abi.encodePacked('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1" /><title>Disco Dance</title><script src="https://cdn.jsdelivr.net/npm/p5@1.4.0/lib/p5.js"></script><style>body{margin:0;}</style></head><body><script>0</script><div id="c"></div></body><script>var d="',_dancedata,'";var s=[],b=[],i,n=0;function preload(){i=loadImage("https://cdn.glitch.global/5f9f45bb-72ab-4b18-9f6d-301fec4e8c13/eye.png?v=1662428513528");}function setup(){let c=createCanvas(600, 600);c.parent("c");frameRate(16);for(let i=0,a=d.split(",");i<a.length;i+=2){const x=JSON.parse(a[i]),y=JSON.parse(a[i+1]);b.push({x,y});if(b.length===17){s.push(b);b=[];}}}function draw(){background(0);let p=s[n];strokeWeight(3);fill(255);stroke(100);line(p[10].x,p[10].y,p[8].x,p[8].y);line(p[8].x,p[8].y,p[6].x,p[6].y);line(p[9].x,p[9].y,p[7].x,p[7].y);line(p[7].x,p[7].y,p[5].x,p[5].y);strokeWeight(1);line(p[16].x,p[16].y,p[14].x,p[14].y);line(p[14].x,p[14].y,p[12].x,p[12].y);line(p[15].x,p[15].y,p[13].x,p[13].y);line(p[13].x,p[13].y,p[11].x,p[11].y);line(p[5].x,p[5].y,p[6].x,p[6].y);line(p[12].x,p[12].y,p[11].x,p[11].y);line(p[5].x,p[5].y,p[11].x,p[11].y);line(p[12].x,p[12].y,p[6].x,p[6].y);circle(p[0].x,p[0].y,2*dist(p[4].x,p[4].y,p[0].x,p[0].y));image(i,p[2].x-20,p[2].y,34,18);image(i,p[1].x,p[1].y,34,18);if(n<s[0].length){n++;}else{n=0;}}</script></html>'));
        string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"name": "',
                    // We set the title of our NFT as the generated word.
                    string(abi.encodePacked("Disco Dance #", uint2str(newItemId))),
                    '", "description": "an nft collection of dances which are made with the power of AI and YOU, by monolesan", "animation_url": "data:text/html;base64,',
                    Base64.encode(bytes(finalDance)),
                    '"}'
                )
            )
        )
    );
    // Just like before, we prepend data:application/json;base64, to our data.
    string memory finalTokenUri = string(
        abi.encodePacked("data:application/json;base64,", json)
    );
    console.log(finalTokenUri);

    // Actually mint the NFT to the sender using msg.sender.
    _safeMint(msg.sender, newItemId);

    // Set the NFTs data.
    _setTokenURI(newItemId, finalTokenUri);

    // Increment the counter for when the next NFT is minted.
    _tokenIds.increment();

    emit NewDance(_dancedata);
    }

    function getTotalNFTsMintedSoFar() public view returns (uint256) {
        return _tokenIds.current();
    }

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

    function withdraw() public onlyOwner{
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner { 
        require(msg.sender == owner, "Sender is not owner");
        _; 
    }
}