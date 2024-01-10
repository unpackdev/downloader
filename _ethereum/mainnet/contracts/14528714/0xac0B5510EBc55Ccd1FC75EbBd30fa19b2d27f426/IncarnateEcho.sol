// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IIncarnateEcho.sol";

contract IncarnateEcho is IIncarnateEcho, ERC721A, Ownable {
    mapping(address => bool) private _minters;
    string private _tokenBaseUri = ''; 

    constructor() 
    ERC721A("Incarnate Echo", "INCHO")
    {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseUri;
    }

    function getTokenBaseUri() public view onlyOwner returns (string memory) {
        return _tokenBaseUri;
    }

    function setTokenBaseUri(string memory tokenBaseUri) public onlyOwner {
        _tokenBaseUri = tokenBaseUri;
    }

    function burn(uint256 tokenId) public {
        TokenOwnership memory ownership = ownershipOf(tokenId);
        require(ownership.burned == false, 'Token already burned');
        
        bool isApproved = msg.sender == owner();
        isApproved = isApproved || _minters[msg.sender];
        isApproved = msg.sender == ownershipOf(tokenId).addr;
        isApproved = getApproved(tokenId) == _msgSender();

        require(isApproved, 'Not approved to burn this token');
        _burn(tokenId);
    }

    function mint(address to, uint256 quantity) public {
        require(msg.sender == owner() || _minters[msg.sender] == true, 'Minting access required');

        _safeMint(to, quantity);
    }

    function addMinter(address minter) public onlyOwner {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyOwner {
        delete _minters[minter];
    }
}