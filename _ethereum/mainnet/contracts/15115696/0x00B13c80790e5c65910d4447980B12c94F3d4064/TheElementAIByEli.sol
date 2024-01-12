//SPDX-License-Identifier: Unlicense
//    .....                                          ..      .           ..                                                              s         ..                  .....     .
//  .H8888888h.  ~-.    .uef^"                     x88f` `..x88. .> x .d88"                                                              :8      :**888H: `: .xH""    .d88888Neu. 'L
//  888888888888x  `> :d88E                      :8888   xf`*8888%   5888R                 ..    .     :                  u.    u.      .88     X   `8888k XX888      F""""*8888888F
// X~     `?888888hx~ `888E            .u       :8888f .888  `"`     '888R        .u     .888: x888  x888.       .u     x@88k u@88c.   :888ooo '8hx  48888 ?8888     *      `"*88*"
// '      x8.^"*88*"   888E .z8k    ud8888.     88888' X8888. >"8x    888R     ud8888.  ~`8888~'888X`?888f`   ud8888.  ^"8888""8888" -*8888888 '8888 '8888 `8888      -....    ue=:.
//  `-:- X8888x        888E~?888L :888'8888.    88888  ?88888< 888>   888R   :888'8888.   X888  888X '888>  :888'8888.   8888  888R    8888     %888>'8888  8888             :88N  `
//       488888>       888E  888E d888 '88%"    88888   "88888 "8%    888R   d888 '88%"   X888  888X '888>  d888 '88%"   8888  888R    8888       "8 '888"  8888             9888L
//     .. `"88*        888E  888E 8888.+"       88888 '  `8888>       888R   8888.+"      X888  888X '888>  8888.+"      8888  888R    8888      .-` X*"    8888      uzu.   `8888L
//   x88888nX"      .  888E  888E 8888L         `8888> %  X88!        888R   8888L        X888  888X '888>  8888L        8888  888R   .8888Lu=     .xhx.    8888    ,""888i   ?8888
//  !"*8888888n..  :   888E  888E '8888c. .+     `888X  `~""`   :    .888B . '8888c. .+  "*88%""*88" '888!` '8888c. .+  "*88*" 8888"  ^%888*     .H88888h.~`8888.>  4  9888L   %888>
// '    "*88888888*   m888N= 888>  "88888%         "88k.      .~     ^*888%   "88888%      `~    "    `"`    "88888%      ""   'Y"      'Y"     .~  `%88!` '888*~   '  '8888   '88%
//         ^"***"`     `Y"   888     "YP'            `""*==~~`         "%       "YP'                           "YP'                                   `"     ""          "*8Nu.z*"
//                          J88"
//                          @%
//                        :"


pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

contract TheElementAIByEli is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string  public baseTokenURI = "https://bafybeidjw4vdk6hxe7u5jeh4sa344hm67ssjod6xhromimmxlid6yfjuwy.ipfs.nftstorage.link/metadata";
    uint256 public MAX_SUPPLY = 1000;
    uint256 public MAX_PER_TX = 5;
    uint256 public MAX_PER_WALLET = 5;
    uint256 public PRICE = 0.005 ether;
    uint256 public MAX_FREE_PER_WALLET = 1;
    bool public initialize = true;

    mapping(address => uint256) public qtyFreeMinted;

    constructor() ERC721A("TheArtOfCode", "TAOC") {}

    function mint(uint256 numberOfTokens) external payable
    {
        require(initialize, "Error not ready");
        require(numberOfTokens > 0, "Need to be more than 0");
        require(numberOfTokens <= MAX_PER_TX, "Max mints per transaction exceeded");

        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "The mint end");

        uint256 tokensOfSender = balanceOf(msg.sender);

        require(tokensOfSender + numberOfTokens <= MAX_PER_WALLET, "More than limit");

        bool alreadyMintedAFree = qtyFreeMinted[msg.sender] >= MAX_FREE_PER_WALLET;

        if (alreadyMintedAFree) {
            require(msg.value > 0, "You already minted a free");
        }

        bool isTryingToMintAOneFreeMint = !alreadyMintedAFree
            && numberOfTokens == 1
            && msg.value == 0;

        if (!alreadyMintedAFree && !isTryingToMintAOneFreeMint) {
            require(msg.value >= (PRICE * (numberOfTokens - MAX_FREE_PER_WALLET)), "Error");
        }

        bool itsAPaidMint = !isTryingToMintAOneFreeMint && alreadyMintedAFree;
        if (itsAPaidMint) {
            require(msg.value >= (PRICE * numberOfTokens) , "Incorrect ETH value sent");
        }

        if (!alreadyMintedAFree) {
            qtyFreeMinted[msg.sender] += 1;
        }

        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner nonReentrant
    {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    function setInitialize(bool _initialize) external onlyOwner
    {
        initialize = _initialize;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PER_TX = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE_PER_WALLET = _limit;
    }
}