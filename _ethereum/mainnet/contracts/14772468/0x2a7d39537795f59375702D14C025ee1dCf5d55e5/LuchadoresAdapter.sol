// SPDX-License-Identifier: UNLICENSED
/// @title LuchadoresAdapter
/// @notice Luchadores Adapter
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
import "./ILuchadores.sol";
// import "./console.sol";

contract LuchadoresAdapter is Ownable, DestroyLockable {
    IStringUtilsV3 public stringUtils;
    ILuchadores public luchadores;
    address public luchadoresContract;
    string public name = "Luchadores";

    constructor(address stringUtilsContract, address _luchadoresContract) {
        stringUtils = IStringUtilsV3(stringUtilsContract);
        luchadores = ILuchadores(_luchadoresContract);
        luchadoresContract = _luchadoresContract;
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        return luchadores.imageData(tokenId);
    }

    function getDataUriSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;utf8,", getSvg(tokenId)));
    }

    function getDataUriBase64(uint256 tokenId) external view returns (string memory) {
        return stringUtils.base64EncodeSvg(bytes(getSvg(tokenId)));
    }

    function getEmbeddableSvg(uint256 tokenId) external view returns (string memory) {
        return getSvg(tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return luchadores.ownerOf(tokenId);
    }

    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory) {
        string memory extractedFrom = stringUtils.extractFrom(luchadores.metadata(tokenId),'"attributes": ');
        return stringUtils.removeSuffix(extractedFrom, "}");
    }

}
