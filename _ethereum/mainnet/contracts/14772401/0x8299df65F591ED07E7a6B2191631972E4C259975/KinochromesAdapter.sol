// SPDX-License-Identifier: UNLICENSED
/// @title KinochromesAdapter
/// @notice Kinochromes Adapter
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
import "./IKinochromes.sol";
// import "./console.sol";

contract KinochromesAdapter is Ownable, DestroyLockable {
    IStringUtilsV3 public stringUtils;
    IKinochromes public kinochromes;
    address public kinochromesContract;
    string public name = "Kinochromes";

    constructor(address stringUtilsContract, address _kinochromesContract) {
        stringUtils = IStringUtilsV3(stringUtilsContract);
        kinochromes = IKinochromes(_kinochromesContract);
        kinochromesContract = _kinochromesContract;
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        string memory jsonBase64 = kinochromes.tokenURI(tokenId);
        string memory onlyBase64 = stringUtils.removePrefix(jsonBase64, "data:application/json;base64,");
        string memory json = string(stringUtils.base64Decode(bytes(onlyBase64)));
        string memory encodedBase64 = stringUtils.extractFromTo(json,'"image": "data:image/svg+xml;base64,','"');
        bytes memory decoded = stringUtils.base64Decode(bytes(encodedBase64));
        return string(decoded);
    }

    function getDataUriSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;utf8,", getSvg(tokenId)));
    }

    function getDataUriBase64(uint256 tokenId) public view returns (string memory) {
        string memory jsonBase64 = kinochromes.tokenURI(tokenId);
        string memory onlyBase64 = stringUtils.removePrefix(jsonBase64, "data:application/json;base64,");
        string memory json = string(stringUtils.base64Decode(bytes(onlyBase64)));
        return stringUtils.extractFromTo(json,'"image": "','"');
    }

    function getEmbeddableSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("<image x='0' y='0' width='640' height='640' style='opacity: 0.85;' href='", getDataUriBase64(tokenId), "'/>"));
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return kinochromes.ownerOf(tokenId);
    }

    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory) {
        string memory jsonBase64 = kinochromes.tokenURI(tokenId);
        string memory onlyBase64 = stringUtils.removePrefix(jsonBase64, "data:application/json;base64,");
        string memory json = string(stringUtils.base64Decode(bytes(onlyBase64)));
        return stringUtils.extractFromTo(json,'"attributes": ', ',"image": "data:image/svg+xml;base64,');
    }

}
