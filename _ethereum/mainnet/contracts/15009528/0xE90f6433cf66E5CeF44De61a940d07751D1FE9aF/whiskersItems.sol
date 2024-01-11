// SPDX-License-Identifier: MIT
/*
           ──        │   ┐└│      └┘  │  ┌┐       ┐┘ └─┐│ ┐│ ┌ ┌┐      ┐ ││ ┐┐             ╕    ╙╣╬╬╬╬╬╬
    ┐              ─└└  ┘ ┘  ─╕═├┬╕┌│┌┐│┐ └│    ┐ ─   ╕└└┬┌ ─    ╛╡┌┐ ┴┐  │┌│└│┐       ╓╓╥╥╓ ╫╣╩ ║╣╬╬╬╬╬
    ╣╗╗╥╓            ┌└  ┐┐┐ ╛├╡┴╡│╡┤│├││╘ ┐┐┐ │ ┐┘ └  ││  ╕   │└┘└└│ │┌└┘ │ ┐┌    ┌╗╣╣╩╬╬╬╣╣╣╬  ║╣╣╡╬╬╬
     ╙╙╙╝╣╣╣╣╗╗╦╓ └ ┌ ─│ ┌ └╘┘├┘││╛└│┘││┘│┐│       ├ ┌┘ │││┐┌┐╕ ┐         ┘││  ┌─╓╣╣╬╡╬╬╬╬╬╬╬╬╣╣╬╩╙╣╣╡╬╬
    │││││││ └╙╙╙╝╣╣╣╣╗╗╥╥  ││┌│╤ ╕┌┘╕┐└╧╒│ ╕│ ┘ ╕  ╓─┌ │  ││┐     ╕     ╛   ┘╕┐└╔╣╬╡╬╡╬╬╬╬╬╬╬╬╣╬╬╕╓╣╣╬╬╬
    ││││││││││││┌╓ └╙╙╙╙╝╣╣╦╛ ├│┘│┘╕┤╛│┼┐╘││├╡╦┘└│╕ ┌─┤ ╕┐ └┐ └  ╡└ ╕──     ╥╗╣╣╣╬╬╬╬╬╬╬╬╬╬╬╬╬╣╣╬╬╙╙║╣╡╬
    ││││││││ ╓╗╣╣╝╣╗┘┘┌┐╣╣╨╣╣╡└┘└│╕╦╦╦╦╡ ╒╕╦╦╩╙ ├╕   └╛ └╕│ └┤│╛ ╔ ┘│┌╦╓╗╣╣╣╝╨╫╣╬╬╬╬╬╬╡╬╡╬╬╬╣╣╬╬╬   ╣╣╡╬
    ││││ ╓╗╣╣╝╙    ╚╣╦ ╣╣   ╙╣╗┌ ┤╠╡╙╙╛└╚╩╡╡╡╕ ││└│└└ │┐┌ │  │╕╓╛╓╓╗╣╣╣╨╙   ┌╣╣╬╬╬╬╬╬╬╬╬╣╣╣╬╬╬╩╙└   ╚╣╣╬
    │╓╗╣╣╝╙          ╫╣╣      ╫╣╦╓╪│├╛ ╓│╦╬╡╬│ │╛     ┌    │╓╗╗╣╣╣╨╙       ╒╣╣╣╣╣╣╣╣╣╣╣╝╩╨╙╙╣╣╦  ┐    ║╣
    ╣╝╨          ─   ╣╣        ╙╣╣╥│┴╡┤╚╙╚╚╡┤╡┐│└╛╓╡╡╬╡╥╗╣╣╣╝╨╙       ╓╖╖ ╕ ╙╙╙╙╙╙     ┐     ╙╣╣╦ ╕    ║
                    ╣╣           ╙╣╗┐╡╡╛│╙╙╡╡╡╡╬╧╡╛╗╣╣╣╝╨╙         ╓╣╣╝╩╣╣               ┐     ╙╣╣╦
           ─   ─ ─╒╣╣              ╫╣╦╨│└ │╔╔╣╣╗╗╗╣╣╨        ╗╣╣╣╗╗╬╣ ┤│║╣╦                      ╙╣╣╦
                 ╒╣╣                ╙╣╣╥╗╣╣╣╣╨╙╙╙╙          ╟╬╩┤│╙╙╩╙│╞╣╣╬                  ┐┌     ╙╣╣╦
                ┌╣╣  ╓╣╣╣╣╣╣╣╖   ╓╣╣╬╣╜╣╬╙             ┌┐╓╓╓╣╣╣│╡╛└╡││╙╣╣╣╗                    ┐     ╙╣╣
               ╓╣╩   ╣╣│││╛│╙╣╣╣╣╣╩ ╙╣╣ ╫╣╗   ╓╓╖╗╗╣╣╣╣╣╣╝╩╩╙╙╙╙└╕┌  ┤╡┤┤║╣╣╥    ┘┘│             ┐     ╙
              ╓╣╩    ╙╣╣╡┤╡╡╡││╨╙│││╞╣╣╗╣╣╣╣╣╝╩╩╜╙╜╙└└││ │││││╛┘╛ ╕ ╞╣╗╝╜╨╣╣╬╕ ┘ ┌╕  │             ┌
             ╓╣╝       ╚╣╣╣╣╣╡╡╛││┘─┐ │╙└ │││││││╛╛┘└╡└└  ┐  ┌│ ╒└││╩╕   │╨╣╣╬  │╪╬╦                 ┐
         ═  ╔╣╝           ╙╫╣╣╛││╡╦┐  ││││└│┐ ─╕┌┐└  │╡  ┘┐└┐╕  ┘┐└│┤│    ╡╡║╣╦ ╬╬╬╬  │               │
        ─  ╔╣╝            ╔╣╬│╡╡╣╣╗╡╡╦╗┤││╕     └ ┐┌ ┌┘╕ └│┘│┌ └╕┐┐└ ┤╕    ╚╣╣╡╛│╩╬╕┐ │
        ╗ ║╬╝             └╝╣╣╣╩│┘    │││││╓    └ ┌┘┌  └╛┘┘╕┌╕╕└│  ┐└│┤╕ ─┐ ╚╣╣╕  │ ╛ │      └│
    ╗╣╝╝╝╣╣╣╣╣╣╣╣╣╗╗╗╗╗╗╗╗╖╖╖╣╬╦┤┌─    ││╛└│     │  ┐ ┌╦╡│┘╛┤│ ╒│ ┌┌ ╘│┤╕  ┌ ╚╣╣╦┐┌┌┌╕      ╕╕  └
    ╩                  ╙╙╙╙╙╙╟╣╬╕││   ┐ ││┘││      ┌╛││┌││││╕└│       ││┤╕    ╚╣╣╬         │  ╓┐  └    ╣
                             └╣╣╦╗│╕  ┐─ ╡┤││╕    ┌╕╡ │╕││┘│┘┌│  └   ─ ││┤╕    ╚╣╬╬╕         ╠╬╬╬╦  │┌╣╣
                               ╙╝╣╡│      │┤│││      │┌┤│╕╕╕╡╛─         │││ └  │╣╣╬╬     ┘ ┌ ╠╬╬╬╬╦┐╓╣╣
                                 ╣╣╕╕     └│╕ │┐  ┘ ┐┌└│ └  ╕        └ ─ ││  ╒ └║╣╬╬╬  ┘  │┌╦╬╬╬╬╬╬╫╣╝
                                 └╣╣│╕     └│╕││    ┐│┘└┐   └┐  │  ─  ┌  ││     ║╣╣╬╬─  ┐ ╪╬╬╬╬╬╬╡╣╣╨
                                  ║╣╬│╕     └││││ ┐┘┘│┌│┘│┐┌ └  ─      ┌││┘    │ └╣╣╣╦ │ ╬╬╬╬╬╬╬╬╣╣
                              ┌╓╗╣╣╣╣╬╡╕     └╡│││  ┌┘┌│┐┐┐│  │     ╕╡│││   └ ┌   ─│╚╣╣╡┘└╚╡╣╗╦╫╣╝
                          ╓╗╣╣╣╬╬╬╩╨╣╣╣╡╦   ─  └╛│││┐          └┌╕││││┤┘ ─   ┌╦╡╡╡╡╡╦╣╣╪╡╗╫╣╣╜╙╝╣╣╗╗╖
                     ╓╗╗╣╣╬╬╬╩╨╙ ╓┌┌┴╙╣╣╡╡╦  └ ─   └╡││┐│││││││┐││││╛       ╕╣╣╣╣╣╣╣╣╬╬╬╬╣╣╙      ╙╙╝╣╣╗
                 ╓╗╣╣╣╬╬╬╩╙││   ┌╘╕╕╕  ╙╣╣╦╡═┐    ┌       └└└┘╡│┤│││╕     ╕╔╣╣╬╬╬╬╩ ╙╙└╫╣╩└           ╟╙
            ╓╗╗╣╣╬╬╬╩╨╙└       ┌──┐ └└   ╣╣│  ┘ ┐┐    ┌        ╡     └  ─│╙╣╣╡╬╬╬╬╦╕ ╓╣╣╜│       ╙╡╡╡╡╡╡
        ╓╗╣╣╣╬╬╩╨╙┘│ ╗╕ │    └ │─  ╕    ║╣╬│ ┘ ┐╫╡╡╡╗╦╦┐       │  └┘   └ ╔╗╣╣╬╬╬╡╬╬╡╗╣╣╙            │╙╡╡
    ╗╣╣╣╬╬╬╩╙└   └   ╣╣          ┐└     ╟╣╬│╦╗╗╣╬╣╣╣╣╣╗╦╡╡╡┤┐┌┐╛  ┌╔╦╗╡╦╗╣╬╬╡╬╬╬╬╬╬╣╣╩                ╡╡
    ╬╬╩╨╙         ╓╦┐║╣╣╣╗╥    ──  ┌┘    ╣╣╣╣╣╣╬╬╬╬╬╬╬╬╬╣╣╣│╦╦╦╡╦╦╗╣╣╣╣╣╬╬╬╬╩╨└│└╙╩╣╣╗╗╦╦┤╡╡╦╕┌     ┌╡╡╡
      └           └╬╬╣╬╬╬╬╣╣╣╦╥    ┌ │──  ╙╙╩╬╬╬╬╩╙   └╙╙╩╣╣╣╣╬╣╝╩╬╨╬╬╬╩╨╙    ┐┌   ╟╣╣╨╙╝╣╣╣╣╦╦┤╡╡╡╡╡╡╡╡


     ...    .     ...                     .       .x+=:.         ..                                 .x+=:.
  .~`"888x.!**h.-``888h.     .uef^"      @88>    z`    ^%  < .z@8"`                                z`    ^%
 dX   `8888   :X   48888>  :d88E         %8P        .   <k  !@88E                      .u    .        .   <k
'888x  8888  X88.  '8888>  `888E          .       .@8Ned8"  '888E   u         .u     .d88B :@8c     .@8Ned8"
'88888 8888X:8888:   )?""`  888E .z8k   .@88u   .@^%8888"    888E u@8NL    ud8888.  ="8888f8888r  .@^%8888"
 `8888>8888 '88888>.88h.    888E~?888L ''888E` x88:  `)8b.   888E`"88*"  :888'8888.   4888>'88"  x88:  `)8b.
   `8" 888f  `8888>X88888.  888E  888E   888E  8888N=*8888   888E .dN.   d888 '88%"   4888> '    8888N=*8888
  -~` '8%"     88" `88888X  888E  888E   888E   %8"    R88   888E~8888   8888.+"      4888>       %8"    R88
  .H888n.      XHn.  `*88!  888E  888E   888E    @8Wou 9%    888E '888&  8888L       .d888L .+     @8Wou 9%
 :88888888x..x88888X.  `!   888E  888E   888&  .888888P`     888E  9888. '8888c. .+  ^"8888*"    .888888P`
 f  ^%888888% `*88888nx"   m888N= 888>   R888" `   ^"F     '"888*" 4888"  "88888%       "Y"      `   ^"F
      `"**"`    `"**""      `Y"   888     ""                  ""    ""      "YP'
                                 J88"
                                 @%
                               :"

*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Address.sol";
import "./MerkleProof.sol";

contract WhiskersItems is ERC1155, Ownable, ERC1155Burnable, ReentrancyGuard {
  using Address for address;

  string  public  symbol;
  uint256 private _currentTokenId = 1;

  constructor(
    string memory _symbol
  )
    ERC1155('Whiskers: Inventory Items')
  {
    symbol = _symbol;
  }

  function totalSupply()
    public
    view
    returns (uint256)
  {
    uint256 numTokens = _currentTokenId - 1;
    uint256 sum = 0;
    for (uint256 i = 1; i < numTokens+1; i++) {
      Token storage t = Tokens[i];
      sum += t.supply;
    }
    return sum;
  }

  function withdraw()
    public
    onlyOwner
    nonReentrant
  {
    Address.sendValue(payable(owner()), address(this).balance);
  }

  function setSymbol(
    string calldata _symbol
  )
    public
    onlyOwner
  {
    require(bytes(_symbol).length > 0, 'Symbol required');
    symbol = _symbol;
  }

  struct Token {
    uint64  supply;
    uint64  maxSupply;
    uint128 priceWei;
    bytes32 proofRoot;
    bool    paused;
    string  uri;
  }
  mapping(uint256 => Token) public Tokens;
  mapping(uint256 => mapping(address => bool)) public addressMintedToken;

  function uri(
    uint256 _tokenId
  )
    public
    view
    override
    returns (string memory)
  {
    string memory r = Tokens[_tokenId].uri;
    require(bytes(r).length > 0, 'Nonexistent token');
    return r;
  }

  function setTokenURI(
    uint256 _tokenId,
    string calldata _uri
  )
    public
    onlyOwner
  {
    require(bytes(_uri).length > 0, 'URI required');
    Tokens[_tokenId].uri = _uri;
    emit URI(_uri, _tokenId);
  }

  function setTokenMaxSupply(
    uint256 _tokenId,
    uint64 _maxSupply
  )
    public
    onlyOwner
  {
    require(_maxSupply > 0, 'Max supply must be more than 0');
    Tokens[_tokenId].maxSupply = _maxSupply;
  }

  function setTokenProofRoot(
    uint256 _tokenId,
    bytes32 _root
  )
    public
    onlyOwner
  {
    Tokens[_tokenId].proofRoot = _root;
  }

  function setTokenPriceWei(
    uint256 _tokenId,
    uint128 _priceWei
  )
    public
    onlyOwner
  {
    Tokens[_tokenId].priceWei = _priceWei;
  }

  function pauseToken(
    uint256 _tokenId
  )
    public
    onlyOwner
  {
    Tokens[_tokenId].paused = true;
  }

  function unpauseToken(
    uint256 _tokenId
  )
    public
    onlyOwner
  {
    Tokens[_tokenId].paused = false;
  }

  function createToken(
    uint64 _maxSupply,
    string calldata _uri,
    uint128 _priceWei,
    bytes32 _root,
    bool _paused
  )
    public
    onlyOwner
    returns (uint256)
  {
    require(bytes(_uri).length > 0, 'URI required');
    require(_maxSupply > 0, 'Max supply must be more than 0');
    uint256 _tokenId = _currentTokenId;
    _currentTokenId++;

    Tokens[_tokenId] = Token(0, _maxSupply, _priceWei, _root, _paused, _uri);
    emit URI(_uri, _tokenId);
    return _tokenId;
  }

  modifier mintCompliance(
    uint256 _quantity
  )
  {
    require(
      _quantity > 0 && _quantity <= 300,
      "Invalid mint amount"
    );
    _;
  }

  function airdrop(
    uint64 _tokenId,
    address[] calldata _addresses
  )
    external
    onlyOwner
    mintCompliance(_addresses.length)
  {
    Token storage t = Tokens[_tokenId];
    require(
       t.supply + _addresses.length <= t.maxSupply,
      "Maximum supply exceeded"
    );
    for (uint i = 0; i < _addresses.length; i++) {
        _mint(_addresses[i], _tokenId);
    }
  }

  function mint(
    uint64 _tokenId,
    bytes32[] memory _proof
  )
    public
    payable
    nonReentrant
    mintCompliance(1)
  {
    Token storage t = Tokens[_tokenId];
    require(
      msg.value == t.priceWei,
      "Incorrect payment"
    );
    require(
       t.supply + 1 <= t.maxSupply,
      "Maximum supply exceeded"
    );
    require(
      !addressMintedToken[_tokenId][msg.sender],
      "Address already minted"
    );
    require(
      !t.paused,
      "Pausable: paused"
    );
    require(
      MerkleProof.verify(_proof, t.proofRoot, keccak256(abi.encodePacked(msg.sender))),
      "Failed allowlist proof"
    );
    addressMintedToken[_tokenId][msg.sender] = true;
    _mint(msg.sender, _tokenId);
  }

  function _mint(
    address _address,
    uint64 _tokenId
  )
    internal
    virtual
  {
    Token storage t = Tokens[_tokenId];
    _mint(_address, _tokenId, 1, '');
    t.supply += 1;
  }
}
