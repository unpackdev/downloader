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
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./CigarClub2.sol";

contract WealthyWhales2 is Context, ERC721, ERC721Enumerable, Ownable {

    uint256 public constant MAX_TOKENS = 2000;
    uint public maxTokenPurchase = 10;

    uint256 public priceInWrld = 100 ether;
    uint256 public priceInEth = 0.08 ether;

    IERC20 public wrldToken;
    CigarClub2 public cigarClub;
    string public PROVENANCE;
    bool public saleIsActive = false;
    bool public wrldSaleIsActive = false;
    string private _baseURIextended;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(address _wrldToken, address _cigarClub) ERC721("Wealthy Whales Gen2", "WW") {
        wrldToken = IERC20(_wrldToken);
        cigarClub = CigarClub2(_cigarClub);
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

    function mintTokenWithEth(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= maxTokenPurchase, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(priceInEth * numberOfTokens == msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mintTokenWithWrld(uint numberOfTokens) public {
        require(wrldSaleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= maxTokenPurchase, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(priceInWrld * numberOfTokens <= wrldToken.balanceOf(msg.sender), "WRLD balance is not enough");

        require(wrldToken.transferFrom(msg.sender, address(this), priceInWrld * numberOfTokens), "WRLD transfer failed");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function setPriceInEth(uint256 price) external onlyOwner {
        priceInEth = price;
    }

    function setPriceInWrld(uint256 price) external onlyOwner {
        priceInWrld = price;
    }

    function setWrldAddress(address token) external onlyOwner {
        wrldToken = IERC20(token);
    }

    function setMaxTokenPurchase(uint256 max) external onlyOwner {
        maxTokenPurchase = max;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipWrldSaleState() external onlyOwner {
        wrldSaleIsActive = !wrldSaleIsActive;
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
        cigarClub = CigarClub2(_cigarClub);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function markPermanentURI(string memory value, uint256 id) public onlyOwner {
        emit PermanentURI(value, id);
    }
}