// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

// OOO OO OO O O OO O OOOOOOOO[[`   .[[\OOOOOOO O OO O O OO OO OOO
// OOO OO OO O O OO O OOO[*...         ....,\\O O OO O O OO OO OOO
// OOO OO OO O O OO o [*.....            ....., [ OO O O OO OO OOO
// OOO OO OO O O o, * *.....   ]/@@@O\`   ..... . *o o O OO OO OOO
// OOO OO OO o \ `* . ....  ,O@@@@@@@@@@\`  ... . .* = o oO OO OOO
// OOO OO Oo \ * *. . ... ,O@@@@@@@@@@@@@@O  .. . .* * , oo OO OOO
// OOO Oo /o * * .. . .. /@@@@@@@@@@@@@@@@@@^ . . .. * * ,o oO OOO
// OOO o/ o^ * * .. . . /@@@@@@@@@@@@@@@@@@@@^  . .. . * */ o\ OOO
// OOo oo o* . . .. .  =@@@@@@@@@@@@@@@@@@@@@O  . .. * * *= /o oOO
// OOo o\ \* * * *. .  O@@@@@@@@@@@@@@@@@@@@@@\   .. . * ** oo ooO
// OOo o/ `` * * *.   O@@@@@@@@@@@@@@@@@@@@@@@@ ^ .. * * *= /o ooO
// OOo \o [* * * *.   O@O[   [\O@@@@@OO[[  ,\O@ ^ .* * * */ oo ooO
// Ooo o/ o^ * * *. . ,O^       ,O@O/        O/ . .* * * *o oo ooO
// OOo oo o/ [ * ** * ..O`        O^        =^. . ** * * /o oo ooO
// OOo oo oo o ^ ** * **.\\`     /OO`     ,O^.* * ** * / /o oo oOO
// OOO oo oo / o \* * ***.,O@@@@@@@@@@@@@@/.*** * ** o / oo oo oOO
// OOO Oo oo o / o\ ` *****..[O@@@@@@@@/`.***** * /o \ o oo oo OOO
// OOO OO oo o o oo o o\`*. ,O@@@@@@@@@@\  *,\o \ oo o / oo oO OOO
// OOO OO Oo o o oo o ooo* =@@@@@@@@@@@@@O` =oo o oo o o oo OO OOO
// OOO OO OO O o oo o ooo`,@@@@@@@@@@@@@@@O.=oo o oo o o OO OO OOO
// OOO OO OO O O Oo o ooo^  @@@@@@@@@@@@@O .ooo o oo O O OO OO OOO
// OOO OO OO O O OO O ooo^.O@@@@@@@@@@@@@@O =oo O OO O O OO OO OOO
// OOO OO OO O O OO O OOOo*O@@@O`]o\`\O@@@O,oOO O OO O O OO OO OOO
// OOO OO OO O O OO O OOOOOoooooOOOOOOoooooOOOO O OO O O OO OO OOO
// OOO OO OO O O OO O OOOOOOOOOOOOOOOOOOOOOOOOO O OO O O OO OO OOO

import {IERC721} from "IERC721.sol";
import {ERC2981} from "ERC2981.sol";
import {ERC721A} from "ERC721A.sol";
import {Ownable} from "Ownable.sol";

// ERC721A?
contract CryptoWontDie is ERC721A, Ownable, ERC2981 {
    uint256 public constant MAX_SUPPLY = 12_000;
    string public baseURI;
    string public postfix;
    string public prerevealURI;
    uint256 public maxByWallet = 2;
    bool public pubSale;
    mapping(address => uint256) public mintedByWallet;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        string memory postfix_,
        string memory _prerevealURI,
        address receiver
    ) ERC721A(name, symbol) {
        baseURI = baseURI_;
        postfix = postfix_;
        prerevealURI = _prerevealURI;
        _setDefaultRoyalty(receiver, 500);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint(uint256 amount) external {
        require(msg.sender == tx.origin, "403 error");
        require(pubSale, "Sale is closed!");
        require(_totalMinted() + amount <= MAX_SUPPLY, "Exceed MAX_SUPPLY");
        require(amount > 0, "Amount can't be 0");
        require(
            amount + mintedByWallet[msg.sender] <= maxByWallet,
            "Exceed maxByWallet"
        );

        mintedByWallet[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    /******************** READ ONLY ********************/

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), postfix)) : prerevealURI;
    }

    /******************** OWNER ********************/
    function setBaseURI(string memory newBaseURI, string memory newPostFix)
        external
        onlyOwner
    {
        baseURI = newBaseURI;
        postfix = newPostFix;
    }

    function setMaxByWallet(uint256 newMaxByWallet) external onlyOwner {
        maxByWallet = newMaxByWallet;
    }

    function setpubSale(bool newpubSale) external onlyOwner {
        pubSale = newpubSale;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    /******************** YOU WANT ALPHA? ********************/
    function alphaMint(uint256 amount) external onlyOwner {
        require(msg.sender == tx.origin, "403 alpha error");
        require(!pubSale, "Sale is open!");
        require(_totalMinted() + amount <= MAX_SUPPLY, "Exceed MAX_SUPPLY");
        require(amount > 0, "Amount can't be 0");
        mintedByWallet[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }
}
