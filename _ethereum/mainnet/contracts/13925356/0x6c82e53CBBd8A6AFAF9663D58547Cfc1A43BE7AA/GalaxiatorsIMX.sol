// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

import "./Mintable.sol";

contract Galaxiators is ERC721, Ownable, Mintable {

    string currentBaseURI;

    // In case we'll want to add burning functionality in the future
    address burningContract;

    constructor(address _imxAddress) 
        ERC721("Galaxiators", "GLX")
        Mintable(msg.sender, _imxAddress) {
            burningContract = address(0);
        }

    // Allows IMX to mint when a token is withdrawn back to L1
    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    // In case of contract changes
    function setIMX(address _imxAddress) external onlyOwner{
         imx = _imxAddress;
    }

    // Just in case ¯\_(ツ)_/¯
    function withdraw(address payable _address) external onlyOwner {
        require(payable(_address).send(address(this).balance));
    }

    // Standard override for baseURI for L1 
    function setBaseURI(string memory baseURI) public onlyOwner {
        currentBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return currentBaseURI;
    }

    // Burning is initially disabled, if we'll want to support it in the future
    // we can use a proxy contract.
    function setBurningContractAddress(address _burningContract) external onlyOwner {
        burningContract = _burningContract;
    } 

    function burnToken(uint tokenId) public {
        require(msg.sender == burningContract, "This function can only be called a by a certain address!");
        _burn(tokenId);
    }
}