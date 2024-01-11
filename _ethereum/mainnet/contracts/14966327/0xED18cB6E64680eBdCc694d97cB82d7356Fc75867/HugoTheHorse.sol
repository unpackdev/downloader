//                                   .-.                         
//                                  /    \                       
//      .--.     .--.     .--.      | .`. ;    .--.    ___  ___  
//     /    \   /    \   /    \     | |(___)  /    \  (   )(   ) 
//    |  .-. ; ;  ,-. ' |  .-. ;    | |_     |  .-. ;  | |  | |  
//    |  | | | | |  | | | |  | |   (   __)   | |  | |   \ `' /   
//    |  |/  | | |  | | | |  | |    | |      | |  | |   / ,. \   
//    |  ' _.' | |  | | | |  | |    | |      | |  | |  ' .  ; .  
//    |  .'.-. | '  | | | '  | |    | |      | '  | |  | |  | |  
//    '  `-' / '  `-' | '  `-' /    | |      '  `-' /  | |  | |  
//     `.__.'   `.__. |  `.__.'    (___)      `.__.'  (___)(___) 
//              ( `-' ;                                          
//               `.__.                                                                                                                                                         


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

interface IEGOFOX {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract HugoTheHorse is ERC721A, Ownable {

    using Strings for uint256;

    mapping (uint256 => bool) private redeemed;

    uint256 public maxSupply = 1000;
    string private baseURI = "";
    string public provenance = "";
    string public uriNotRevealed = "";
    
    bool public paused = true;
    bool public isRevealed;
    
    address public egofox = 0xaB49f8929F89A49227A565e92400972bc45B77Af;
    // address public egofox = 0x93A983891819f66a4eCBcfb1721E4f2c445bD8b0;
    
    event Minted(address caller);

    constructor() ERC721A("Hugo the Horse", "HORSE") {}
    
    function redeem(uint256 fox1, uint256 fox2) external{
        require(!paused, "Contract is paused");
        require(fox1 != fox2, "Foxes must be different");
        require(IEGOFOX(egofox).ownerOf(fox1) == msg.sender, "You are not the owner of fox 1");
        require(IEGOFOX(egofox).ownerOf(fox2) == msg.sender, "You are not the owner of fox 2");
        require(redeemed[fox1] == false, "Fox 1 has already been redeemed");
        require(redeemed[fox2] == false, "Fox 2 has already been redeemed");

        redeemed[fox1] = true;
        redeemed[fox2] = true;

        _safeMint(msg.sender, 1);

        emit Minted(msg.sender);
    }

    function mintGiveaway(address _to, uint256 qty) external onlyOwner{
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        _safeMint(_to, qty);
    }
    
    function remaining() public view returns(uint256){
        return maxSupply - totalSupply();
    }
 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed == false) {
            return uriNotRevealed;
        }
        string memory base = baseURI;
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
    }


    // ADMIN FUNCTIONS

    function setFoxAddress(address _addr) public onlyOwner{
        egofox = _addr;
    }
    
    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    // close minting forever!
    function closeMinting() public onlyOwner {
        uint256 supply = totalSupply();
        maxSupply = supply;
    }
    
    function flipRevealed(string memory _URI) public onlyOwner {
        baseURI = _URI;
        isRevealed = !isRevealed;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }
    
    function setUriNotRevealed(string memory _URI) public onlyOwner {
        uriNotRevealed = _URI;
    }

    function setProvenanceHash(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(0x6cfd6b3ca3413a3f4BC93642C0B600823dAfbbB9).send((balance * 1500) / 10000));
        require(payable(0x8ebAc12B75D14D173a1727DC3eEbA78A1A3E382c).send((balance * 8500) / 10000));
    }

    receive() external payable {}
    
}