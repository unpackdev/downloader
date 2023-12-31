//
//
//
////////////////////////////////////////////////////////////////////////////////////////
// __________        .__                        ___ ___                     .__       //
// \______   \_____  |__| ____   ___________   /   |   \  ____  ______ ____ |  |__    //
//  |       _/\__  \ |  |/    \_/ __ \_  __ \ /    ~    \/  _ \/  ___// ___\|  |  \   //
//  |    |   \ / __ \|  |   |  \  ___/|  | \/ \    Y    (  <_> )___ \\  \___|   Y  \  //
//  |____|_  /(____  /__|___|  /\___  >__|     \___|_  / \____/____  >\___  >___|  /  //
//         \/      \/        \/     \/               \/            \/     \/     \/   //
////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ERC1155PresetMinterPauser.sol";
import "./ERC2981.sol";

contract IconsOfNFT is ERC1155PresetMinterPauser, Ownable, ERC2981 {

    string public name = "iCONSofNFT";
    string public symbol = "ioNFT";

    address receiver = 0x2b8352941fAc4D384A81a782536c0fdf847e459b;
    uint96 feeNumerator = 1000;

    string public contractUri = "https://metadata.rainerhosch.com/iconsofnft/contract.json"; 


    constructor() ERC1155PresetMinterPauser("https://metadata.rainerhosch.com/iconsofnft/{id}") {
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