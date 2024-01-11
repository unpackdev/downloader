// SPDX-License-Identifier: UNLICENSED
/// @title PonziRugsAdapter
/// @notice PonziRugs Adapter
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
import "./IPonziRugs.sol";
// import "./console.sol";

contract PonziRugsAdapter is Ownable, DestroyLockable {
    IStringUtilsV3 public stringUtils;
    IPonziRugs public ponziRugs;
    address public ponziRugsContract;
    string public name = "PonziRugs";

    constructor(address stringUtilsContract, address _ponziRugsContract) {
        stringUtils = IStringUtilsV3(stringUtilsContract);
        ponziRugs = IPonziRugs(_ponziRugsContract);
        ponziRugsContract = _ponziRugsContract;
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        string memory jsonBase64 = ponziRugs.tokenURI(tokenId);
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
        string memory jsonBase64 = ponziRugs.tokenURI(tokenId);
        string memory onlyBase64 = stringUtils.removePrefix(jsonBase64, "data:application/json;base64,");
        string memory json = string(stringUtils.base64Decode(bytes(onlyBase64)));
        return stringUtils.extractFromTo(json,'"image": "','"');
    }

    function getEmbeddableSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("<image x='-425' y='-20' height='680' style='opacity: 0.85;' href='", getDataUriBase64(tokenId), "'/>"));
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return ponziRugs.ownerOf(tokenId);
    }

    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory) {
        string memory jsonBase64 = ponziRugs.tokenURI(tokenId);
        string memory onlyBase64 = stringUtils.removePrefix(jsonBase64, "data:application/json;base64,");
        string memory json = string(stringUtils.base64Decode(bytes(onlyBase64)));
        string memory extractedFrom = stringUtils.extractFrom(json,'"attributes": ');
        return stringUtils.removeSuffix(extractedFrom, "}");

    }

}
