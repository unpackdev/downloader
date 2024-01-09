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
import "./ICIGAR.sol";

contract TreasureChest is Context, ERC721, ERC721Enumerable, Ownable {

    /*
    Initial Token Types:
    0 - Sand Dollar
    1 - Sapphire
    2 - Emerald
    3 - Ruby
    4 - Diamond
    */
    uint256 public constant NUM_TYPES = 5;
    // mint price in Cigar
    uint256 public mintPrice = 20000 ether;

    string private _baseURIextended;
    // maps user address => map of (token type => num tokens)
    mapping(address => uint256[5]) public userToTokenTypes;
    mapping(address => bool) public controllers;
    ICIGAR public cigar;

    bool public chestIsOpen;
    uint256 public nftChance;
    uint256 public currentNftCount;
    uint256 public nftMaxCount;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor() ERC721("Treasure Chest", "TC") {
        chestIsOpen = true;
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

    function mint(uint256 amount) public {
        require(chestIsOpen, "Chest must be open!");
        uint256 totalCost = 0;
        for(uint i = 0; i < amount; i++) {
            uint256 rand = random(i);
            uint256 itemType = getType(rand % 100);

            userToTokenTypes[_msgSender()][itemType]++;
            totalCost += mintPrice;
        }
        cigar.burn(_msgSender(), totalCost);
    }

    function mintGem(uint256 amount, uint256 gemType) external {
        require(chestIsOpen, "Chest must be open!");
        require(gemType == 1 || gemType == 2 || gemType == 3, "GemType must be 1, 2, or 3");
        uint256 totalCost = 0;
        for(uint i = 0; i < amount; i++) {
            uint256 rand = random(i);
            uint256 rand2 = rand % 10;
            if (rand2 < 4) {
                userToTokenTypes[_msgSender()][gemType]++;
            } else {
                userToTokenTypes[_msgSender()][0]++;
            }
            totalCost += mintPrice;
        }
        cigar.burn(_msgSender(), totalCost);
    }

    function mintDiamond(uint256 amount) external {
        require(chestIsOpen, "Chest must be open!");
        uint256 totalCost = 0;
        for(uint i = 0; i < amount; i++) {
            uint256 rand = random(i);
            uint256 rand2 = rand % 7;
            if (rand2 == 0) {
                userToTokenTypes[_msgSender()][4]++;
            } else {
                userToTokenTypes[_msgSender()][0]++;
            }
            totalCost += mintPrice;
        }
        cigar.burn(_msgSender(), totalCost);
    }

    function superMint(uint256 amount) external {
        require(chestIsOpen, "Chest must be open!");
        uint256 supply = totalSupply();
        uint256 numMinted = 0;
        uint256 nftsMinted = 0;
        uint256 totalCost = 0;
        for(uint i = 0; i < amount; i++) {
            if (currentNftCount < nftMaxCount) {
                uint256 rand = random(i);
                uint256 rand2 = rand % 10000;
                if (rand2 < nftChance) {
                    _safeMint(_msgSender(), supply + nftsMinted);
                    nftsMinted++;
                    currentNftCount++;
                    totalCost += mintPrice;
                } else {
                    mint(1);
                }
                numMinted++;
            } else {
                break;
            }
        }
        cigar.burn(_msgSender(), totalCost);
        mint(amount - numMinted);
    }

    function reserveTokens(uint256 numTokens) external onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function burn(address user, uint256[5] calldata amounts) external {
        require(controllers[_msgSender()], "Must be called by a valid controller address");
        for(uint256 i = 0; i < 5; i++) {
            userToTokenTypes[user][i] -= amounts[i];
        }
    }

    function setNftMintInfo(uint256 chance, uint256 maxCount) external onlyOwner {
        require(chance <= 10000, "Chance must be less than 10000");
        nftChance = chance;
        nftMaxCount = maxCount;
        currentNftCount = 0;
    }

    function adjustTreasureChestPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setCigarToken(address cigarToken) external onlyOwner {
        require(address(cigar) == address(0), "Cigar Token already set.");
        cigar = ICIGAR(cigarToken);
    }

    // adds or removes a controller
    function setController(address controller) external onlyOwner {
        controllers[controller] = !controllers[controller];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function closeOrOpenChest(bool open) external onlyOwner {
        chestIsOpen = open;
    }

    function markPermanentURI(string memory value, uint256 id) public onlyOwner {
        emit PermanentURI(value, id);
    }

    function getTokensForUser(address user) external view returns (uint256[5] memory) {
        return userToTokenTypes[user];
    }

    // Internal functions

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                seed
            )));
    }

    function getType(uint256 rand) internal pure returns (uint256) {
        if (rand < 35) {
            return 0;
        } else if (rand < 40) {
            return 4;
        } else if (rand < 60) {
            return 1;
        } else if (rand < 80) {
            return 2;
        } else {
            return 3;
        }
    }
}