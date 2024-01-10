//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Counters.sol";

/********************************************************************

   SSSSSSSSSSSSSSS kkkkkkkk             iiii                   FFFFFFFFFFFFFFFFFFFFFFTTTTTTTTTTTTTTTTTTTTTTT
 SS:::::::::::::::Sk::::::k            i::::i                  F::::::::::::::::::::FT:::::::::::::::::::::T
S:::::SSSSSS::::::Sk::::::k             iiii                   F::::::::::::::::::::FT:::::::::::::::::::::T
S:::::S     SSSSSSSk::::::k                                    FF::::::FFFFFFFFF::::FT:::::TT:::::::TT:::::T
S:::::S             k:::::k    kkkkkkkiiiiiiinnnn  nnnnnnnn      F:::::F       FFFFFFTTTTTT  T:::::T  TTTTTT
S:::::S             k:::::k   k:::::k i:::::in:::nn::::::::nn    F:::::F                     T:::::T
 S::::SSSS          k:::::k  k:::::k   i::::in::::::::::::::nn   F::::::FFFFFFFFFF           T:::::T
  SS::::::SSSSS     k:::::k k:::::k    i::::inn:::::::::::::::n  F:::::::::::::::F           T:::::T
    SSS::::::::SS   k::::::k:::::k     i::::i  n:::::nnnn:::::n  F:::::::::::::::F           T:::::T
       SSSSSS::::S  k:::::::::::k      i::::i  n::::n    n::::n  F::::::FFFFFFFFFF           T:::::T
            S:::::S k:::::::::::k      i::::i  n::::n    n::::n  F:::::F                     T:::::T
            S:::::S k::::::k:::::k     i::::i  n::::n    n::::n  F:::::F                     T:::::T
SSSSSSS     S:::::Sk::::::k k:::::k   i::::::i n::::n    n::::nFF:::::::FF                 TT:::::::TT
S::::::SSSSSS:::::Sk::::::k  k:::::k  i::::::i n::::n    n::::nF::::::::FF                 T:::::::::T
S:::::::::::::::SS k::::::k   k:::::k i::::::i n::::n    n::::nF::::::::FF                 T:::::::::T
 SSSSSSSSSSSSSSS   kkkkkkkk    kkkkkkkiiiiiiii nnnnnn    nnnnnnFFFFFFFFFFF                 TTTTTTTTTTT

********************************************************************/

contract SkinFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant SALE_PRICE = 0.077 ether;
    uint public constant maxSkinftsPerMint = 7;

    bool public IS_SALE_ACTIVE = false;

    Counters.Counter private _tokenIdCounter;

    string public provenanceHash = '4fc7359d04baaff65f424b039d589a29fb044cc9206db1cb7ec019ff56938838';

    /**
     * Images and static traits are proveable on-chain by provenanceHash.
     */
    string private baseTokenURI = 'https://skinft.io/api/';

    constructor() ERC721('SkinFT', 'SKNFT') {
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
        require(tokensAmount <= tokensLimit, 'Minting limit is 7');
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

        _mintTokens(maxSkinftsPerMint, tokensAmount, SALE_PRICE);
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

    function setSaleStatus(bool _isSaleActive) public onlyOwner {
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
