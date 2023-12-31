//
//
//
///////////////////////////////////////////////////
//   __  __ _ _         _  _                     //
//  |  \/  (_) |_____  | || |__ _ __ _ ___ _ _   //
//  | |\/| | | / / -_) | __ / _` / _` / -_) '_|  //
//  |_|  |_|_|_\_\___| |_||_\__,_\__, \___|_|    //
//                               |___/           //
///////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ERC1155PresetMinterPauser.sol";
import "./ERC2981.sol";

contract NFTDasMagazine20243 is ERC1155PresetMinterPauser, Ownable, ERC2981 {

    string public name = "NFTDasMagazineByMikeHager20243";
    string public symbol = "NFTDME20243";

    address receiver = 0x841494e9b8e71D06547Ba89989a8a9f52F71205C;
    uint96 feeNumerator = 1000;

    string public contractUri = "https://metadata.mikehager.de/20243enContract.json";

    constructor() ERC1155PresetMinterPauser("https://metadata.mikehager.de/20243en.json") {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PresetMinterPauser, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}