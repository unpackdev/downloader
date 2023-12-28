//
//
//
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  ██████  ███████ ████████ ██████  ███████ ███████ ██      ██████  ██████   //
// ██       ██         ██    ██   ██ ██      ██      ██           ██      ██  //
// ██   ███ █████      ██    ██████  █████   █████   ██       █████   █████   //
// ██    ██ ██         ██    ██   ██ ██      ██      ██           ██      ██  //
//  ██████  ███████    ██    ██   ██ ███████ ███████ ███████ ██████  ██████   //
//                                                                            //                                                                      
////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ERC1155PresetMinterPauser.sol";
import "./ERC2981.sol";

contract JIGGIES33 is ERC1155PresetMinterPauser, Ownable, ERC2981 {

    string public name = "JIGGIES33";
    string public symbol = "J33";

    address receiver = 0x46bb5F8B393e3711C083269B3281be5aB2Ec0b6B;
    uint96 feeNumerator = 1000;

    string public contractUri = "https://metadata.getreel33.com/jiggies/contract";

    constructor() ERC1155PresetMinterPauser("https://metadata.getreel33.com/jiggies/{id}") {
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