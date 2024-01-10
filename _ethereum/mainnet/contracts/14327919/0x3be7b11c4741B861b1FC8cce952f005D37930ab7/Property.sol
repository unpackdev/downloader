// contracts/Property.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IPaper.sol";
import "./DebtCityLibrary.sol";

contract Property is ERC721Enumerable, Ownable {

    
/*

██████╗░██████╗░░█████╗░██████╗░███████╗██████╗░████████╗██╗░░░██╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗╚══██╔══╝╚██╗░██╔╝
██████╔╝██████╔╝██║░░██║██████╔╝█████╗░░██████╔╝░░░██║░░░░╚████╔╝░
██╔═══╝░██╔══██╗██║░░██║██╔═══╝░██╔══╝░░██╔══██╗░░░██║░░░░░╚██╔╝░░
██║░░░░░██║░░██║╚█████╔╝██║░░░░░███████╗██║░░██║░░░██║░░░░░░██║░░░
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░░░╚═╝░░░

*/


    using DebtCityLibrary for uint8;

    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal propIdToHash;
    bool isMintActive = false;

    uint256 MAX_SUPPLY = 10000;
    uint256 SEED_NONCE = 0;

    uint256 REMAINING_GOOD_HOTELS = 250;
    uint256 REMAINING_HOTELS = 250;
    uint256 REMAINING_GOOD_APARTMENTS = 1200;
    uint256 REMAINING_APARTMENTS = 1800;
    uint256 REMAINING_GOOD_HOUSES = 1950;
    uint256 REMAINING_HOUSES = 4550;

    struct PngTrait {
        string ttype;
        string name;
        string png;
        bool on;
    }

    mapping(uint8 => mapping(uint8 => PngTrait)) public traitData;
    
    uint8[] traitVals = [10,8,2,7,2,4,3,4,6,
                         10,4,2,4,4,4,6,6,3,
                         10,5,2,3,4,4,4,1,1];

    string[] LETTERS = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];

    address paperAddress;
    address debtCityAddress;
    address _owner;

    constructor() ERC721("Property", "PROPERTY") {
        _owner = msg.sender;
    }

    
    /** *********************************** **/
    /** ********* Minting Functions ******* **/
    /** *********************************** **/

    function hash(
        uint256 _t,
        address _a,
        uint256 _c,
        uint8 propType
    ) internal returns (string memory) {
        require(_c < 10);

        // This will generate an 11 character string
        // The last 10 digits are random, the first is 1-6 depending on the random
        // property style assigned to the token

        SEED_NONCE++;
        uint16 randValue = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _t,
                        _a,
                        _c,
                        SEED_NONCE
                    )
                )
            ) 
        );

        uint8 pstyle = getPropertyType(randValue, propType);
        string memory currentHash = pstyle.toString();

        uint8 adder = 0;
        uint8 numTraits = 9;

        if (propType == 2) adder = numTraits;
        else if (propType == 3) adder = numTraits * 2;

        for (uint8 i = 0; i < numTraits; i++) {
            SEED_NONCE++;
            uint8 numTraitVals = traitVals[i + adder];

            uint8 randVal = uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % numTraitVals
            );

            uint8 randDigit = applyPropRules(i, pstyle, randVal);

            currentHash = string(
                abi.encodePacked(currentHash, randDigit.toString())
            );
        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1, propType);

        return currentHash;
    }

    

    function mintInternal(uint8 propType) internal {
        require(isMintActive == true, "Minting new property is not currently enabled");
        uint256 _totalSupply = totalSupply();
        uint256 propsRemaining = getPropsRemaing();
        require(_totalSupply < MAX_SUPPLY && propsRemaining > 0);
        require(!DebtCityLibrary.isContract(msg.sender));

        uint256 thisPropId = _totalSupply;

        propIdToHash[thisPropId] = hash(thisPropId, msg.sender, 0, propType);

        hashToMinted[propIdToHash[thisPropId]] = true;

        _safeMint(msg.sender, thisPropId);
    }

    function mintProperty(uint8 propType) public {

        uint256 propPrice = getPropPrice(propType);

        // require this owner has enough PAPER to buy property type
        require(IERC20(paperAddress).balanceOf(msg.sender) > propPrice, "You must have enough DEBT to mint this property type");

        //Burn as much paper as the property costs
        IPaper(paperAddress).burnFrom(msg.sender, propPrice);

        return mintInternal(propType);
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // hardcode approval so that users don't have to waste gas approving
        if (_msgSender() != address(paperAddress)){
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(from, to, tokenId);
    }



    /** *********************************** **/
    /** ******* Internal Functions ******** **/
    /** *********************************** **/

    function getPropsRemaing() internal view returns (uint256) {
        return REMAINING_GOOD_HOTELS + REMAINING_HOTELS +
             REMAINING_GOOD_APARTMENTS + REMAINING_APARTMENTS + 
             REMAINING_GOOD_HOUSES + REMAINING_HOUSES;
    }


    function applyPropRules(uint8 i, uint8 propType, uint8 randDigit) pure internal returns (uint8) {
        // apply different rules and odds of getting 0 for specific property traits
        if ((i == 2) && (propType == 1 || propType == 3 || propType == 5)) randDigit = 0;
        if (i == 4 && (randDigit > 5 || propType == 2 || propType == 4)) randDigit = 0;
        if (i == 5 && (randDigit > 5 || propType == 1 || propType == 3 || propType == 6)) randDigit = 0;
        if (i == 6 && (randDigit > 5 || propType == 5)) randDigit = 0;
        if (i == 7 && (propType == 4 || (propType == 3 && randDigit > 5))) randDigit = 0;
        if (i == 8 && (propType == 3 || (randDigit > 5 && propType > 3))) randDigit = 0;

        return randDigit;
    }




    function getPropertyType(uint16 rando, uint8 propType) internal returns (uint8) {     

        uint16 randVal = (rando & 0xFFFF);

        if (propType == 1) {
            if (REMAINING_GOOD_HOUSES > 0 && (randVal % 4 == 0 || randVal % 15 == 0)) { // 30% chance of good house
                REMAINING_GOOD_HOUSES--;
                return 5;
            } else {
                REMAINING_HOUSES--;
                return 6;
            }
        }

        if (propType == 2) {
            if (REMAINING_GOOD_APARTMENTS > 0 && (randVal % 3 == 0 || randVal % 10 == 0) ) { // 40% chance of good apartment
                REMAINING_GOOD_APARTMENTS--;
                return 3;
            } else {
                REMAINING_APARTMENTS--;
                return 4;
            }
        }


        if (propType == 3) {
            if (REMAINING_GOOD_HOTELS > 0 && randVal % 2 == 0) { // 50% chance for good hotel
                REMAINING_GOOD_HOTELS--;
                return 1;
            } else {
                REMAINING_HOTELS--;
                return 2;
            }
        }

        return 0;
    }


    function getPropTitle(uint8 prop) internal pure returns (string memory) {
        if (prop == 6) return "house";
        if (prop == 5) return "good_house";
        else if (prop == 4) return "apartment";
        else if (prop == 3) return "good_apartment";
        else if (prop == 2) return "hotel";
        else if (prop == 1) return "good_hotel";
        return "none";
    } 

   

    /** *********************************** **/
    /** ********* Public Getters ********** **/
    /** *********************************** **/


    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {

        uint8 propType = DebtCityLibrary.parseInt(
            DebtCityLibrary.substring(_hash, 0, 1)
        );

        string memory metadataString = string(
            abi.encodePacked(
                '{"trait_type":"property_type","value":"',
                getPropTitle(propType), '"},'
            )
        );
        

        uint8 adder = 0;
        uint8 numTraits = 9;

        if (propType == 3 || propType == 4) adder = numTraits;
        else if (propType == 1 || propType == 2) {
            adder = numTraits * 2;
            numTraits = 6;
        }

        for (uint8 i = 0; i < numTraits; i++) {
            uint8 hashIndex = i + 1;
            uint8 thisTraitIndex = DebtCityLibrary.parseInt(
                DebtCityLibrary.substring(_hash, hashIndex, hashIndex + 1)
            );

            PngTrait memory t = traitData[i + adder][thisTraitIndex];
            if (t.on) {
                if (i != 0) metadataString = string(abi.encodePacked(metadataString, ","));

                metadataString = string(
                    abi.encodePacked(
                        metadataString,
                        '{"trait_type":"',
                        t.ttype,
                        '","value":"',
                        t.name,
                        '"}'
                    )
                );
            }

        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }


    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _propIdToHash(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    DebtCityLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "DebtCity #',
                                    DebtCityLibrary.toString(_tokenId),
                                    '", "description": "A unique property for DebtCity, the first on-chain economic simulator. No IPFS, no API. Just an Ethereum blockchain simulation of finance, investment, and degeneracy", "image": "data:image/svg+xml;base64,',
                                    DebtCityLibrary.encode(
                                        bytes(outputFullSVG(tokenHash))
                                    ),
                                    '","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }


    function _propIdToHash(uint256 _propId)
        public
        view
        returns (string memory)
    {
        return propIdToHash[_propId];
    }


    function getPayForProperty(uint256 _propId)
        public
        view
        returns (uint8)
    {
        string memory propHash = propIdToHash[_propId];
        
        uint8 propType = DebtCityLibrary.parseInt(
            DebtCityLibrary.substring(propHash, 0, 1)
        );

        if (propType == 1) return 7;
        if (propType == 2) return 5;
        if (propType == 3) return 3;
        if (propType == 4) return 2;
        if (propType == 5) return 2;

        return 1;
    }

    function getPayForType(uint8 propType) public pure returns (string memory) {
        if (propType == 1) return "1-2";
        if (propType == 2) return "2-3";
        if (propType == 3) return "5-7";

        return "";
    }

    function getPropPrice(uint8 propType) public view returns (uint256) {

        uint256 taxRate = 1;
        uint256 numLeft = getPropsRemaing();

        if (numLeft < 2500) taxRate = 8;
        else if (numLeft < 5000) taxRate = 4;
        else if (numLeft < 7500) taxRate = 2;

        if (propType == 1) return 25 * taxRate;
        if (propType == 2) return 50 * taxRate;
        if (propType == 3) return 100 * taxRate;

        revert();
    }



    function getPropInventory()
        public
        view
        returns (uint256[6] memory)
    {

        uint256[6] memory things = [REMAINING_GOOD_HOUSES, REMAINING_HOUSES, REMAINING_GOOD_APARTMENTS, REMAINING_APARTMENTS, REMAINING_GOOD_HOTELS, REMAINING_HOTELS];
        return things;
    }

    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 propCount = balanceOf(_wallet);

        uint256[] memory propIds = new uint256[](propCount);
        for (uint256 i; i < propCount; i++) {
            propIds[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return propIds;
    }






    /** *********************************** **/
    /** ********* Owner Functions ********* **/
    /** *********************************** **/


    function clearTraits() public onlyOwner {
        for (uint8 i = 0; i < 9; i++) {
            for (uint8 j = 0; j < 9; j++) { 
                delete traitData[i][i];
            }
        }
    }


    function outputFullSVG(string memory _hash) public view returns (string memory) {
       
        string memory svgString = "";

        uint8 propType = DebtCityLibrary.parseInt(
            DebtCityLibrary.substring(_hash, 0, 1)
        );

        uint8 adder = 0;
        uint8 numTraits = 9;

        if (propType == 3 || propType == 4) adder = numTraits;
        else if (propType == 1 || propType == 2) {
            adder = numTraits * 2;
            numTraits = 6;
        }

        for (uint8 i = 0; i < numTraits; i++) {

            uint8 hashIndex = i + 1;
            uint8 thisTraitIndex = DebtCityLibrary.parseInt(
                DebtCityLibrary.substring(_hash, hashIndex, hashIndex + 1)
            );
           
            PngTrait memory t = traitData[i + adder][thisTraitIndex];
            if (t.on) {
                svgString = string(abi.encodePacked(svgString, drawTrait(t)));
            }   
        }


        return string(abi.encodePacked(
          '<svg id="property" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          svgString,
          "</svg>"
        ));
    }


    function drawTrait(PngTrait memory trait) internal pure returns (string memory) {
        return string(abi.encodePacked(
          '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
          trait.png,
          '"/>'
        ));
    }


    function uploadTraits(uint8 traitType, PngTrait[] memory traits) public onlyOwner {
        for (uint8 i = 0; i < traits.length; i++) {
            traitData[traitType][i] = PngTrait(
                traits[i].ttype,
                traits[i].name,
                traits[i].png,
                traits[i].on
            );
        }
    }


    function setPaperAddresses(address _debtCityAddress, address _paperAddress) public onlyOwner {
        debtCityAddress = _debtCityAddress;
        paperAddress = _paperAddress;
        return;
    }


    function flipMintMode() public onlyOwner {
        isMintActive = !isMintActive;
    }


}
