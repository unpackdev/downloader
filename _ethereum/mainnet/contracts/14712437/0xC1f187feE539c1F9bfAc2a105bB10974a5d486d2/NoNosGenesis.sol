// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

/*

     .-') _                         .-') _                .-')    
    ( OO ) )                       ( OO ) )              ( OO ).  
,--./ ,--,'  .-'),-----.       ,--./ ,--,'  .-'),-----. (_)---\_) 
|   \ |  |\ ( OO'  .-.  '      |   \ |  |\ ( OO'  .-.  '/    _ |  
|    \|  | )/   |  | |  |      |    \|  | )/   |  | |  |\  :` `.  
|  .     |/ \_) |  |\|  |      |  .     |/ \_) |  |\|  | '..`''.) 
|  |\    |    \ |  | |  |      |  |\    |    \ |  | |  |.-._)   \ 
|  | \   |     `'  '-'  '      |  | \   |     `'  '-'  '\       / 
`--'  `--'       `-----'       `--'  `--'       `-----'  `-----'  

No Nos Dev - @nonos_nft
nonosnft.com

*/

contract NoNosGenesis is ERC721A, Ownable {
    string private _baseTokenURI =
        "https://nonos.mypinata.cloud/ipfs/QmQY4XSK6XJhYqTmtbEDDQW66TPJ2i6EvcmQJYcXMbE2SR/";
    uint256 private _maxNoNos = 25;

    constructor() ERC721A("NoNosGenesis", "NONOSGENESIS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function giveawayFighter(address _to, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= _maxNoNos,
            "Reached maximum capacity of No Nos in the Spaceship!"
        );
        _safeMint(_to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function setMaxNoNos(uint256 _newMax) public onlyOwner {
        _maxNoNos = _newMax;
    }

    function getMaxNoNos() public view returns (uint256) {
        return _maxNoNos;
    }

    function withdrawAll() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }
}
