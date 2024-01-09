//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkxxdoodkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdlodddxxodkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxoooodddooxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOko;:ldkOOkdodxkOOOOOOOOOOkxxdxkOOOOOOOOOOkxddxkkxddl::dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxocclodxkkdddddxkkkkkxdc;,;:oxkkOkkxxddddxkkkxdlcloxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxoooooddxxdddddoc;;;,,:cclllddddxxxxdoolllodxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxddollooolllll:..,llcooooooooooooodxkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkxc'....''';l:,'..,;:oxxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdc'...,ldxxkkkxl:'.':odxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdol,...'lkOOOOOOOOkxl::ldodkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdodo;....,lxkOOOOkxllodo:;lxdoxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxodxd;...'lddllxOOOx;..;ooc,,lxdoxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdloxo:....;clo:';coo;. .;ll:..':olcdOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkd;',,''.  .,odxo,.':l,..'lxkd,......,lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOkkkd:.......  .,odl;..'cd:..'lxdc. ..  ..;okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkxl;:coodddo;...,;;;.. ......,;ldocc;.'.......''.':ldxdoloxkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOxc:cloddxxddc..':okkOko'..:oxkl..   .;lcclodxko'...,cddxo,..,lxkkl..;odxxxxxdc:dOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOo,...,coxkOOd,..':oxkkd;..,::;'....',;clllloool'...,codo;..,okOOx:..cxOOOkkkd:;oOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOxc,. .;cokOOkc. ...,:cc;,,'...  .'cc,........;ol'..........'cdxd:..:dOOOOOOkoclkOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOko;. ..,:oddo;...','.',:cc;'.. .,;,...     ...'cc.. ...,::;''';;...;lxkOOkkoclxOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOko,..  .......,clc;..;dkOkl:'.......... . ......,,...':lxkkdc',lol:;,,,;;;,;lxOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOkc..    ..':oxkl'..lxxdl;,:;...,cl;...'',,:cclc;'...,:',ldkx:.'cdkxdc;'..;okOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOko;...'cokOOOOd:,,cl:,...',..;dkOxc;;looodddkkxc'..',...,clc;;cxOOOOkxxxkOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOkdloxOOOOOOOOkkxdoll:,,;:,.':oxOOkkxxxxkkOOxl,.';loooddxxxkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkdc,..,lxkOOOOOkxoc;'.,lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxc,.',:cccc:;,..',cxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxo:,'.......,:oxkOOOOOOOOOOOOOOOkkxkOOkxkOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkxooxkOOOOOOOOOkdolc:clcoxkOOOOOOOOOOkxxdoodoc;;lkkdokOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOko;',::;cc,':xOOOOOOOOOOkoc:::cdkOOOOOOOOkxxkxl;,',,'',:okx:cxOOOOOOOOOOOOOOOOOOOOOOOOOO
// OO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOko:'..,..,''cxkOOOOOOOOkkd:....;loodkOOOko,.cxxc;'.''',:oko',dOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOO000OOOOOOOOOOOOOOOOOOOOOOOOOx:',,',;,.':oxxkOOOOOkdlcc:,. ..;;;:oxOOOOxl;:ddc;..'. .'ld;.,dOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOO000OOOOOOOOOOOOOOOOOOOOOOxl;''..,ldl;,lolokOOOOkl;'.'....;coxkOOOOOOOxc,,cdc.....,ll,..:xOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd:,.,;;coxkd:'..,oOOOOOOkoccccclodxkOOOOOOdc;,..,:,.....''...'okOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxl;;coxkOOOOkl,..,dOOOOOOOOOOOOOOOOOOOOOOkdlloddooolllooolcccdkOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkddkOOOOOOOOOOkdccdOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
//
// __________ ____ ___  _________ ___ ___ .___________   ________
// \______   \    |   \/   _____//   |   \|   \______ \  \_____  \
//  |    |  _/    |   /\_____  \/    ~    \   ||    |  \  /   |   \
//  |    |   \    |  / /        \    Y    /   ||    `   \/    |    \
//  |______  /______/ /_______  /\___|_  /|___/_______  /\_______  /
//         \/                 \/       \/             \/         \/
// __________________________________
// \______  \   _  \______  \______  \
//     /    /  /_\  \  /    /   /    /
//    /    /\  \_/   \/    /   /    /
//   /____/  \_____  /____/   /____/
//                 \/

import "./ERC721X.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Bushido is ERC721X, Ownable {
    using Strings for uint256;

    bool public publicSale;

    address private markOfTheSunAddress = 0xF960e7bCc123bdB4FDB961537747062295e403c7;

    string public unrevealedURI = 'ipfs://QmYckZUn54yvqLVe1zHiw63YDdqLeoK6YTNYeAUbdMe1Xi/prereveal.json';
    string public baseURI;

    uint256 public maxSupply = 7077;

    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant PRICE_MOTS = 0.06 ether;

    constructor() ERC721X('Bushido7077', 'SHIDO') {}

    // ------------- User Api -------------

    function mint(uint256 amount) external payable whenSaleActive onlyHuman {
        uint256 price = _getMintPrice();

        require(msg.value == price * amount, 'INCORRECT_VALUE');
        require(totalSupply() + amount <= maxSupply, 'MAX_SUPPLY_REACHED');

        _mintBatch(amount);
    }

    // ------------- Modifier -------------

    modifier whenSaleActive() {
        require(publicSale, 'PUBLIC_SALE_NOT_ACTIVE');
        _;
    }

    modifier whenSaleNotActive() {
        require(!publicSale, 'PUBLIC_SALE_ACTIVE');
        _;
    }

    modifier onlyHuman() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }

    // ------------- Admin -------------

    function giveAway(address[] calldata addresses) external onlyOwner {
        uint256 startIndex = totalSupply();

        for (uint256 i; i < addresses.length; i++) {
            _owners.push(addresses[i]);
            emit Transfer(address(0), addresses[i], startIndex + i);
        }
    }

    function burnAllUnminted() external onlyOwner {
        for (uint256 id = totalSupply(); id < maxSupply; id++) {
            emit Transfer(address(0), address(0), id);
        }
        maxSupply = totalSupply();
    }

    function setSaleState(bool _active) external onlyOwner {
        publicSale = _active;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setMarkOfTheSunAddress(address _address) external onlyOwner {
        markOfTheSunAddress = _address;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        bool _success = _token.transfer(owner(), balance);
        require(_success, 'Token could not be transferred');
    }

    // ------------- Internal -------------

    function _mintBatch(uint256 amount) internal {
        uint256 startIndex = totalSupply();
        for (uint256 i; i < amount; i++) {
            _owners.push(msg.sender);
            emit Transfer(address(0), msg.sender, startIndex + i);
        }
    }

    function _getMintPrice() internal view returns (uint256) {
        return MarkOfTheSun(markOfTheSunAddress).balanceOf(msg.sender) > 0 ? PRICE_MOTS : PRICE;
    }

    // ------------- View -------------

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, (tokenId + 1).toString(), '.json'))
                : unrevealedURI;
    }

    function getMarkOfTheSunBalance(address user) public view returns (uint256) {
        return MarkOfTheSun(markOfTheSunAddress).balanceOf(user);
    }
}

interface MarkOfTheSun {
    function balanceOf(address _user) external view returns (uint256 balance);
}
