//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Counters.sol";

/********************************************************************
 __          __             _        _______
 \ \        / /            | |      |__   __|
  \ \  /\  / /__  _ __ ___ | |__   __ _| | ___  __ _ _ __ ___
   \ \/  \/ / _ \| '_ ` _ \| '_ \ / _` | |/ _ \/ _` | '_ ` _ \
    \  /\  / (_) | | | | | | |_) | (_| | |  __/ (_| | | | | | |
     \/  \/ \___/|_| |_| |_|_.__/ \__,_|_|\___|\__,_|_| |_| |_|

********************************************************************/

contract WombatTeam is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant SALE_PRICE = 0.05 ether;
    uint public constant maxWombatsPerMint = 5;

    bool public IS_SALE_ACTIVE = false;

    Counters.Counter private _tokenIdCounter;

    string public provenanceHash = '964f05559697da4aba3f23d65de05bbf5e6d0b366fe82c3cbdf1d990a0d2246a';

    /**
     * Images and static traits are proveable on-chain by provenanceHash.
     */
    string private baseTokenURI = 'https://wombat.team/api/tokens/';

    constructor() ERC721('WombaTeam', 'WMBTM') {
    }

    function _mintOneToken(address to) internal {
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
    }

    function _mintTokens(
        uint256 tokensLimit,
        uint256 tokensAmount,
        uint256 tokenPrice
    ) internal {
        require(tokensAmount <= tokensLimit, 'Minting limit is 5');
        require(
            (_tokenIdCounter.current() + tokensAmount) <= MAX_SUPPLY,
            'Minting would exceed total supply'
        );
        require(msg.value >= (tokenPrice * tokensAmount), 'Incorrect price');

        for (uint256 i = 0; i < tokensAmount; i++) {
            _mintOneToken(msg.sender);
        }
    }

    function mintSale(uint256 tokensAmount) public payable {
        require(IS_SALE_ACTIVE, 'Sale is closed');

        _mintTokens(maxWombatsPerMint, tokensAmount, SALE_PRICE);
    }

    function mintReserved(uint256 tokensAmount) public onlyOwner {
        require(
            _tokenIdCounter.current() + tokensAmount <= MAX_SUPPLY,
            'Minting would exceed total supply'
        );

        for (uint256 i = 0; i < tokensAmount; i++) {
            _mintOneToken(msg.sender);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setSaleState(bool _isSaleActive) public onlyOwner {
        IS_SALE_ACTIVE = _isSaleActive;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
