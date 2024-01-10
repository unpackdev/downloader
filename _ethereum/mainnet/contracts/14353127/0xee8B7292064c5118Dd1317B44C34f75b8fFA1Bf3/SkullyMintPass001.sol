// SPDX-License-Identifier: MIT
//                                         ╒▓▓▓▌  ▄
//                                         ▓▓▓▓▌ ▐▓▓
//             ╨`"▀▒▄                      ▓▓▓▓▌ ▐▓▓µ
//          ,╗█═     ▌                     ▓▀▓▓▌  ▓▓▌
//       ,Æ▀¬       ]∩                     ▓∩▓▓▌  ▓╟▌                 ▄æ▄╓
//      ▄▌           ╙╙└*                ▄▓▓∩▓▓▌ ▄▓▐▓█µ            .      ▀▀┘└*
// ▀█▓▓▓▓▓▄,  ▄▀       ∞█▄▄,            ╫▓▓▓▄▓▓▌▓▓▓▄  ▓            ▌           ▓
//              ¬¬└^╙"``╙`¬             ▓▓▓▓▓▓▓▓▓▓▓▌ ▄▓ ▓▓Γ╓█┴%▄▄wΦ▀           ▀
//                                   ]▐▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓ ╙▀ ▀⌐               Æ┘
//                             ▐▓    ▓╫▓▓▓▓▓▓▓▓▓▓▓▀≥*▀▀▀▀╙╙   ╓╓             ⁿ≈≈▄▄╓
//                             ╫▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▓⌐└└`▌^¬¬¬¬¬¬  ª#▄▄m
//                             ▓▓▌ ▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ╟▓▄
//                       .     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▄█▄▓▓
//                      ▓¬▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▀
//                     ╓▓▌╫╓▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▐▄▄▓▓¬╓▄
//                    ▐▀▐  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▓▐▓▓▓▓▌ ▓┘
//                   ▄    ╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▄▓▓▓▀▀▓▄▄,   ╓,
//                 └▀  ,,,.▀` ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄▓▓▌,▄▓▓▓
//                  ╒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▀▓▓▓▓▓▓▓▓█▀ ╙▓
//        ╓M▓▓▓▓▄Æ      ▀▓▓▓▀▓▌█▀▓▓▓▓▓▓▓▓▓▓▓▓▄▄▄, `¬  ª█▀▀▀▀╙       ╙^         ▄µ
//      ¬  ▄▄▄#▀ê╗,  "▀ ²▀▀▀▀▀▀Mm▓▓▓▀▀▓▀▀╙"∞╙▀▀▀▀ M*╨╙    ,,▄m#█▓▀è▄▄,  ▄▄,▄ª▓▌▀▓▓▄
// MINT-PASS.001 by tortuga
// code by beansandtoast 

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SkullyMintPass001 is ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    mapping(address => uint256) private tokensMinted;

    mapping(address => uint256) private addressTokenId;

    string private customBaseURI;

    uint256 public constant PRICE = 99000000000000000;

    event Minted(uint256 blockNumber, address minter, int numberMinted);

    constructor(string memory customBaseURI_) ERC721("MINT-PASS.001", "TUGAPASS"){
        customBaseURI = customBaseURI_;
        mintPassSupplyCounter.increment(); // start at 1
    }

    /** MINT PASS **/

    uint256 public constant MINT_PASS_SUPPLY = 500;

    Counters.Counter private mintPassSupplyCounter;

    function mint() public payable nonReentrant {

        require(mintPassActive, "Mint passes are unavailable");

        require(_msgSender() == tx.origin, "Can't mint passes from a smart contract");

        require(tokensMinted[_msgSender()] == 0, "Address already owns mint pass");

        require(mintPassSupply() < MINT_PASS_SUPPLY, "Exceeds max supply");

        require(msg.value >= PRICE, "Not enough ETH, you need 0.099 ETH per Skully");

        tokensMinted[_msgSender()] += 1;

        addressTokenId[_msgSender()] = mintPassSupplyCounter.current();

        _safeMint(_msgSender(), mintPassSupplyCounter.current());

        emit Minted(block.number, _msgSender(), 1);

        mintPassSupplyCounter.increment();
    }

    function mintPassSupply() public view returns (uint256) {
        return mintPassSupplyCounter.current() - 1;
    }

    function addressMintPassId(address minter) public view returns (uint256) {
        return addressTokenId[minter];
    }

    /** ACTIVATION **/

    bool public mintPassActive = false;

    function setMintPassActive(bool mintPassActive_) external onlyOwner {
        mintPassActive = mintPassActive_;
    }

    /** URI HANDLING **/

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _baseURI();
    }

    /** PAYOUT **/

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        payable(owner()).transfer(balance);
    }

}
