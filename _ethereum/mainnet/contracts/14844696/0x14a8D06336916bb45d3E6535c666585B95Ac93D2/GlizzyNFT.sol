// SPDX-License-Identifier: MIT

//  .-_'''-.     .---.    .-./`)  ____..--'  ____..--'   ____     __  
// '_( )_   \    | ,_|    \ .-.')|        | |        |   \   \   /  / 
//|(_ o _)|  ' ,-./  )    / `-' \|   .-'  ' |   .-'  '    \  _. /  '  
//. (_,_)/___| \  '_ '`)   `-'`"`|.-'.'   / |.-'.'   /     _( )_ .'   
//|  |  .-----. > (_)  )   .---.    /   _/     /   _/  ___(_ o _)'    
//'  \  '-   .'(  .  .-'   |   |  .'._( )_   .'._( )_ |   |(_,_)'     
// \  `-'`   |  `-'`-'|___ |   |.'  (_'o._).'  (_'o._)|   `-'  /      
//  \        /   |        \|   ||    (_,_)||    (_,_)| \      /       
//  `'-...-'    `--------`'---'|_________||_________|  `-..-'        
                                                                    
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GlizzyNFT is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 4000;
    uint256 public constant MAX_PUBLIC_MINT = 20;
    uint256 public constant PUBLIC_SALE_PRICE = .0069 ether;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    bool public isRevealed;
    bool public publicSale;
    bool public pause;

    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("GlizzyNFT", "Glizzy"){

    }
    //stops botting from contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Glizzy :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Glizzy :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Glizzy :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Glizzy :: Already minted 3 times!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Glizzy :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

        function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}