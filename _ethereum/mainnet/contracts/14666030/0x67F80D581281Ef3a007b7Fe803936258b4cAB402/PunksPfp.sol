// SPDX-License-Identifier: UNLICENSED
/// @title PunksPfp
/// @notice Punks Pfp
/// @author CyberPnk <cyberpnk@punkspfp.cyberpnk.win>
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

contract PunksPfp is Ownable, DestroyLockable {
    IStringUtilsV2 public stringUtils;
    ICryptoPunksData public cryptoPunksData;
    ICryptoPunksMarket public cryptoPunksMarket;

    constructor(address stringUtilsContract, address cryptoPunksMarketContract, address cryptoPunksDataContract) {
        stringUtils = IStringUtilsV2(stringUtilsContract);
        cryptoPunksMarket = ICryptoPunksMarket(cryptoPunksMarketContract);
        cryptoPunksData = ICryptoPunksData(cryptoPunksDataContract);
    }

    function tokenURI(uint256 punkId) external view returns (string memory) {
        string memory strPunkId = stringUtils.numberToString(punkId);

        bytes memory imageBytes = bytes(cryptoPunksData.punkImageSvg(uint16(punkId)));
        string memory traitsBytes = cryptoPunksData.punkAttributes(uint16(punkId));

        string memory imageBytesNoHeader = stringUtils.substr(imageBytes, 24, imageBytes.length);

        string memory image = stringUtils.base64EncodeSvg(bytes(imageBytesNoHeader));

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

        bytes memory json = abi.encodePacked(
            '{'
                '"title": "Punk Pfp #', strPunkId, '",'
                '"name": "Punk Pfp #', strPunkId, '",'
                '"image": "', image, '",'
                '"traits": [ ',
                    traitsStr,
                '],'
                '"description": "Punk Pfp #', strPunkId,'.  Just a passthrough wrapper to LarvaLabs on-chain punks data contract to make it ERC721-like.  No afiliation."'
            '}'
        );

        return stringUtils.base64EncodeJson(json);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return cryptoPunksMarket.punkIndexToAddress(uint16(_tokenId));
    }

}
