// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./IMintableBurnableERC721.sol";
import "./SafeOwnable.sol";
import "./Mintable.sol";
import "./Burnable.sol";
import "./NFTCore.sol";

contract ClassicNFT is SafeOwnable, NFTCore, Mintable, Burnable, IMintableBurnableERC721 {

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _uri
    ) NFTCore(_name, _symbol, _uri, type(uint256).max) Mintable(new address[](0), false) Burnable(new address[](0), false) {
    }

    function mint(address _to, uint _num) external override onlyMinter {
        mintInternal(_to, _num);
    }

    function burn(address _user, uint256 _tokenId) external override onlyBurner {
        burnInternal(_user, _tokenId);
    }
}
