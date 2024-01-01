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

contract FoFExclusive is ERC1155PresetMinterPauser, Ownable, ERC2981 {

    string public name = "FoFExclusive";
    string public symbol = "FoFEx";

    address receiver = 0x841494e9b8e71D06547Ba89989a8a9f52F71205C;
    uint96 feeNumerator = 1000;

    string public contractUri = "https://metadata.mikehager.de/mikehagerexclusive/contract";

    constructor() ERC1155PresetMinterPauser("https://metadata.mikehager.de/mikehagerexclusive/{id}") {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,
        uint256[] memory amount
    ) public onlyOwner {
        require(
            to.length == id.length && to.length == amount.length,
            "Length mismatch"
        );
        for (uint256 i = 0; i < to.length; i++)
            _mint(to[i], id[i], amount[i], "");
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