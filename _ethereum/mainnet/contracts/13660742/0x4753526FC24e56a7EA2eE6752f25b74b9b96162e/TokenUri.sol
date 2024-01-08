// contracts/BaseballWords.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// import "./console.sol";
import "./base64.sol";
import "./structs.sol";

import "./Words.sol";
import "./BaseballWords.sol";

contract TokenUri {

    Words private _words;

    constructor(address wordsAddress) {
        _words = Words(wordsAddress);
    }

    function tokenURI(uint256 tokenId, uint256 projectId, uint256 tokenIndex, address baseballWordsAddress) public view returns (string memory) {

        require(BaseballWords(baseballWordsAddress).exists(tokenId) == true, "Invalid token");

        //Get the project name
        Project memory project = BaseballWords(baseballWordsAddress).getProject(projectId);

        //Get info about this token        
        string memory attributesJson = "";
        string memory queryString = "";

        //Get the attribute categories for this project        
        for (uint256 i=0; i < project.attributeCategoryIds.length; i++) {

            //Get the category id
            // uint256 categoryId = project.attributeCategoryIds[i];

            //Get the attribute id mapped to attributeCategory id + tokenId
            uint256 attributeId = BaseballWords(baseballWordsAddress).tokenAttribute(project.attributeCategoryIds[i], tokenId);

            //Build attributes json
            attributesJson = string(abi.encodePacked(attributesJson, '{"trait_type": "', _words.word(project.attributeCategoryIds[i]), '", "value": "', _words.word(attributeId), '"}'));

            //Build querystring
            queryString = string(abi.encodePacked(queryString, uint2str(project.attributeCategoryIds[i]), ',', uint2str(attributeId)));

            if (i != project.attributeCategoryIds.length - 1) {
                attributesJson = string(abi.encodePacked(attributesJson, ','));
                queryString = string(abi.encodePacked(queryString, ','));
            }

        }
        
        string memory url = string(abi.encodePacked('ipfs://', project.ipfs, '?t=', uint2str(tokenId), '&a=', queryString));
        
        return string(
            abi.encodePacked('data:application/json;base64,', Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{', 
                                '"name": "', project.name, ' #', uint2str(tokenIndex), '",', 
                                '"description": "', project.description, '",',
                                '"animation_url": "', url, '",',
                                '"image_data": "', BaseballWords(baseballWordsAddress).svg(tokenIndex, project.maxSupply), '",',    
                                '"attributes": [',
                                    '{"trait_type": "Project", "value": "', project.name, '"},',
                                    attributesJson,
                                ']',
                            '}')
                    )
                )
            ))
        );

    }

    function uint2str(uint _i) public pure returns (string memory _uintAsString) {
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










}