// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 _        ______   _______  _______  _______  _______           _______ 
( (    /|(  ___ \ (  ___  )(  ____ )(  ____ \(  ____ \|\     /|(  ____ \
|  \  ( || (   ) )| (   ) || (    )|| (    \/| (    \/( \   / )| (    \/
|   \ | || (__/ / | (___) || (____)|| (__    | (_____  \ (_) / | |      
| (\ \) ||  __ (  |  ___  ||  _____)|  __)   (_____  )  \   /  | |      
| | \   || (  \ \ | (   ) || (      | (            ) |   ) (   | |      
| )  \  || )___) )| )   ( || )      | (____/\/\____) |   | |   | (____/\
|/    )_)|/ \___/ |/     \||/       (_______/\_______)   \_/   (_______/

          _______  _        _          _______  _______    _______  _______  _______  _______ 
|\     /|(  ___  )( \      ( \        (  ___  )(  ____ \  (  ____ \(  ___  )(       )(  ____ \
| )   ( || (   ) || (      | (        | (   ) || (    \/  | (    \/| (   ) || () () || (    \/
| (___) || (___) || |      | |        | |   | || (__      | (__    | (___) || || || || (__    
|  ___  ||  ___  || |      | |        | |   | ||  __)     |  __)   |  ___  || |(_)| ||  __)   
| (   ) || (   ) || |      | |        | |   | || (        | (      | (   ) || |   | || (      
| )   ( || )   ( || (____/\| (____/\  | (___) || )        | )      | )   ( || )   ( || (____/\
|/     \||/     \|(_______/(_______/  (_______)|/         |/       |/     \||/     \|(_______/
 */
import "./ERC721.sol";
import "./Ownable.sol";

contract nbaychalloffame is ERC721, Ownable {
    string private _baseURIextended;
    bool public isActive = true;
    uint256 private totalSupply_ = 0;
    address payable public immutable shareholderAddress;
    
    constructor(address payable shareholderAddress_) ERC721("nbaychalloffame", "NBAYC Hall of Fame") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
        _baseURIextended = "ipfs://QmSyaLGhvzpwgruaMXNGWpA6LyxpBXYsibuoi5wu9hXGkE/";
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function setSaleState(bool newState) public onlyOwner {
        isActive = newState;
    }

    function mint(address receiver) public onlyOwner {
        require(isActive, "Sale must be active to mint nbaychalloffame tokens");        
        uint256 mintIndex = totalSupply_ + 1;
        totalSupply_ = totalSupply_ + 1;
        _safeMint(receiver, mintIndex);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }
}
