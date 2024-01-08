// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./AccessControl.sol";

contract WinkyDeebies is AccessControl, ERC721Enumerable {
    using Strings for uint256;

	string private baseTokenURI;
	bool public paused;
    address private ownerAddress;
    address private deebiesContract;
    

    constructor(address owner_, address deebiesContract_, string memory uri_) ERC721("Winky Deebies", "WINKY_DEEBIES")  {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        setOwner(owner_);
        _setupRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        setBaseURI(uri_);
        setDeebiesContract(deebiesContract_);
        paused = false;
    }

    function claimed(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function baseClaim(uint256 tokenId) private {
        require(IERC721(deebiesContract).ownerOf(tokenId) == _msgSender(), string(abi.encodePacked('You are not the owner of DB ', tokenId.toString())));
        require(!claimed(tokenId), 'Already claimed!');

        _safeMint(_msgSender(), tokenId);
    }


    function claimWinkyDeebies(uint256[] memory tokenIds) public {
        if(_msgSender() != owner()){
            require(!paused, "Pause");
        }
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            baseClaim(tokenIds[i]);
        }
    }

    function owner() public view virtual returns (address) {
        return ownerAddress;
    }

    function setOwner(address owner_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ownerAddress = owner_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = baseURI;
    }

    function setDeebiesContract(address deebiesContract_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        deebiesContract = deebiesContract_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory result = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return result;
    }

    function pause(bool isPaused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = isPaused;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}