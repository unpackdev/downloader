// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./DragonKnightLibrary.sol";

contract DragonKnight is Ownable, ERC721A {
    uint256 public maxSupply = 1000;
    uint256 public maxFreeMint = 2;
    uint256 public maxMint = 5;
    bool public paused = true;
    uint256 public cost = 0.005 ether;

    // Token trait layers and colors, uploaded post contract deployment
    string[][6] colors;
    string[][6] traits;

    // Stores legendary svg and metadata
    mapping(uint256 => string) internal legendarySvgs;
    mapping(uint256 => string) internal legendaryNames;
    mapping(uint256 => string) internal legendaryWeapons;

    bool legChain = false;
    uint numLegendaries = 13;
    uint256[13] legendaryIds;

    // Metadata layer names
    string[] types = ["Background", "Face", "Eyes", "Helmet Eyes", "Sword", "Armor"];

    // Hash storing unique layer string with tokenId
    mapping(uint256 => string) internal tokenIdToHash;

    // For checking minted per wallet
    mapping(address => uint256) internal userMints;
    mapping(address => uint256) internal userMintsPaid;

    constructor() ERC721A('chainknights.xyz', 'CKNIGHT') {
        // Legendary ids are randomized on contract creation
        loadLegendaryIds();
    }

    /** MINTING FUNCTIONS */

    function mint(address _to, uint256 _mintAmount) public payable {
        require(tx.origin == _msgSender(), "Only EOA");
        require(!paused, "Contract paused");
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount < maxSupply, "No enought mints left.");

        // ADD CHECK FOR 5 PER WALLET
        require(userMintsPaid[msg.sender] + _mintAmount <= maxMint, "Max mint exceeded!");
        require(msg.value >= cost * _mintAmount, "Not enough ETH.");
        
        userMintsPaid[msg.sender] += _mintAmount;
        _safeMint(_to, _mintAmount);
    }

    function mintFree(address _to, uint256 _mintAmount) public payable {
        require(tx.origin == _msgSender(), "Only EOA");
        require(!paused, "Contract paused");
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount < maxSupply, "No enought mints left.");

        // ADD CHECK FOR 2 FREE PER WALLET
        require(userMints[msg.sender] + _mintAmount <= maxFreeMint, "Max mint exceeded!");
        
        userMints[msg.sender] += _mintAmount;
        _safeMint(_to, _mintAmount);
    }

    /** TOKEN URI AND METADATA ON CHAIN FUNCTIONS */

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        // Checks if legendary
        for(uint256 i = 0; i < numLegendaries; i++) {
            if(legendaryIds[i] == _tokenId) {
                return formatTokenURI(legendarySvgs[_tokenId], _tokenId, true, i);
            }
        }

        return formatTokenURI(generateSVG(_tokenId), _tokenId, false, 0);
    }


    /**
     * @dev Converts tokenID to JSON metadata.
     * @param _tokenId The erc721 token id.
     * @param legendary A boolean whether or not token is legendary.
     */
    function tokenIdToMetadata(uint256 _tokenId, bool legendary)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        if(legendary == true) {
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    "Legendary Weapon",
                    '","value":"',
                    legendaryWeapons[_tokenId],
                    '"}'
                )
            );

            return string(abi.encodePacked("[", metadataString, "]"));
        }

        for (uint8 i = 0; i < 6; i++) {
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    types[i],
                    '","value":"',
                    traits[i][parseHash(i, _tokenId)],
                    '"}'
                )
            );

            if (i != 5)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Parses 6 digit tokenID hash into svg parts
     * @param _layerId The layer id 0-5.
     * @param _tokenId The erc721 token id.
     */
    function parseHash(uint256 _layerId, uint256 _tokenId) public view returns(uint256) {
        string memory layerNum = DragonKnightLibrary.substring(tokenIdToHash[_tokenId], _layerId, _layerId + 1);
        return DragonKnightLibrary.parseInt(layerNum);
    }

    /**
     * @dev Generates SVG string by pulling colors from hash
     * @param _tokenId The erc721 token id.
     */
    function generateSVG(uint256 _tokenId) public view returns(string memory){
        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" preserveAspectRatio="xMinYMin meet" viewBox="0 -0.5 64 64">';
        for(uint256 i = 0; i < 6; i++) {
            string memory color = colors[i][parseHash(i, _tokenId)];

            //Check if two colors
            if(bytes(color).length > 7){
                svg = string(abi.encodePacked(svg, DragonKnightLibrary.getLayer(i, DragonKnightLibrary.substring(color, 0, 7), DragonKnightLibrary.substring(color, 7, 14))));
            } else {
                svg = string(abi.encodePacked(svg, DragonKnightLibrary.getLayer(i, color, color)));
            }
        }
        
        svg = string(abi.encodePacked(svg, DragonKnightLibrary.getHelmetHornsTeethLayer(), '</svg>'));

        return svgToImageURI(svg);
    }

    /**
     * @dev Formats tokenURI, if it is a legendary id it will display legendary data.
     * @param imageURI The raw base64 encoded image data.
     * @param _tokenId The erc721 token id.
     * @param legendary A boolean whether or not token is legendary.
     */
    function formatTokenURI(string memory imageURI, uint256 _tokenId, bool legendary, uint legId) public view returns (string memory) {
        if(legendary == true){
            if(legChain == false) {
                // Temp set leg off chain to save gas on deployment, move post mint
                return string(abi.encodePacked('ipfs://QmQLRascKgw6hTuegm4pn1cwEyJfj391H15kVPPfwcHG3n/', DragonKnightLibrary.toString(legId), '.json'));
            }
            return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    DragonKnightLibrary.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                string(abi.encodePacked(legendaryNames[_tokenId], " #", DragonKnightLibrary.toString(_tokenId))), // You can add whatever name here
                                '", "description":"chainknights.xyz is a 100% unique collection of knights on chain. No ipfs, no server, just code.", "attributes":',tokenIdToMetadata(_tokenId, legendary),', "image":"',imageURI,'"}'
                            )
                        )
                    )
                )
            );
        }
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    DragonKnightLibrary.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                string(abi.encodePacked("chainknights.xyz #", DragonKnightLibrary.toString(_tokenId))), // You can add whatever name here
                                '", "description":"chainknights.xyz is a 100% unique collection of knights on chain. No ipfs, no server, just code.", "attributes":',tokenIdToMetadata(_tokenId, legendary),', "image":"',imageURI,'"}'
                            )
                        )
                    )
                )
            );
    }

    
    /**
     * @dev Converts svg string data to base64 encoded svg data.
     * @param svg String svg data.
     */
    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = DragonKnightLibrary.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    /** OWNER ONLY FUNCTIONS */

    /**
     * @dev Batch set hashes for tokens so minter does not have to pay gas
     * @param data The hash data stored as string array (6 digits each).
     * @param _len The length of array.
     */
    function setHashes(string[] memory data, uint _len) public onlyOwner{
        for(uint i = 0; i < _len; i++) {
            uint tokenId = i;
            tokenIdToHash[tokenId] = data[i];
        }
    }

    /**
     * @dev Loads legendary ids with hashing function on contract deployment.
     */
    function loadLegendaryIds() public onlyOwner {
        for(uint256 i = 0; i < numLegendaries; i++) {
            uint256 rndNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i, msg.sender))) % maxSupply;
            legendaryIds[i] = rndNumber;
        }
    }

    /**
     * @dev Returns all legendary ids.
     */
    function getLegendaryIds() public view onlyOwner returns (uint256[13] memory) {
        return legendaryIds;
    }

    /**
     * @dev Manually set legendary svgdata and metadata.
     * @param svgData The raw base64 encoded svg data.
     * @param name The name of the legendary.
     * @param weapon The name of the legendary weapon.
     * @param index The index in the legendarySvgs array.
     */
    function loadLegendary(string calldata svgData, string memory name, string memory weapon, uint index) public onlyOwner {
        legendarySvgs[legendaryIds[index]] = svgData;
        legendaryNames[legendaryIds[index]] = name;
        legendaryWeapons[legendaryIds[index]] = weapon;
    }

    /**
     * @dev Loads trait data post contract deployment.
     * @param index The index in the colors and traits array.
     * @param color An array of colors for the layer.
     * @param trait An array of names for the trait.
     */
    function loadTraits(uint256 index, string[] memory color, string[] memory trait) public onlyOwner(){
        colors[index] = color;
        traits[index] = trait;
    }
    
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setLegChain(bool _state) public onlyOwner {
        legChain = _state;
    }

    function setCost(uint256 _newCost) public onlyOwner() {
        cost = _newCost;
    }


    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}