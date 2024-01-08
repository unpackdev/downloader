/*
SPDX-License-Identifier: GPL-3.0

                                            ZDAOT


MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:',',,''''''''''''''''''',,'''',':0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkolccccccccccccccccccccccccccccccccccookNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMWXKk;.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.;kKXWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNc.,kXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKk,.cNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMX;  ,::::::::::::oXM0c:::::::::::::kWMMMMMMO. ;XMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMKkxc;'        .,,;,lXMx.        ';,,;xWMMMMMMKc,cxkKMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWNNl..xM0,      .dWWWWWMMx.       'OMWWWMMMMMMMMMMWx. lNNWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMO;'lO0NMWKOOOOOO0XMMMMMMMN0OOOOOOO0NMMMMMMMMMMMMMMMx. .',OMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMXxl,  'llllllllllllllllllllllllllllllllllllllllldKMMMMx. .clllxXMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWK0x;..     .....................................  .kMMMMx. lWNl.;x0KWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMX: ,ONo     oXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK: .kMMMMx. lWMNXO, :XMMMMMMMMMMMMMMM
MMMMMMMMMMMMWx;:oxONMd.    .;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;. .kMMMMx. lWMMMNOxo:;xWMMMMMMMMMMMM
MMMMMMMMMMMMNc .kMMMM0c;.  .;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;c0MMMMx. lWMMMMMMk. cNMMMMMMMMMMMM
MMMMMMMMMMMMNc .kMMMMMMWo..dXNWMMMMMMMNXNWMMMMWNXWMMMMMWNXNMMMMMMMMMMWNXd..oWMMMMMMk. cNMMMMMMMMMMMM
MMMMMMMMMMMMNc .kMMMMMMMX0Oc.:0MMMMMMWo.;OMMMMk,'xWWMMMKc.lXMMMMMMMMM0:.cO0XMMMMMMMk. cNMMMMMMMMMMMM
MMMMMMMMMMMMWOlllcxXMMMMMMWklllcxNMMMWOlllcxXMx. lNWWkclllkNMMMMMMNxclllkWMMMMMMMMMk. cNMMMMMMMMMMMM
MMMMMMMMMMMMMMMXl':xOOOOOO0NMKc':xOOOOOOx. '0Mx. lNWX; .oOOOOOOOOOk:':xOOOOOO0NMWKOd;'dWMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNNk'      .xMMWNx. ..      '0Mx. lNWX:          . .xNk'      .xM0, ;0NWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNo,:dkkkkkxkXMMMMXOxkkx'  ckONMx. lNWW0ko. .okxkkkxOXMNOxkkkkkxc;:dk0WMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNd:codddddddddddddddddo'  :dddd;  ,oodddc. .lddddddddddddddddddc:oKMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMM0,..........................................................kMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/

pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Zdaot is ERC721, ERC721Enumerable, Ownable {

    uint256 public constant maxSupply = 6969;
    uint256 private _price = 0.01 ether;
    bool private _saleStarted;
    string public baseURI;

    constructor() ERC721("Zdaot", "ZDAOT") {
        _saleStarted = true;
        baseURI = "ipfs://QmbeHYxGBqFZn6uJoCrGtULTxUssKgjUvEY1ivsqzsk9HH/";
    }

    modifier whenSaleStarted()
    {
        require(_saleStarted);
        _;
    }

    function mint(uint256 _nbTokens)
        external
        payable
        whenSaleStarted
    {
        uint256 supply = totalSupply();
        require(_nbTokens < 21, "There is a limit on minting too many at a time!");
        require(supply + _nbTokens <= maxSupply, "Minting this many would exceed supply!");
        require(_nbTokens * _price <= msg.value, "Not enough ether sent!");

        for (uint256 i; i < _nbTokens; i++) {
            _safeMint(msg.sender, supply + 1 + i);
        }
    }

    function flipSaleStarted()
        external
        onlyOwner
    {
        _saleStarted = !_saleStarted;
    }

    function saleStarted()
        public
        view
        returns (bool)
    {
        return _saleStarted;
    }

    function setBaseURI(string memory _URI)
        external
        onlyOwner
    {
        baseURI = _URI;
    }

    function _baseURI()
        internal
        view
        override(ERC721)
        returns(string memory)
    {
        return baseURI;
    }

    function setPrice(uint256 _newPrice)
        external
        onlyOwner
    {
        _price = _newPrice;
    }

    function getPrice()
        public
        view
        returns (uint256)
    {
        return _price;
    }

    function withdraw()
        public
        onlyOwner
    {
        uint256 _balance = address(this).balance;
        Address.sendValue(payable(msg.sender), _balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}