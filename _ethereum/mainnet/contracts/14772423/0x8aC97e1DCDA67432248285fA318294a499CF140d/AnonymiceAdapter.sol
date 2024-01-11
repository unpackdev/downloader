// SPDX-License-Identifier: UNLICENSED
/// @title AnonymiceAdapter
/// @notice Anonymice Adapter
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

import "./IStringUtilsV2.sol";
import "./DestroyLockable.sol";
import "./Ownable.sol";
import "./IAnonymice.sol";
// import "./console.sol";

contract AnonymiceAdapter is Ownable, DestroyLockable {
    IStringUtilsV2 public stringUtils;
    IAnonymice public anonymice;
    address public anonymiceContract;
    string public name = "Anonymice";

    constructor(address stringUtilsContract, address _anonymiceContract) {
        stringUtils = IStringUtilsV2(stringUtilsContract);
        anonymice = IAnonymice(_anonymiceContract);
        anonymiceContract = _anonymiceContract;
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        return anonymice.hashToSVG(anonymice._tokenIdToHash(tokenId));
    }

    function getDataUriSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;utf8,", getSvg(tokenId)));
    }

    function getDataUriBase64(uint256 tokenId) public view returns (string memory) {
        return stringUtils.base64EncodeSvg(bytes(getSvg(tokenId)));
    }

    function getEmbeddableSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("<image x='0' y='0' height='640' href='", getDataUriBase64(tokenId), "'/>"));
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return anonymice.ownerOf(tokenId);
    }

    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory) {
        return anonymice.hashToMetadata(anonymice._tokenIdToHash(tokenId));
    }

}
