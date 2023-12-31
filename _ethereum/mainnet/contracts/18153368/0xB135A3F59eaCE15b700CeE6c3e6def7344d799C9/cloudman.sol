// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC1155SupplyWithAll.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";



contract cloudman is ERC1155SupplyWithAll, Ownable {

    uint256 constant SleepyPinkDragon = 1;
    uint256 constant ThickCloud = 2;
    uint256 constant BlackHairPelicanCloud = 3;
    uint256 constant Superhuman = 4;
    uint256 constant Rattle = 5;

    mapping (uint256 => string) private _uris;

    constructor() ERC1155("https://arweave.net/jY8AYf7qhatESwV1h_oAU_v1r9unPvj3Kjozxya6zng/cloudart.json")

    {

     _mint(msg.sender, SleepyPinkDragon, 8, "");
     _mint(msg.sender, ThickCloud, 8, "");
     _mint(msg.sender, BlackHairPelicanCloud, 4, "");
     _mint(msg.sender, Superhuman, 4, "");
     _mint(msg.sender, Rattle, 4, "");
    }

function contractURI() public pure returns (string memory) {
        return "https://arweave.net/jY8AYf7qhatESwV1h_oAU_v1r9unPvj3Kjozxya6zng/cloudart.json";
    }

   
function uri(uint256 _tokenId) override public pure returns (string memory){
        return           string(abi.encodePacked("https://arweave.net/jY8AYf7qhatESwV1h_oAU_v1r9unPvj3Kjozxya6zng/cloudart", Strings.toString(_tokenId),".json"));
    }

    
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155SupplyWithAll)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}