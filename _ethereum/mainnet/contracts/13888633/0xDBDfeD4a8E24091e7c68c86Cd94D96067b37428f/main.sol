// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./ownable.sol";

contract Nebula41 is ERC1155Supply, Ownable{

    uint256 currentID = 0;
    uint256 constant supply = 9000;
    string baseURIx = "https://gen1-nft-api.nebula41.io/v1/nft/gen1/";
    string baseURIip = "ipfs://";
    uint256 constant whitelistSupply = 4000;
    bool public publicMint = false;

    constructor() public ERC1155("") {
    }

    function preMint(uint256[] calldata premintID, uint256[] calldata premintAmounts) public {
      _mintBatch(msg.sender,premintID, premintAmounts, "");
    }
    
    function name()
    external
    view
    returns (string memory) {
        return "Nebula 41";
    }

    function symbol()
    external
    view
    returns (string memory) {
        return "NEB";
    }

    function mint() public payable{
        require(currentID<supply, "Max Supply Reached");
        require(publicMint);
        require(msg.value >= 80000000000000000 wei, "Invalid ETH Amount");
        _mint(msg.sender,currentID,1,"");
        currentID+=1;
    }

    function whiteMint() public payable {
        require(!publicMint);
        require(currentID<whitelistSupply, "Max Supply Reached");
        require(msg.value >= 80000000000000000 wei, "Invalid ETH Amount");        
        _mint(msg.sender,currentID,1,"");
        currentID+=1;
    }

    function uri(uint256 _id) override public view returns (string memory) {
        return string(abi.encodePacked(
            baseURIx,
            Strings.toString(_id),
            ".json")
        );
    }

    function enablePublicMint() public onlyOwner {
      publicMint = true;
    }

    function extractEther() external onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
    }
}