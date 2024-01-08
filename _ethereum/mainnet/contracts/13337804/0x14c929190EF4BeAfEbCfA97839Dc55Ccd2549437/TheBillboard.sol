// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Strings.sol";
import "./ERC721URIStorage.sol";
import "./Base64.sol";

contract TheBillboard is ERC721URIStorage {
  uint256 priceInWeis = 0;
  
  string storedFirstLine = "";
  string storedSecondLine = "";
  string storedThirdLine = "";

  event BillboardUpdated(string first, string second, string third, uint256 price, address indexed by);

  constructor() ERC721 ("TheBillboard", "THEBILLBOARD") {
    _safeMint(msg.sender, 1);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory openingSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 550 250'><style>.base { fill: white; font-family: sans-serif; font-size: 22px; }</style><rect width='100%' height='100%' fill='black' />";
    string memory firstOpeningLine = "<text x='50%' y=";
    string memory secondOpeningLine = " class='base' dominant-baseline='middle' text-anchor='middle'>";
    string memory openingJson = '{"name": "The Billboard", "description": "Fully on chain billboard. This NFT displays the latest text stored in The Billboard (3 lines of 50 bytes each) and allows its owner to control the contract balance.", "image": "data:image/svg+xml;base64,';


    string memory firstLineSvg = "";
    string memory secondLineSvg = "";
    string memory thirdLineSvg = "";

    
    if (bytes(storedFirstLine).length != 0) {
      firstLineSvg = string(abi.encodePacked(firstOpeningLine, "'35%'", secondOpeningLine, storedFirstLine, "</text>"));
    }

    if (bytes(storedSecondLine).length != 0) {
      secondLineSvg = string(abi.encodePacked(firstOpeningLine, "'50%'", secondOpeningLine, storedSecondLine, "</text>"));
    }

    if (bytes(storedThirdLine).length != 0) {
      thirdLineSvg = string(abi.encodePacked(firstOpeningLine, "'65%'", secondOpeningLine, storedThirdLine, "</text>"));
    }

    string memory finalSvg = string(abi.encodePacked(openingSvg, firstLineSvg, secondLineSvg, thirdLineSvg, "</svg>"));

    string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    openingJson,
                    Base64.encode(bytes(finalSvg)),
                    '"}'
                )
            )
        )
    );

    string memory finalTokenUri = string(
        abi.encodePacked("data:application/json;base64,", json)
    );
    
    return finalTokenUri;
  }

  function updateBillboard(string memory firstLine, string memory secondLine, string memory thirdLine) public payable {
    require(msg.value > priceInWeis, "not enough ether sent to update");
    priceInWeis = msg.value;

    require(bytes(firstLine).length <= 50, "first line can be of 50 bytes max");
    require(bytes(secondLine).length <= 50, "second line can be of 50 bytes max");
    require(bytes(thirdLine).length <= 50, "third line can be of 50 bytes max");

    storedFirstLine = firstLine;
    storedSecondLine = secondLine;
    storedThirdLine = thirdLine;

    emit BillboardUpdated(firstLine, secondLine, thirdLine, msg.value, msg.sender);
  }

  function totalSupply() public pure returns(uint){
    return 1;
  }
  
  function getCurrentPriceInWeis() public view returns(uint) {
    return priceInWeis;
  }

  function withdraw(address payable sendToAddress, uint256 amountInWei) public {
    require(msg.sender == ownerOf(1), "you are not the owner");
    require(amountInWei <= address(this).balance, "not enough balance");
    sendToAddress.transfer(amountInWei);
  }
}