// SPDX-License-Identifier: Some
pragma solidity ^0.8.6;

import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./ECDSA.sol";


contract FreeMintNFT is ERC721URIStorage{

    address public forEth;
    address public server;
    address public owner;

    uint public totalMinted;
    uint public totalSupply;
    
    string public link;
    
    mapping(address => bool) mintedPerPerson;


    constructor() ERC721("Ink Cell", "SWL"){
    
    	totalMinted = 0;
    	totalSupply = 2222;
    	
    	link = "https://mint.swallow.digital/free_mint/metadata/";
    	
    	forEth = 0x1387007002958FCc61E3fF93CdA47eE70121D921;
    	server = 0x40c0B3f63459c4301338DFCf7899a0Ec93481f02;
        owner = msg.sender;
    
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return link;
    }



    function specialMinting(bytes memory sig) payable public returns(bool){

        require(totalMinted < totalSupply, "All minted");
        require(!mintedPerPerson[msg.sender], "One per person");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, msg.value));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address receivedAddress = ECDSA.recover(message, sig);

        require(server == receivedAddress, "Wrong signature");

        totalMinted += 1;
        mintedPerPerson[msg.sender] = true;

        _safeMint(msg.sender, totalMinted);

        if(msg.value > 0){
            payable(forEth).transfer(msg.value);
        }

        return true;

    }


}
