// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
//@author: Angel Moratilla
//@title: Nonameclub
// 
//  _        _______  _        _______  _______  _______  _______  _                 ______  
// ( (    /|(  ___  )( (    /|(  ___  )(       )(  ____ \(  ____ \( \      |\     /|(  ___ \ 
// |  \  ( || (   ) ||  \  ( || (   ) || () () || (    \/| (    \/| (      | )   ( || (   ) )
// |   \ | || |   | ||   \ | || (___) || || || || (__    | |      | |      | |   | || (__/ / 
// | (\ \) || |   | || (\ \) ||  ___  || |(_)| ||  __)   | |      | |      | |   | ||  __ (  
// | | \   || |   | || | \   || (   ) || |   | || (      | |      | |      | |   | || (  \ \ 
// | )  \  || (___) || )  \  || )   ( || )   ( || (____/\| (____/\| (____/\| (___) || )___) )
// |/    )_)(_______)|/    )_)|/     \||/     \|(_______/(_______/(_______/(_______)|/ \___/ 
//
//
//
import "./ERC721Psi.sol";
import "./Ownable.sol";

contract Nonameclub is ERC721Psi, Ownable {
    
    string public baseURI = "ipfs://Qmcb1P45a7ULe23oHuBjAsyX548wyytynJqRVVR8CNnLb1/";
    uint256 public MAX_SUPPLY = 500;
    address private fiatMinter = 0x349560B18AF0aC8474dFa15221C5430A94A5E3C6;
    

    
    constructor()
        ERC721Psi("Nonameclub", "NNC")
        Ownable(msg.sender)
    {}

    function mint(address to, uint256 quantity) external payable onlyOwner{
        // Minting will be restricted to Owner
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        // _safeMint's second argument now takes in a quantity, not a tokenId. (same as ERC721A)
        _safeMint(to, quantity);       
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }
// FIAT MINT
    function setFiatMinter(address _fiatMinter) external onlyOwner {
        fiatMinter = _fiatMinter;
    }
    function getFiatMinter() external view onlyOwner returns (address) {
        return fiatMinter;
    }
    // Fiat mint can only be called by fiatMinter
    modifier onlyFiatMinter() {
        require(fiatMinter == msg.sender, "Caller is not minter");
        _;
    }
    function fiatMint(address to, uint256 quantity) external onlyFiatMinter {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(to, quantity);
    }    

// WITHDRAW
    // In case someone gives eth to the contract
    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
// MISC
    function setBaseURI(string memory _newBaseURI) external onlyOwner{
        baseURI = _newBaseURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    
}