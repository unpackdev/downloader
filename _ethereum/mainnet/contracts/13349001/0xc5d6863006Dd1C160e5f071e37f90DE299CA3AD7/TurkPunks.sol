// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IRenderer {
    function renderImage(
        uint256 _b,
        uint256 _e,
        uint256 _m,
        uint256 _h,
        uint256 _r
    ) external view returns (string memory);
}

contract TurkPunks is ERC721, ReentrancyGuard, Ownable {
    bool public started = false;
    uint256 public mintCount;
    uint256 public MAX_SUPPLY = 0;
    uint256 public MINT_PRICE = 0.03 ether;

    address rendererContract = address(0);
    address donationAddress =
        address(0x50D80101e43db03740ad27F2aD6bC919012dc1f9);

    string description = "*100% Punk*";
    string base_url = "";
    string image_format = ".png";

    string[] internal bodies = [
        "White Cartoon Head",
        "Beige Cartoon Head",
        "Standard Head",
        "Zombie Head",
        "Cartoon Head"
    ];
    string[] internal eyes = [
        "Green Eyes",
        "Melancholic Blue Eyes",
        "Green Thin Glasses",
        "Snake Eyes",
        "Red Glasses",
        "Purple Glasses",
        "Angry Black Eyes",
        "Yellow Bee Eyes",
        "Curious Blue Eyes",
        "Red Irregular Glasses",
        "Flaring Eyes",
        "Black Eyes",
        "Purple Cool Glasses",
        "Red Eyes"
    ];
    string[] internal mouths = [
        "Mop Specialist Mouth",
        "Orange Beard",
        "Blower Mouth",
        "Tongue Down",
        "Standard Mouth",
        "Horny Mouth",
        "Cool Beard",
        "Sad Mouth",
        "Tongue Left Down",
        "Demonic Beard",
        "Mouth With Lipstick",
        "Small Mouth With Mustache",
        "Cute Mouth",
        "Tricky Mouth"
    ];
    string[] internal hairs = [
        "Blonde Long Hair",
        "Brown Short Hair",
        "Black Shitty Hair",
        "Purple Hair",
        "Activist Berfo Hair",
        "Purple Messy Hair",
        "Blue Hat",
        "Purple Curly Hair",
        "Green Hair",
        "Brown Hair",
        "Red Hedgehog Hair",
        "Red Curly Hair",
        "Turquoise Hair",
        "Blonde Hedgehog Hair",
        "Red Long Hair",
        "Blue Hair",
        "Yellow Hair",
        "Blonde Short Hair"
    ];

    struct DNA {
        uint256 body;
        uint256 eye;
        uint256 mouth;
        uint256 hair;
        uint256 rarity;
        string rarityStr;
    }

    
    uint16[] internal dnaArray1;
    uint16[] internal dnaArray2;
    uint16[] internal dnaArray3;
    uint16[] internal dnaArray4;
    uint16[] internal dnaArray5;
    uint16[] internal dnaArray6;
    uint16[] internal dnaArray7;
    uint16[] internal dnaArray8;
    uint16[] internal dnaArray9;
    uint16[] internal dnaArray10;
    
    
    function getDna(uint256 dnaId) internal view returns(uint16) {
        
        if(dnaId < 1000) {
            return dnaArray1[dnaId];
        } 
        else if(dnaId < 2000) {
            return dnaArray2[dnaId - 1000];
        } 
        else if(dnaId < 3000) {
            return dnaArray3[dnaId - 2000];
        } 
        else if(dnaId < 4000) {
            return dnaArray4[dnaId - 3000];
        } 
        else if(dnaId < 5000) {
            return dnaArray5[dnaId - 4000];
        } 
        else if(dnaId < 6000) {
            return dnaArray6[dnaId - 5000];
        } 
        else if(dnaId < 7000) {
            return dnaArray7[dnaId - 6000];
        } 
        else if(dnaId < 8000) {
            return dnaArray8[dnaId - 7000];
        } 
        else if(dnaId < 9000) {
            return dnaArray9[dnaId - 8000];
        } 
        else {
            return dnaArray10[dnaId - 9000];
        } 
        
        
    }


    function encodeDna(
        uint256 body,
        uint256 eye,
        uint256 mouth,
        uint256 hair,
        uint256 rarity
    ) internal pure returns (uint16) {
        return
            uint16(
                body +
                    (eye * 5) +
                    (mouth * 5 * 14) +
                    (hair * 5 * 14 * 14) +
                    (rarity * 5 * 14 * 14 * 18)
            );
    }

    function decodeDna(uint16 _dna) internal pure returns (DNA memory) {
        uint256 rarity = _dna / (5 * 14 * 14 * 18);
        uint256 hair = (_dna % (5 * 14 * 14 * 18)) / (5 * 14 * 14);
        uint256 mouth = (_dna % (5 * 14 * 14)) / (5 * 14);
        uint256 eye = (_dna % (5 * 14)) / 5;
        uint256 body = (_dna % 5);
        string memory rarityStr;
        
        if (rarity == 0) {
            rarityStr = "Common";
        } else if (rarity == 1) {
            rarityStr = "Rare";
        } else if (rarity == 2) {
            rarityStr = "Very Rare";
        }
        
        return DNA(body, eye, mouth, hair, rarity, rarityStr);
    }

    function setRendererContract(address _address) external onlyOwner {
        rendererContract = _address;
    }

    function setDescription(string calldata _description) external onlyOwner {
        description = _description;
    }

    function setBaseUrl(string calldata _base_url) external onlyOwner {
        base_url = _base_url;
    }

    function setImageFormat(string calldata _image_format) external onlyOwner {
        image_format = _image_format;
    }

    function renderImage(
        uint256 _b,
        uint256 _e,
        uint256 _m,
        uint256 _h,
        uint256 _r
    ) internal view returns (string memory) {
        if (rendererContract == address(0)) {
            return
                string(
                    abi.encodePacked(
                        base_url,
                        toString(encodeDna(_b, _e, _m, _h, _r)),
                        image_format
                    )
                );
        } else {
            IRenderer renderer = IRenderer(rendererContract);
            return renderer.renderImage(_b, _e, _m, _h, _r);
        }
    }


    function getAttributes(DNA memory _dna) internal view returns(bytes memory) {
        
        return abi.encodePacked(
            '", "attributes": [{"trait_type": "Head", "value": "',
            bodies[_dna.body],
            '"}, {"trait_type": "Eyes", "value": "',
            eyes[_dna.eye],
            '"}, {"trait_type": "Hair", "value": "',
            hairs[_dna.hair],
            '"}, {"trait_type": "Mouth", "value": "',
            mouths[_dna.mouth],
            '"}, {"trait_type": "Rarity", "value": "',
            _dna.rarityStr
            );
        
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "uri query for nonexistent token");
        
        uint16 dna = getDna(tokenId);
        DNA memory _dna = decodeDna(dna);
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "#',
                                toString(tokenId),
                                '", "description": "',
                                description,
                                '"',
                                ', "image": "',
                                renderImage(
                                    _dna.body,
                                    _dna.eye,
                                    _dna.mouth,
                                    _dna.hair,
                                    _dna.rarity
                                ),
                                getAttributes(_dna),
                                '"} ]  }'
                            )
                        )
                    ),
                    "#"
                )
            );
    }

    function _mint(address _to) internal {
        require(mintCount < MAX_SUPPLY, "Sold Out!");
        _safeMint(_to, mintCount);
        mintCount++;
    }

    function devMint(address _to) public onlyOwner {
        _mint(_to);
    }

    function startWithPreMint(uint256 _amount) external onlyOwner {
        require(started == false);
        for (uint256 i; i < _amount; i++) {
            _mint(msg.sender);
        }
        started = true;
    }

    function mint(uint256 _amount) external payable nonReentrant {
        require(started == true, "not started");
        require(
            msg.value >= _amount * MINT_PRICE,
            "please send 0.03 ether to mint."
        );
        require(mintCount + _amount <= MAX_SUPPLY, "exceeds the max supply");
        withdrawToPayees(msg.value);
        for (uint256 i; i < _amount; i++) {
            _mint(msg.sender);
        }
    }
    
    function airdrop(address[] calldata _addresses ) public onlyOwner {
        for(uint256 i; i < _addresses.length; i++){
            address _address = _addresses[i];
            devMint(_address);
        }
    }

    function pushDnas1(uint16[] calldata _supply) external onlyOwner {
        dnaArray1 = _supply;
    }
    function pushDnas2(uint16[] calldata _supply) external onlyOwner {
        dnaArray2 = _supply;
    }
    function pushDnas3(uint16[] calldata _supply) external onlyOwner {
        dnaArray3 = _supply;
    }
    function pushDnas4(uint16[] calldata _supply) external onlyOwner {
        dnaArray4 = _supply;
    }
    function pushDnas5(uint16[] calldata _supply) external onlyOwner {
        dnaArray5 = _supply;
    }
    function pushDnas6(uint16[] calldata _supply) external onlyOwner {
        dnaArray6 = _supply;
    }
    function pushDnas7(uint16[] calldata _supply) external onlyOwner {
        dnaArray7 = _supply;
    }
    function pushDnas8(uint16[] calldata _supply) external onlyOwner {
        dnaArray8 = _supply;
    }
    function pushDnas9(uint16[] calldata _supply) external onlyOwner {
        dnaArray9 = _supply;
    }
    function pushDnas10(uint16[] calldata _supply) external onlyOwner {
        dnaArray10 = _supply;
    }
    
    function updateMaxSupply() external onlyOwner {
        MAX_SUPPLY = dnaArray1.length + 
        dnaArray2.length + 
        dnaArray3.length + 
        dnaArray4.length + 
        dnaArray5.length +
        dnaArray6.length +
        dnaArray7.length +
        dnaArray8.length +
        dnaArray9.length +
        dnaArray10.length;
    }

    constructor() ERC721("Turk Punks", "TP") onlyOwner {}

    function withdrawToPayees(uint256 _amount) internal {
        uint256 amount = _amount;

        payable(0x3B99E794378bD057F3AD7aEA9206fB6C01f3Ee60).transfer(
            (amount / 100) * 40
        );

        payable(0x575CBC1D88c266B18f1BB221C1a1a79A55A3d3BE).transfer(
            (amount / 100) * 40
        );

        payable(donationAddress).transfer((amount / 100) * 20);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
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

    // @title Base64
    // @author Brecht Devos - <brecht@loopring.org>
    // @notice Provides a function for encoding some bytes in base64
    function encode(bytes memory data) internal pure returns (string memory) {
        string
            memory TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
