// SPDX-License-Identifier: MIT
/**
* Introduction of this contract:

This contract represented the initiative of the Crypto Republic of Sigaland government to collect, organize, and issue its legal documents on IPFS using the NFT standard. 
Each minted NFT (token symbol: SLD) signified the official recognition by the Sigaland government of the content of its corresponding document, granting it legal validity.
The Crypto Republic of Sigaland is located between Croatia and Serbia, an unclaimed territory known to the local indigenous people as Gornja Siga or simply Siga. 
Cyrus Cisco (0xCC…7777) deployed this contract and minted the first SLD, becoming the first to claim ownership and governance rights over this land on the IPFS network and Ethereum mainnet. 
With this action, he proclaimed the establishment of the Crypto Republic of Sigaland.

* Original content of SLD#0:

Declaration of the Sovereignty of the Crypto Republic of Sigaland

To whom it may concern,

I, Cyrus Cisco, hereby solemnly declare, there is still a piece of terra nullius between Croatia and Serbia along the Danube River, known locally as Gornja Siga, which covers an area of about seven square kilometres. On the base of the above fact, I formally appoint myself as the Prince of Gornja Siga. This appointment encompasses all rights of ownership, including the land itself. Furthermore, I proclaim the creation of a sovereign nation: the Crypto Republic of Sigaland.

Historical Context

Gornja Siga, a piece of terra nullius along the Danube River, has long existed without clear sovereignty. Various geopolitical and territorial disputes have left the question of its sovereignty unresolved. I firmly believe that every region deserves clear sovereignty to foster development and stability.

Rationale

Given the aforementioned circumstances, the proclamation of the Crypto Republic of Sigaland is both justified and legitimate. As its Prince and founding father, I pledge to uphold the rights of the country and its citizens, striving for the sustainable development of the land.

Observations

Over the years, Gornja Siga, approximately 7 square kilometers in size, has languished in neglect. Despite claims of sovereignty by various parties, its small size and complex international territorial disputes have hindered its development. As a computer scientist, I, alongside my colleagues, aim to leverage our expertise in the Internet, Blockchain, Artificial Intelligence, and Web3 to ensure the Crypto Republic of Sigaland's recognition and development.

Titles and Governance

My title of Prince of Gornja Siga and subsequent titles of nobility for elite nationals are symbolic national honors. These titles, either hereditary or for life, do not confer any political rights. Initially, the Siga Improvement Governance Association, comprising myself and other co-founders, will oversee the nation's legislative, executive, diplomatic, and economic affairs. This association represents our nation's supreme governmental organization.

After much deliberation on the name of this land of hope with other founders of the nation, we were torn between three options: "Sigaland" aligns more with international naming conventions for lands, "Gornja Siga" is the traditional name given by the local inhabitants, and "Siga" is short and easy to remember. We have decided to give "Sigaland", "Gornja Siga", and "Siga" equal legal status as geographical names and official short names for our country. Similarly, "Crypto Republic of Sigaland" and "Crypto Republic of Gornja Siga" are given equivalent legal positions as the official full names of our nation. Both officials, civilians, and friendly nations are free to choose and use either name in both formal and informal occasions.

Furthermore, in alignment with our vision, the Crypto Republic of Sigaland will soon transition to a decentralized autonomous organization, the first of its kind globally, built on Web3 and Smart Contract technologies, allowing broader participation in governance.

Immediate Objectives

The Siga Improvement Governance Association commits to:

1.Globally announce our nationhood via global news media.
2.Develop the WEB3 DID digital identity system and introduce digital citizen ID and Passport applications.
3.Establish Sigaland as a hub for decentralized autonomous organizations.
4.Launch the Siga Blockchain, our primary national blockchain network.

These objectives will pave the way for various digital services, enhancing global awareness and goodwill towards our nation.

Closing Remarks

I earnestly seek the international community's understanding and support in recognizing the Crypto Republic of Sigaland's sovereignty. Through peaceful collaboration, we envision a blockchain digital democracy where private property is revered, and global citizens can apply for equal citizenship.

Our national motto: "Micro, but also can be a model."

With gratitude for your interest and support,

Cyrus Cisco
Prince of Gornja Siga
September 1st 2023

**/

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SigaLegislationDocuments is ERC721Enumerable, Ownable {
    // Events
    event MetadataBaseURIChanged(string newBaseURI);
    event DocumentMinted(uint256 tokenId, string description, string fileType, string IPFSCID);

    // Structure for storing document details
    struct Document {
        string description;
        string fileType;
        string IPFSCID;
    }

    Document[] public documents;
    string public metadataBaseURI = "https://siga.land/sld/"; 

    constructor() ERC721("Siga Legislation Document", "SLD") {}

    function setMetadataBaseURI(string memory newBaseURI) public onlyOwner {
        metadataBaseURI = newBaseURI;
        emit MetadataBaseURIChanged(newBaseURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(metadataBaseURI, uintToString(tokenId)));
    }

    function mintDocument(string memory description, string memory fileType, string memory IPFSCID) public onlyOwner {
        documents.push(Document(description, fileType, IPFSCID));
        uint256 newDocumentId = documents.length - 1;
        _mint(msg.sender, newDocumentId);
        emit DocumentMinted(newDocumentId, description, fileType, IPFSCID);
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}