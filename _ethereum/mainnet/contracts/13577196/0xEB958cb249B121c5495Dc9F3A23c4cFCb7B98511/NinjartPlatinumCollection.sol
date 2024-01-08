// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Royalty.sol";


contract NinjartPlatinumCollection is ERC721, ERC721Enumerable, ERC721URIStorage, HasSecondarySaleFees, Ownable {
    using Strings for uint256;

    address private constant SALES_ADDRESS = 0x4D105d2737C65D001839812a8817c7E0D838AA8A;
    address[] public MINTER_ADDRESS = new address[](21);
    string[] public MINTER_URI = new string[](21);

    constructor()
    ERC721("Ninjart Platinum Collection", "NPC")
    HasSecondarySaleFees(new address payable[](0), new uint256[](0))
    {
        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;
        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
        for (uint256 i = 0; i < 21; i++) {
            MINTER_ADDRESS[i] = address(0x0);
            MINTER_URI[i] = "";
        }
    }
    
    function mint() public {
        uint256 hitId = 0;
        for (uint256 i = 1; i < 21; i++) {
            if(MINTER_ADDRESS[i] == msg.sender){
                hitId = i;
            }
        }
        require(hitId > 0, "UnMatch Error");
        _safeMint(msg.sender, hitId);
        _setTokenURI(hitId, MINTER_URI[hitId]);
        safeTransferFrom(msg.sender, SALES_ADDRESS, hitId);
        MINTER_ADDRESS[hitId] = address(0x0);
        MINTER_URI[hitId] = "";
    }
    
    function preMint(uint256 tokenId, address creator, string memory uri)
        public
        onlyOwner
    {
        require(tokenId > 0 && tokenId < 21, "Order Limit");
        require(!_exists(tokenId), "Already mint token");
        MINTER_ADDRESS[tokenId] = creator;
        MINTER_URI[tokenId] = uri;
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    

    function getRoyalty() public view returns(uint256) {
        return address(this).balance;
    }

    function withdrawETH() external {
        uint256 royalty = address(this).balance;
        Address.sendValue(payable(SALES_ADDRESS), royalty);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, HasSecondarySaleFees)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }
    
    receive() external payable {}
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

}

