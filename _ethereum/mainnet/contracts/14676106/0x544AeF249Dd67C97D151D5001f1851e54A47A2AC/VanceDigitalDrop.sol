// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
/*
@title:     Chris Vance: First Digital Drop
@artist:    Chris Vance @ https://chrisvanceart.com/
@company:   NiftyFusions @ http://niftyfusions.com/
@dev:       Mr.Wizard @ https://twitter.com/mr_wizar6

                                    ▄▄▄▄╖╖▄▄▄▄▄
                            ▄═╜╙└               └╙╙╗▄▄
                        ▄╤▀                           └▀╗▄
                      ═╙                                  ▀▄
                   ┌▀                                       ▀▄
                  ═                                           █
                 ╜                                             █
                ╧                                               █
               ╧                                                ▐▌
              ▐                                                  █
              ─      ▄ ▄▄██████▓            ┬═┌▄▄▓█████▓▄ ╔      ║▄
             ▐     ╓▀▄███████████          ┘▄█████████████       ▐▌
             ▐    ▄╩▄█████████████        ╓███████████████▌      ▐═
             ╞   ╒╜▐██████████████╒      ┌█████████████████▐     █
             ▐   █ ███████████████      │╫█████████████████    ╒ █
              ▄  ╛ ███████████████      └█████████████████▌═    ╒▌
              ╞╓   ███████████████┌      ██████████████████    └█
               ╦ ▄ ▀████▌████████▌▐     ▐║██████╗█▓█▌█████▌   ╓▄╩
                ▄║▄ █████████████▌▐  ▄  ╚▐██████▀█████████   ╔╫▀
                 ▄└┌███████▀▀████░█ ╒█▄  ░██████▀▀█▀████▓  ┌░▄╩
                  ▀▓╙████▄▄▄████▀█ ┌███▄ ▒██████▌╖▄████▄  ╔╓█
                   ╙▄ ▀████████│█─ ╫████  ▌▀█████████▀╛  ╚╫╜
                     ▓  ▀▀▀█▀██▀─ └▄████▌  └ ▀██████▌▀─╕▄╩
                    █▄█▓       ▄   ██ ███      ─╜ ╙╙  ▒█
                         ─             └           ▄▓█▀▌
                            ═╖▄▄▄▄▄▄▄▄▄▄▄▄▄▄╗╗╗╗╜    └╙
                            └└   ─╙╙╙╙╙▀└╙╩ ─╩└└

*/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Burnable.sol";

contract CVFDD is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;

    // ===== Variables =====
    string public baseTokenURI = "https://niftyfusions.mypinata.cloud/ipfs/QmZ65eEwhe8zHoTbF3ERBVrr2wD2WHZAJFrhn4Bqbxcf7i/";
    uint256 public collectionSize = 96;
    address public recipient = 0xb16eCb727B03c1E10546d8E3AD5B0e669120936d;

    // ===== Constructor =====
    constructor() ERC721A("Chris Vance: First Digital Drop", "CVFDD") {}

    // ===== Reserve mint =====
    function devMint(uint256 amount) external onlyOwner nonReentrant {
        require((totalSupply() + amount) <= collectionSize, "Max out!");
        _safeMint(recipient, amount);
    }

    // ===== Setter =====
    function setBaseTokenURI(string memory _baseTokenURI)
        external
        onlyOwner
        nonReentrant
    {
        baseTokenURI = _baseTokenURI;
    }

    // ===== View =====
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }
}
