// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract NftWhitelist is ERC721, Ownable {
    uint public nftCounter;

    event minted(address indexed to, uint id);
    mapping(address=>bool) public hasMinted;

    constructor () ERC721 ("Mines of Dalarnia Mining Apes Collection", "TMOD") Ownable(){
        nftCounter = 0;
    }

    function verifySignature(uint8 _v, bytes32 _r, bytes32 _s) internal view returns (bool){
        bytes memory prefix = "\x19Ethereum Signed Message:\n20";

        bytes32 msgh = keccak256(abi.encodePacked(prefix, msg.sender));
        return ecrecover(msgh, _v, _r, _s) == owner();
    }

    function mint(uint8 _v, bytes32 _r, bytes32 _s) public payable {
        require(verifySignature(_v, _r, _s), "Invalid whitelist signature");
        require(msg.value == 60000000000000000, "Wrong ETH amount.");
        require(nftCounter < 10000, "Nft cap reached.");
        require(!hasMinted[msg.sender], "Address has already minted one nft.");
       
        uint idToMint = nftCounter;
        nftCounter = nftCounter + 1;
        hasMinted[msg.sender] = true;

        payable(owner()).transfer(msg.value);

        _safeMint(msg.sender, idToMint);
        emit minted(msg.sender, idToMint);
    }

    function ownerMint(uint _nrToMint) public onlyOwner(){
        require((nftCounter+_nrToMint) <= 10000, "Nft cap overflow.");

        uint256 target = nftCounter + _nrToMint;

        for (uint256 i = nftCounter; i < target; i++){
            nftCounter = nftCounter + 1;
            _safeMint(owner(), i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://api.minesofdalarnia.com/nft/avatar/";
    }
}