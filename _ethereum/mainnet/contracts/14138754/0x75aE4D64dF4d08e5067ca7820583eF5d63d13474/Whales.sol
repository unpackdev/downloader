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

contract Whales is ERC721, ERC721Enumerable, Ownable {

    string public PROVENANCE;
    uint256 public constant tokenPrice = 50000000000000000; // 0.05 ETH
    uint public constant maxTokenPurchase = 10;
    uint256 public MAX_TOKENS = 10000;
    bool public saleIsActive = false;

    string private _baseURIextended;

    constructor() ERC721("Secret Society of Whales", "SSOW") {
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

    function reserveTokens() public onlyOwner {
        uint supply = totalSupply();
        require(supply < 200, "More than 200 tokens have already been reserved or minted.");
        uint i;
        for (i = 0; i < 100; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintToken(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= maxTokenPurchase, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}