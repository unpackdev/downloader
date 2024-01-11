//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";

contract ZeroSense is ERC721URIStorage, IERC2981, Ownable, ReentrancyGuard {
  bool public minted = false;
  address public rockGarden;
  uint public standardMintPrice;
  uint public headlinerMintPrice;
  uint public totalMintPrice;

  struct ArtPiece {
    address collector;
    address artist;
    uint256 mintPrice;
    string originalTokenURI;
  }

  mapping(address => uint256) balances;
  mapping(uint => ArtPiece) pieces;

  string public baseURI;

  constructor(uint _standardMintPrice, uint _headlinerMintPrice, address _rockGarden) ERC721("ZeroSenseChapter01", "ZERO/01") {
    standardMintPrice = _standardMintPrice;
    headlinerMintPrice = _headlinerMintPrice;
    rockGarden = _rockGarden;
    totalMintPrice = (standardMintPrice * 22) + (headlinerMintPrice * 2);

    pieces[1] = ArtPiece(
      0xa723835e082A012376581D692E1CcC1bfd0e5017,
      rockGarden,
      standardMintPrice,
      "ipfs://QmZ2M9d4Z7KPtLRq11j3ovXpJ9R4efUYumuo6JUYxNtJue"
    );

    pieces[2] = ArtPiece(
      0xe8A57a6B16A4532015185599797487a41F77eA03,
      0x6C1dbBb980F2a645850131F8144606bdA727c339,
      standardMintPrice,
      "ipfs://QmZQ4uixqhnfyJR4MeFPnFHccxYw7Xk7BdKAk8qhxvmWci"
    );

    pieces[3] = ArtPiece(
      0xa723835e082A012376581D692E1CcC1bfd0e5017,
      rockGarden,
      standardMintPrice,
      "ipfs://QmaZ8zU3jYiJFeGd84bj4E7oXvCRqN52YerZHUZTdFaqMV"
    );

    pieces[4] = ArtPiece(
      0xd88bD55A0CddAA8d431c26EEa0388b58eC398846,
      0xe0121879EA9Cc3CDEb53457edb251065fe27E6cc,
      standardMintPrice,
      "ipfs://Qmd7HpJDMVLbSFHwCPAPPWSPSzPh2fUShME874izmfkTny"
    );

    pieces[5] = ArtPiece(
      0x7d5995afB483a05cd3222fB8E6b152c5a46e752c,
      rockGarden,
      headlinerMintPrice,
      "ipfs://QmPe4kGGgKoJNLo2LEXodds6S2bD83qcGCAR8orhNU4atT"
    );

    pieces[6] = ArtPiece(
      0xa723835e082A012376581D692E1CcC1bfd0e5017,
      0x99d8D9a3c90b94b8A09C9292615E086B22EF4Fd5,
      standardMintPrice,
      "ipfs://QmQYNyFcPk3zbnjp3Zx2tFfrmBAorz3YdCZjveT435u1SQ"
    );

    pieces[7] = ArtPiece(
      0xa723835e082A012376581D692E1CcC1bfd0e5017,
      rockGarden,
      headlinerMintPrice,
      "ipfs://QmdUuBNQZtL2At75jNgibycVGhcm8ixQrvibuQ6sG7o7AN"
    );

    pieces[8] = ArtPiece(
      0x6269AEBabC13FFcbbF3471A6C7adB8F4AdF803f9,
      0xF985e23d04c63CDB8e31aCBEb442e3D6E0B385f1,
      standardMintPrice,
      "ipfs://QmfAGRZWRqbX9nYq2ipH8V2wNUatspZsvaqtYyvyNZcJrh"
    );

    pieces[9] = ArtPiece(
      0x22e309552C7D984f5d04F0A97dB99aa489011C6d,
      0xaDeE5ee18e77CCee0717b707D28d589292B65C9C,
      standardMintPrice,
      "ipfs://QmUu4sHdhAGepnToew5oTUAo6ZyBRuzkorqwpp2UTFMQrr"
    );

    pieces[10] = ArtPiece(
      0x2f0341330BCca77bAc176ec7Ba61ea2c687cc247,
      0xD6a0a0076969a9E6cc264e9B6Addf284AB4f1a41,
      standardMintPrice,
      "ipfs://Qmcw9BywmruLw9hbC9iRUPLYFDZHrViYfvFH3ivV2R5N6W"
    );

    // pieces[11]
    // Artist 11 chose to mint outside of the show. There will be no token 11.

    pieces[12] = ArtPiece(
      0xAD047e46d32b9F538073D1b819f67c87d62970A6,
      0xA82F9339A673763400e74876D42492Af89136e02,
      standardMintPrice,
      "ipfs://QmdBkj67FEJegVfHPpozp2b1GEf8tLchLUsEFAzBLyGKZk"
    );

    pieces[13] = ArtPiece(
      0x0a42027fF32778F4fa4459fe417fF677D36FE1cB,
      0x4dff95fEdc002d968906E036B08E3AEB71D2A61c,
      standardMintPrice,
      "ipfs://Qmf1P2agWgVzm1fPoQGmrFaQQwZGxPv1VXNrip4DFNoqYZ"
    );

    pieces[14] = ArtPiece(
      0x7c6a5A11805069F88CB088294f5ef5bE806a2D93,
      0x47a3dC6A23b477008e9ae687E65dCF8164Ef0F5c,
      standardMintPrice,
      "ipfs://QmZecbhE2DbQhhTPpZdPsvLXXGBtg4spAghhmHtobCTTj6"
    );

    pieces[15] = ArtPiece(
      0x82aBEBF011B6bd78ACcB218898e94d2900fc195f,
      0x53fa194fBcEaBf02dbC29ED94d37Fc9fB5c918FE,
      standardMintPrice,
      "ipfs://QmPTAYmmCiVx54LhGkvB2ivWqcLvQNPdZ5yN1fZsJWd8XK"
    );

    pieces[16] = ArtPiece(
      0xBE4bDEE6B29401d5A02ffBaa71884f988Ab33e05,
      rockGarden,
      standardMintPrice,
      "ipfs://QmbnuyRigZ2xX2GyzTtp3nseA2M41nZeZR8roURBJpFgPN"
    );

    pieces[17] = ArtPiece(
      0xC39cA36A2392CA5bf8755A19B81b4DDfB0F9bcAE,
      0xA82F9339A673763400e74876D42492Af89136e02,
      standardMintPrice,
      "ipfs://QmQ25wpztoidac8ACpBYnReLNmJ9jgUyxJsPHqHUWqu7m3"
    );

    pieces[18] = ArtPiece(
      0x9A8e5BF720e5d463f04962a7B1f7435123D9349c,
      0x4dff95fEdc002d968906E036B08E3AEB71D2A61c,
      standardMintPrice,
      "ipfs://QmdXYbQThMJTkTpiL6pTHDFeRic4JeTrVh6SRd1QQF2jYW"
    );

    pieces[19] = ArtPiece(
      0x25e78e6BF2677BbeFE647850fd40CC3901d3C85c,
      0x47a3dC6A23b477008e9ae687E65dCF8164Ef0F5c,
      standardMintPrice,
      "ipfs://QmV8ezVf29EzNUZNGU8BZQJz7gfqbbw8D2Xj8eWM9vB2DW"
    );

    pieces[20] = ArtPiece(
      0x7575fD4B66BD0e284e1e8c274683047b85A17D5F,
      0xD6a0a0076969a9E6cc264e9B6Addf284AB4f1a41,
      standardMintPrice,
      "ipfs://QmSQoaki1wcE12Z4S5qkGznJvDwxCuXwiAc6Gk1QLVmwJx"
    );

    pieces[21] = ArtPiece(
      0x176C73Fa3Cfc0C6d9c1c65A01225b909dD60b066,
      0x99d8D9a3c90b94b8A09C9292615E086B22EF4Fd5,
      standardMintPrice,
      "ipfs://QmYxgfisMJePaXQNgEZMqxzWoKx84aNR2uJ5fDskyQ5ttN"
    );

    pieces[22] = ArtPiece(
      0x7C8DCc5136CbC26bC644016E446473Ccd631E489,
      0x589dd84e871491f39FD45f38096fF0Dea0930E49,
      standardMintPrice,
      "ipfs://QmPDPeME2nhCbVTBbMG5kMMwcuXCitf9vd7FUCe3GPHfqL"
    );

    pieces[23] = ArtPiece(
      0x04146bBbB794E398F7d6760106A02b4d4fc39578,
      0x53fa194fBcEaBf02dbC29ED94d37Fc9fB5c918FE,
      standardMintPrice,
      "ipfs://QmZju9u9pX19iCkKMdTHqqUJxuHmSqZsWhJr3n8z5c5YLF"
    );

    pieces[24] = ArtPiece(
      0xd88bD55A0CddAA8d431c26EEa0388b58eC398846,
      0xD843387380A5905d293c81B157fcc5d333790909,
      standardMintPrice,
      "ipfs://QmfQyV7F4YLhSLSc5nQ5K4Ub8KfZYyCE8Nz1b2eE5nm4ym"
    );

    pieces[25] = ArtPiece(
      0x5d4DC3F64Da9edb742f816f567601eAF2b340d64,
      0x6C1dbBb980F2a645850131F8144606bdA727c339,
      standardMintPrice,
      "ipfs://QmYqzRSdmVmwEoXKch5AE9zJ1C5wNwMzA421xp7AoiCxmC"
    );
  }

  function withdraw () public nonReentrant {
    address sender = _msgSender();
    uint256 balance = balances[sender];
    require ((balance > 0), 'Sender does have a balance in the contract.');
    balances[sender] = 0;
    payable(sender).transfer(balance);
  }

  function withdrawForAddress (address _address) public onlyOwner nonReentrant {
    uint256 balance = balances[_address];
    require ((balance > 0), 'Sender does have a balance in the contract.');
    balances[_address] = 0;
    payable(_address).transfer(balance);
  }

  // Allow the owner to trigger withdrawal of an artist's balance to another
  // address in case an artist has given us a bad address. Not the most
  // decentralized or trustless system, but I'd rather have a safety net than
  // not.
  function emergencyWithdraw (address _from, address _to) public onlyOwner nonReentrant {
    uint256 balance = balances[_from];
    require (_to != address(0), '_from does have a balance in the contract.');
    require ((balance > 0), '_from does have a balance in the contract.');
    balances[_from] = 0;
    payable(_to).transfer(balance);
  }

  function updateArtistAddress (uint pieceNumber, address _newAddress) public {
    ArtPiece memory piece = pieces[pieceNumber];

    require(piece.mintPrice != 0, 'pieceNumber does not exist');
    require (_msgSender() == piece.artist || _msgSender() == owner(), 'Artist address can only be updated by the artist or the contract owner');
    require(_newAddress != address(0), 'Cannot change address to the zero address');

    pieces[pieceNumber].artist = _newAddress;
  }

  function setRockGardenAddress (address _newAddress) public onlyOwner {
    require(_newAddress != address(0), 'Cannot change rockGarden to 0 address');
    rockGarden = _newAddress;
  }

  function mint () public payable nonReentrant {
    require(minted == false, "Already minted");
    require(msg.value == totalMintPrice, "Incorrect payable amount");
    minted = true;

    ArtPiece memory piece;
    for(uint i=1; i<=25; i++){
	if (i == 11) { continue; } // Piece 11 was minted outside this contract

	piece = pieces[i];
	balances[piece.artist] += piece.mintPrice / 2;
	balances[rockGarden] += piece.mintPrice / 2;
	_safeMint(piece.collector, i);
	_setTokenURI(i, piece.originalTokenURI);
     }
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
    _setTokenURI(tokenId, _tokenURI);
  }

  function getBalance (address _address) public view returns (uint) {
    return balances[_address];
  }

  // ERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // IERC2981
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
    return (pieces[_tokenId].artist, _salePrice / 10);
  }
}
