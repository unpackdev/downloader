// SPDX-License-Identifier: UNLICENSED
/// @title TerraformsAdapter
/// @notice Terraforms Adapter
/// @author CyberPnk <cyberpnk@pfpbg.cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.13;

import "./IStringUtilsV3.sol";
import "./DestroyLockable.sol";
import "./Ownable.sol";
import "./ITerraforms.sol";
// import "./console.sol";

contract TerraformsAdapter is Ownable, DestroyLockable {
    IStringUtilsV3 public stringUtils;
    ITerraforms public terraforms;
    address public terraformsContract;
    string public name = "Terraforms";

    constructor(address stringUtilsContract, address _terraformsContract) {
        stringUtils = IStringUtilsV3(stringUtilsContract);
        terraforms = ITerraforms(_terraformsContract);
        terraformsContract = _terraformsContract;
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        return terraforms.tokenSVG(tokenId);
    }

    function getDataUriSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;utf8,", terraforms.tokenSVG(tokenId)));
    }

    function getDataUriBase64(uint256 tokenId) public view returns (string memory) {
        return stringUtils.base64EncodeSvg(bytes(terraforms.tokenSVG(tokenId)));
    }

    function getEmbeddableSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("<image x='-30' y='-155' width='700' style='opacity: 0.85;' href='", getDataUriBase64(tokenId), "'/>"));
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return terraforms.ownerOf(tokenId);
    }

    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory) {
        string memory jsonBase64 = terraforms.tokenURI(tokenId);
        string memory onlyBase64 = stringUtils.removePrefix(jsonBase64, "data:application/json;base64,");
        string memory json = string(stringUtils.base64Decode(bytes(onlyBase64)));
        return stringUtils.extractFromTo(json,'"attributes": ', ', "image": "data:image/svg+xml;base64,');
    }

}
