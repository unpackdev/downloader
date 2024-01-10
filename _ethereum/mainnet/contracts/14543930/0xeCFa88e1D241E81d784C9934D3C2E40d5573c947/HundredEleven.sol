// SPDX-License-Identifier: CONSTANTLY WANTS TO MAKE THE WORLD BEAUTIFUL
// AND MIT

// ██╗  ██╗██╗   ██╗███╗   ██╗██████╗ ██████╗ ███████╗██████╗ ███████╗██╗     ███████╗██╗   ██╗███████╗███╗   ██╗
// ██║  ██║██║   ██║████╗  ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝██║     ██╔════╝██║   ██║██╔════╝████╗  ██║
// ███████║██║   ██║██╔██╗ ██║██║  ██║██████╔╝█████╗  ██║  ██║█████╗  ██║     █████╗  ██║   ██║█████╗  ██╔██╗ ██║
// ██╔══██║██║   ██║██║╚██╗██║██║  ██║██╔══██╗██╔══╝  ██║  ██║██╔══╝  ██║     ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║
// ██║  ██║╚██████╔╝██║ ╚████║██████╔╝██║  ██║███████╗██████╔╝███████╗███████╗███████╗ ╚████╔╝ ███████╗██║ ╚████║
// ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚══════╝╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝
                                                                                                                                                                                                                                                     
// EXPERIMENTAL/CONCEPTUAL CRYPTOART METACOLLECTION by Berk aka Princess Camel aka Guerrilla Pimp Minion Bastard 
// 111 pieces. Multiple collections. Interchangeable artwork.
// https://hundredeleven.art
// @berkozdemir

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";

interface IMetaCollection {
    function getMetadata(uint256 tokenId) external view returns (string memory);
}

contract HUNDREDELEVEN is ERC721A, Ownable, ERC2981 {

    address public MetaCollection;
    bool public saleOpen;
    uint public price = 0.15 ether;

    constructor() ERC721A("HUNDREDELEVEN", "111") {
        _safeMint(msg.sender, 5);
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function setMetaCollectionAddress(address _address) public onlyOwner {
        MetaCollection = _address;
    }

    function editRoyalty(address _address, uint96 _royalty) public onlyOwner {
        _setDefaultRoyalty(_address, _royalty);
    }

    function editPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    
    
    // SALE

    function toggleSaleState() public onlyOwner {
        saleOpen = !saleOpen;
    }

    function publicSale(uint quantity) payable public {
        require(saleOpen, "SALE IS NOT OPEN!");
        require(quantity <= 5 , "CHOOSE A VALID AMOUNT");
        require(totalSupply() + quantity <= 110);
        require(msg.value == price * quantity, "MONEY PROBLEMZ");
        _safeMint(msg.sender, quantity);
    }

    function mintLastOne() public onlyOwner {
        require(totalSupply() == 110);
        _safeMint(msg.sender,1);
    }


    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // METADATA
    
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Invalid id");
        require(
            MetaCollection != address(0),
            "Invalid metadata provider address"
        );

        return IMetaCollection(MetaCollection).getMetadata(_tokenId);
    }


}