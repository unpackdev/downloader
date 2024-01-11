// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

//      _   __         ______               ______                   
//     / | / /___     / ____/_  ______     /_  __/__  ____ _____ ___ 
//    /  |/ / __ \   / /_  / / / / __ \     / / / _ \/ __ `/ __ `__ \
//   / /|  / /_/ /  / __/ / /_/ / / / /    / / /  __/ /_/ / / / / / /
//  /_/ |_/\____/  /_/    \__,_/_/ /_/    /_/  \___/\__,_/_/ /_/ /_/ 
//                                                                 
//

import "./ERC721A.sol";
import "./Ownable.sol";

contract SiouxFallsFoundersPass is ERC721A, Ownable {

    uint256 public MAX_SUPPLY = 125;
    uint256 MAXPLUSONE = 126;

    string public baseURI = "ipfs://QmTciLN6AitCa5iDopdr1dqCZxnWzXHVncJUkMUPCaTAfr?tokenID=";

    constructor() ERC721A("SiouxFallsFoundersPass", "SFFP") {}

    function mint(address[] calldata addresses, uint8 quantity) external onlyOwner
    {
        require(totalSupply() + (addresses.length * quantity) < MAXPLUSONE, "Exceeds max supply");
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], quantity);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}