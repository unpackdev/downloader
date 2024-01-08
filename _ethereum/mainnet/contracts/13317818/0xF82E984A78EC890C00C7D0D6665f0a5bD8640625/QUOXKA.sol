// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeMath.sol";
import "./Math.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Royalty.sol";

contract QUOXKA is ERC721, ERC721Enumerable, ERC721URIStorage, HasSecondarySaleFees, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using Math for uint256;

    uint256 private constant KESEED = 85821;
    address private constant ROYALTY_RECIPIENTS_1 = 0xA297b42c882065bB5C6fFcc38441685db32592A8;
    address private constant ROYALTY_RECIPIENTS_2 = 0x7174257Cd9743E75B57B508D8b8734519B6905F1;
    string private constant _NAME = "QUOXKA";
    
    constructor()
    ERC721(_NAME, _NAME)
    HasSecondarySaleFees(new address payable[](0), new uint256[](0))
    {
        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;

        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }
    
    function _safeMint(address to, uint256 tokenId, string memory tokenFullURI) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenFullURI);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return super.tokenURI(tokenId);
    }

    function bigValue(uint256 tokenId, uint256 _seed) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tokenId, _NAME, _seed))) % 9007199254740990;
    }

    function withdrawETH() external {
        uint256 royalty = address(this).balance / 2;

        Address.sendValue(payable(ROYALTY_RECIPIENTS_1), royalty);
        Address.sendValue(payable(ROYALTY_RECIPIENTS_2), royalty);
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
    
    function viewTokenItem(uint256 tokenId) private pure returns (string memory){
        uint256 seed1 = bigValue(tokenId, 0xac);
        uint256 seed2 = bigValue(tokenId, 0xb2);
        uint256 seed3 = bigValue(tokenId, 0xdc);
        uint256 seed4 = Math.max(Math.max(seed1, seed2), seed3).mod(KESEED);
        return string(abi.encodePacked(seed1.toString(), ",", seed2.toString(), ",", seed3.toString(), ",", seed4.toString()));
    }
    
    function viewGenCodeForOwner(uint256 tokenId) public view onlyOwner returns (string memory){
        return viewTokenItem(tokenId);
    }
    
    function viewGenCode(uint256 tokenId) public view returns (string memory){
        require(_exists(tokenId), "URI query for nonexistent token");
        return viewTokenItem(tokenId);
    }

}

