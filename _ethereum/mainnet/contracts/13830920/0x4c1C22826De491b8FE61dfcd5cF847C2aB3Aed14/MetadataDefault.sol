// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Handles metadata requests from token contracts
import "./I_MetadataHandler.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./Ownable.sol";

//base contract to just display placeholder hidden information
contract MetadataDefault is I_MetadataHandler, Ownable {

    using Strings for uint256;

    string public imageData; //base64 encoded image
    string public description;
    string public namePrefix;

    constructor(string memory _image, string memory _description, string memory _prefix) {
        imageData = _image;
        description = _description;
        namePrefix = _prefix;
    }

    function tokenURI(uint256 tokenID) external override view returns (string memory)
    {
        string memory json = string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(        //todo is this double conversion back and forth?
                    string(abi.encodePacked(
                        '{"name": "',namePrefix,
                            tokenID.toString(),
                        '","description": "',
                            description,
                        '","image": "', //data:image/png;base64,', 
                            imageData,
                        '", "attributes":',
                        '[{"trait_type":"Status","value":"Hidden"}]',
                        '}'
                        ))
                )
            )
        ));

        return json;
    }

    function setImageString(string memory _newImage) external onlyOwner {
        imageData = _newImage;
    }

    function setPrefix(string memory _prefix) external onlyOwner {
        namePrefix = _prefix;
    }

    function setDescription(string memory _description) external onlyOwner {
        description = _description;
    }

}