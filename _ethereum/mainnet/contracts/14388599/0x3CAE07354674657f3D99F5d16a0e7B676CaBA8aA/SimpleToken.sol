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
import "./CIGAR.sol";
import "./WealthyWhales.sol";

contract SimpleToken is Context, Ownable, ERC721, ERC721Enumerable {

    uint public constant MINT_PRICE = 100 ether;

    CIGAR public cigar;
    address public wealthyWhales;
    mapping(address => mapping(uint256 => uint256)) public userToTokenTypes;

    /*
    Token Types:
    0 - Sand Dollar
    1 - Sapphire
    2 - Emerald
    3 - Ruby
    4 - Diamond

    Can always add more types to adjust probabilities through addTypes()
    */
    uint256 public numTypes;

    /*
    repalce wealthyWhales variable with setBurner function. Similar to addController
    */

    constructor() ERC721("TreasureChest", "TC"){
        numTypes = 5;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    function mint(uint256 amount) external {
        uint256 totalCost = 0;
        for(uint i = 0; i < amount; i++) {
            uint256 rand = random(i);
            uint256 itemType = rand % numTypes;

            userToTokenTypes[_msgSender()][itemType]++;
            totalCost += MINT_PRICE;
        }
        cigar.burn(_msgSender(), totalCost);
    }

    // if burn gems, burn one of each of 3 gems. Otherwise burn diamond.
    function burn(address user, bool burnGems) external {
        require(_msgSender() == wealthyWhales, "Must be called by WealthyWhales");
        if (burnGems) {
            userToTokenTypes[user][1]--;
            userToTokenTypes[user][2]--;
            userToTokenTypes[user][3]--;
        } else {
            userToTokenTypes[user][4]--;
        }
    }

    function setExternalContracts(address wealthyWhalesAddress, address cigarToken) public onlyOwner {
        require(wealthyWhales == address(0) && address(cigar) == address(0), "External contracts already initialized");
        wealthyWhales = wealthyWhalesAddress;
        cigar = CIGAR(cigarToken);
    }

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                seed
            )));
    }
}