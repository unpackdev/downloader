// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

/// @title BLONKS URI Contract
/// @author Matto
/// @notice This contract does the heavy lifting in creating the token metadata and image.
/// @dev The extra functions to retrieve/preview the SVG and return legible URI made main contract too large.
/// @custom:security-contact monkmatto@protonmail.com
interface iBLONKStraits {
	function calculateTraitsArray(uint256 _tokenEntropy)
		external
		view
		returns (uint8[11] memory);

  function calculateTraitsJSON(uint8[11] memory _traitsArray)
  	external
		view
		returns (string memory);
}

interface iBLONKSlocations {
	function calculateLocatsArray(uint256 _ownerEntropy, uint256 _tokenEntropy, uint8[11] memory _traitsArray)
		external
		view
		returns (uint16[110] memory);
}

interface iBLONKSsvg {
	function assembleSVG(uint256 _ownerEntropy, uint256 _tokenEntropy, uint8[11] memory _traitsArray, uint16[110] memory _locatsArray)
		external
		view
		returns (string memory);
}

contract BLONKSuri is Ownable {
  using Counters for Counters.Counter;
  using Strings for string;

  address public traitsContract;
  address public locationsContract;
  address public svgContract;
  bool public cruncherContractsLocked = false;

  function buildMetaPart(uint256 _tokenId, string memory _description, address _artistAddy, uint256 _royaltyBps, string memory _collection, string memory _website, string memory _externalURL)
    external
    view
    virtual
    returns (string memory)
  {
    string memory metaP = string(abi.encodePacked('{"name":"BLONK #',Strings.toString(_tokenId),'","artist":"Matto","description":"',
    _description,'","royaltyInfo":{"artistAddress":"',Strings.toHexString(uint160(_artistAddy), 20),'","royaltyFeeByID":',Strings.toString(_royaltyBps/100),'},"collection_name":"',
    _collection,'","website":"',_website,'","external_url":"',_externalURL,'","script_type":"Solidity","image_type":"Generative SVG","image":"data:image/svg+xml;base64,'));
    return metaP;
  }

  function buildContractURI(string memory _description, string memory _externalURL, uint256 _royaltyBps, address _artistAddy, string memory _svg)
    external
    view
    virtual
    returns (string memory)
  {
    string memory b64svg = Base64.encode(bytes(_svg)); 
    string memory contractURI = string(abi.encodePacked('{"name":"BLONKS","description":"',_description,'","image":"data:image/svg+xml;base64,',b64svg,
    '","external_link":"',_externalURL,'","seller_fee_basis_points":',Strings.toString(_royaltyBps),',"fee_recipient":"',Strings.toHexString(uint160(_artistAddy), 20),'"}'));
    return contractURI;
  }

  function getLegibleTokenURI(string memory _metaP, uint256 _tokenEntropy, uint256 _ownerEntropy)
    external
    view
    virtual
    returns (string memory)
  {
    uint8[11] memory traitsArray = iBLONKStraits(traitsContract).calculateTraitsArray(_tokenEntropy);
    _tokenEntropy /= 10 ** 18;
    string memory traitsJSON = iBLONKStraits(traitsContract).calculateTraitsJSON(traitsArray);
    uint16[110] memory locatsArray = iBLONKSlocations(locationsContract).calculateLocatsArray(_ownerEntropy, _tokenEntropy, traitsArray);
    _ownerEntropy /= 10 ** 29;
    _tokenEntropy /= 10 ** 15;
    string memory svg = iBLONKSsvg(svgContract).assembleSVG(_ownerEntropy, _tokenEntropy, traitsArray, locatsArray);
    string memory legibleURI = string(abi.encodePacked(_metaP,Base64.encode(bytes(svg)),'",',traitsJSON,'}'));
    return legibleURI;
  }  

  function buildPreviewSVG(uint256 _tokenEntropy, uint256 _addressEntropy)
    external
    view
    virtual
    returns (string memory)
  {
    uint8[11] memory traitsArray = iBLONKStraits(traitsContract).calculateTraitsArray(_tokenEntropy);
    _tokenEntropy /= 10 ** 18;
    uint16[110] memory locatsArray = iBLONKSlocations(locationsContract).calculateLocatsArray(_addressEntropy, _tokenEntropy, traitsArray);
    _addressEntropy /= 10 ** 29;
    _tokenEntropy /= 10 ** 15;
    string memory resultSVG = iBLONKSsvg(svgContract).assembleSVG(_addressEntropy, _tokenEntropy, traitsArray, locatsArray);
    return resultSVG;
  }

  function getBase64TokenURI(string memory _legibleURI)
    external
    view
    virtual
    returns (string memory)
  {
    string memory URIBase64 = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(_legibleURI))));
    return URIBase64;
  }

  function updateSVGContract(address _svgContract)
		external 
		onlyOwner 
	{
    require(cruncherContractsLocked == false, "Contracts locked");
    svgContract = _svgContract;
  }

	function updateTraitsContract(address _traitsContract)
		external 
		onlyOwner 
	{
    require(cruncherContractsLocked == false, "Contracts locked");
    traitsContract = _traitsContract;
  }

	function updateLocationsContract(address _locationsContract)
		external 
		onlyOwner 
	{
    require(cruncherContractsLocked == false, "Contracts locked");
    locationsContract = _locationsContract;
  }

  function DANGER_LockCruncherContracts()
    external
    payable
    onlyOwner
  {
    cruncherContractsLocked = true;
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}