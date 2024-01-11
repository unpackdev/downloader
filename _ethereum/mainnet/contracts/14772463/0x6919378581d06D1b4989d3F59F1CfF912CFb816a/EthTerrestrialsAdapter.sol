// SPDX-License-Identifier: UNLICENSED
/// @title EthTerrestrialsAdapter
/// @notice EthTerrestrials Adapter
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
import "./IEthTerrestrials.sol";
// import "./console.sol";

contract EthTerrestrialsAdapter is Ownable, DestroyLockable {
    IStringUtilsV3 public stringUtils;
    IEthTerrestrials public ethTerrestrials;
    address public ethTerrestrialsContract;
    string public name = "EthTerrestrials";

    constructor(address stringUtilsContract, address _ethTerrestrialsContract) {
        stringUtils = IStringUtilsV3(stringUtilsContract);
        ethTerrestrials = IEthTerrestrials(_ethTerrestrialsContract);
        ethTerrestrialsContract = _ethTerrestrialsContract;
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        return ethTerrestrials.tokenSVG(tokenId, false);
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
        return ethTerrestrials.ownerOf(tokenId);
    }

    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory) {
        string memory jsonBase64 = ethTerrestrials.tokenURI(tokenId);
        string memory onlyBase64 = stringUtils.removePrefix(jsonBase64, "data:application/json;base64,");
        string memory json = string(stringUtils.base64Decode(bytes(onlyBase64)));
        return stringUtils.extractFromTo(json,'"attributes":', ',"image": "data:image/svg+xml;base64,');
    }

}
