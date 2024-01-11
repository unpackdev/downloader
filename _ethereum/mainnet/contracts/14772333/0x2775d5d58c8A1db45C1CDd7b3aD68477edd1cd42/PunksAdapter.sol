// SPDX-License-Identifier: UNLICENSED
/// @title PunksAdapter
/// @notice Punks Adapter
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
import "./ICryptoPunksData.sol";
import "./ICryptoPunksMarket.sol";
// import "./console.sol";

contract PunksAdapter is Ownable, DestroyLockable {
    IStringUtilsV2 public stringUtils;
    ICryptoPunksData public cryptoPunksData;
    ICryptoPunksMarket public cryptoPunksMarket;
    address public cryptoPunksDataContract;
    address public cryptoPunksMarketContract;
    string public name = "Punks";

    constructor(address stringUtilsContract, address _cryptoPunksDataContract, address _cryptoPunksMarketContract) {
        stringUtils = IStringUtilsV2(stringUtilsContract);
        cryptoPunksData = ICryptoPunksData(_cryptoPunksDataContract);
        cryptoPunksMarket = ICryptoPunksMarket(_cryptoPunksMarketContract);
        cryptoPunksDataContract = _cryptoPunksDataContract;
        cryptoPunksMarketContract = _cryptoPunksMarketContract;
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        bytes memory imageBytes = bytes(cryptoPunksData.punkImageSvg(uint16(tokenId)));
        return stringUtils.substr(imageBytes, 24, imageBytes.length);
    }

    function getDataUriSvg(uint256 tokenId) external view returns (string memory) {
        return cryptoPunksData.punkImageSvg(uint16(tokenId));
    }

    function getDataUriBase64(uint256 tokenId) external view returns (string memory) {
        return stringUtils.base64EncodeSvg(bytes(getSvg(tokenId)));
    }

    function getEmbeddableSvg(uint256 tokenId) external view returns (string memory) {
        return getSvg(tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return cryptoPunksMarket.punkIndexToAddress(uint16(tokenId));
    }

    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory) {
        string memory traitsBytes = cryptoPunksData.punkAttributes(uint16(tokenId));

        string[] memory traits = stringUtils.split(traitsBytes, ",");
        bytes memory traitsStr = "";
        uint len = traits.length;
        for (uint i = 0; i < len; i++) {
            bytes memory trait = bytes(traits[i]);
             string memory traitToUse = i == 0 ? string(trait) : stringUtils.substr(trait, 1, trait.length);
            traitsStr = abi.encodePacked(traitsStr, 
                '{'
                    '"trait_type":"', traitToUse, '",'
                    '"value":"', traitToUse, '"'
                '}', 
                i == len - 1 ? '' : ','
            );
        }

        return string(abi.encodePacked('[', traitsStr, ']'));
    }

}
