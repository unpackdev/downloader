// SPDX-License-Identifier: MIT

/*
                                          «∩ⁿ─╖
                                       ⌐  ╦╠Σ▌╓┴                        .⌐─≈-,
                                ≤╠╠╠╫╕╬╦╜              ┌"░░░░░░░░░░≈╖φ░╔╦╬░░Σ╜^
                               ¼,╠.:╬╬╦╖╔≡p               "╙φ░ ╠╩╚`  ░╩░╟╓╜
                                   Γ╠▀╬═┘`                         Θ Å░▄
                      ,,,,,        ┌#                             ]  ▌░░╕
             ,-─S╜" ,⌐"",`░░φ░░░░S>╫▐                             ╩  ░░░░¼
            ╙ⁿ═s, <░φ╬░░φù ░░░░░░░░╬╠░░"Zw,                    ,─╓φ░Å░░╩╧w¼
            ∩²≥┴╝δ»╬░╝░░╩░╓║╙░░░░░░Åφ▄φ░░╦≥░⌠░≥╖,          ,≈"╓φ░░░╬╬░░╕ {⌐\
            } ▐      ½,#░░░░░╦╚░░╬╜Σ░p╠░░╬╘░░░░╩  ^"¥7"""░"¬╖╠░░░#▒░░░╩ φ╩ ∩
              Γ      ╬░⌐"╢╙φ░░▒╬╓╓░░░░▄▄╬▄░╬░░Å░░░░╠░╦,φ╠░░░░░░-"╠░╩╩  ê░Γ╠
             ╘░,,   ╠╬     '░╗Σ╢░░░░░░▀╢▓▒▒╬╬░╦#####≥╨░░░╝╜╙` ,φ╬░░░. é░░╔⌐
              ▐░ `^Σ░▒╗,   ▐░░░░░ ▒░"╙Σ░╨▀╜╬░▓▓▓▓▓▓▀▀░»φ░N  ╔╬▒░░░"`,╬≥░░╢
               \  ╠░░░░░░╬#╩╣▄░Γ, ▐░,φ╬▄Å` ░ ```"╚░░░░,╓▄▄▄╬▀▀░╠╙░╔╬░░░ ½"
                └ '░░░░░░╦╠ ╟▒M╗▄▄,▄▄▄╗#▒╬▒╠"╙╙╙╙╙╙╢▒▒▓▀▀░░░░░╠╦#░░░░╚,╩
                  ¼░░░░░░░⌂╦ ▀░░░╚╙░╚▓▒▀░░░½░░╠╜   ╘▀░░░╩╩╩,▄╣╬░░░░░╙╔╩
                    ╢^╙╨╠░░▄æ,Σ ",╓╥m╬░░░░░░░Θ░φ░φ▄ ╬╬░,▄#▒▀░░░░░≥░░#`
                      *╓,╙φ░░░░░#░░░░░░░#╬╠╩ ╠╩╚╠╟▓▄╣▒▓╬▓▀░░░░░╩░╓═^
                          `"╜╧Σ░░░Σ░░░░░░╬▓µ ─"░░░░░░░░░░╜░╬▄≈"
                                    `"╙╜╜╜╝╩ÅΣM≡,`╙╚░╙╙░╜|  ╙╙╙┴7≥╗
                                                   `"┴╙¬¬¬┴┴╙╙╙╙""
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./CigarClub.sol";
import "./TreasureChest.sol";
import "./SimpleToken.sol";

contract WealthyWhales is Context, ERC721, ERC721Enumerable, Ownable {

    string public PROVENANCE;
    bool public saleIsActive = false;
    CigarClub public cigarClub;
    TreasureChest public treasureChest;

    uint256 public constant MAX_TOKENS = 1000;

    string private _baseURIextended;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(address _treasureChest) ERC721("Wealthy Whales", "WW") {
        treasureChest = TreasureChest(_treasureChest);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function flipSaleState() public onlyOwner {
        require(address(cigarClub) != address(0), "The CigarClub has not been initialized");
        saleIsActive = !saleIsActive;
    }


    function mintWithGems(uint numberOfWealthyWhales) external {
        require(numberOfWealthyWhales > 0, "Must mint at least 1 wealthy whale");
        require(saleIsActive, "Sale must be active to mint Tokens");
        uint256 totalSupply = totalSupply();
        require(totalSupply + numberOfWealthyWhales <= MAX_TOKENS, "Purchase would exceed max supply of tokens");

        uint256 numSapphires = treasureChest.userToTokenTypes(_msgSender(), 1);
        uint256 numEmeralds = treasureChest.userToTokenTypes(_msgSender(), 2);
        uint256 numRubies = treasureChest.userToTokenTypes(_msgSender(), 3);
        require(numSapphires >= numberOfWealthyWhales, "Must have enough sapphires");
        require(numEmeralds >= numberOfWealthyWhales, "Must have enough emeralds");
        require(numRubies >= numberOfWealthyWhales, "Must have enough rubies");

        for(uint i = 0; i < numberOfWealthyWhales; i++) {
            _safeMint(_msgSender(), totalSupply);
            totalSupply++;
        }

        uint256[5] memory tokensToSpend = [0, numberOfWealthyWhales, numberOfWealthyWhales, numberOfWealthyWhales, 0];
        treasureChest.burn(_msgSender(), tokensToSpend);
    }

    function mintWithDiamonds(uint numberOfWealthyWhales) external {
        require(numberOfWealthyWhales > 0, "Must mint at least 1 wealthy whale");
        require(saleIsActive, "Sale must be active to mint Tokens");
        uint256 totalSupply = totalSupply();
        require(totalSupply + numberOfWealthyWhales <= MAX_TOKENS, "Purchase would exceed max supply of tokens");

        uint256 numDiamonds = treasureChest.userToTokenTypes(_msgSender(), 4);
        require(numDiamonds >= numberOfWealthyWhales, "Must have enough diamonds");

        for(uint i = 0; i < numberOfWealthyWhales; i++) {
            _safeMint(_msgSender(), totalSupply);
            totalSupply++;
        }

        uint256[5] memory tokensToSpend = [0, 0, 0, 0, numberOfWealthyWhales];
        treasureChest.burn(_msgSender(), tokensToSpend);
    }

    function mintWithSanddollars(uint numberOfWealthyWhales) external {
        require(numberOfWealthyWhales > 0, "Must mint at least 1 wealthy whale");
        require(saleIsActive, "Sale must be active to mint Tokens");
        uint256 totalSupply = totalSupply();
        require(totalSupply + numberOfWealthyWhales <= MAX_TOKENS, "Purchase would exceed max supply of tokens");

        uint256 numSanddollars = treasureChest.userToTokenTypes(_msgSender(), 0);
        require(numSanddollars >= numberOfWealthyWhales * 100, "Must have enough sand dollars");

        for(uint i = 0; i < numberOfWealthyWhales; i++) {
            _safeMint(_msgSender(), totalSupply);
            totalSupply++;
        }

        uint256[5] memory tokensToSpend = [numberOfWealthyWhales * 100, 0, 0, 0, 0];
        treasureChest.burn(_msgSender(), tokensToSpend);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (_msgSender() != address(cigarClub)) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "");
        }

        _transfer(from, to, tokenId);
    }

    function setCigarClub(address _cigarClub) external onlyOwner {
        require(address(cigarClub) == address(0), "CigarClub has already been initialized.");
        cigarClub = CigarClub(_cigarClub);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function markPermanentURI(string memory value, uint256 id) public onlyOwner {
        emit PermanentURI(value, id);
    }
}