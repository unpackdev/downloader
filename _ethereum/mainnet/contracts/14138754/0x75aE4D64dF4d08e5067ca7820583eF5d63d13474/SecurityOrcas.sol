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

abstract contract WHALES {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function balanceOf(address owner) public view virtual returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);
}

contract SecurityOrcas is ERC721, ERC721Enumerable, Ownable {

    // Removed tokenPrice

    WHALES private whales;
    string public PROVENANCE;
    bool public saleIsActive = false;
    uint256 public MAX_TOKENS = 10000;
    uint256 public MAX_MINT = 50;
    string private _baseURIextended;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(address whalesContract) ERC721("SSoW Security Orcas", "SO") {
        whales = WHALES(whalesContract);
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

    // Removed reserveTokens

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // TODO: see which costs more gas: mintToken() or mintMultipleTokens(0, 1);
    function mintToken(uint256 tokenId) public {
        require(saleIsActive, "Sale must be active to mint Security Orcas");
        require(totalSupply() < MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(tokenId < MAX_TOKENS, "TokenId does not exist");
        require(!_exists(tokenId), "TokenId has already been minted");
        require(whales.ownerOf(tokenId) == msg.sender, "Sender does not own the correct Whale token");

        _safeMint(msg.sender, tokenId);
    }

    function mintMultipleTokens(uint256 startingIndex, uint256 numberOfTokens) public {
        require(saleIsActive, "Sale must be active to mint Security Orcas");
        require(numberOfTokens > 0, "Need to mint at least one token");
        require(numberOfTokens <= MAX_MINT, "Cannot adopt more than 50 Orcas in one tx");

        require(whales.balanceOf(msg.sender) >= numberOfTokens + startingIndex, "Sender does not own the correct number of Whale tokens");

        for(uint i = 0; i < numberOfTokens; i++) {
            require(totalSupply() < MAX_TOKENS, "Cannot exceed max supply of tokens");
            uint tokenId = whales.tokenOfOwnerByIndex(msg.sender, i + startingIndex);
            if(!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function markPermanentURI(string memory value, uint256 id) public onlyOwner {
        emit PermanentURI(value, id);
    }
}