//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Prior art.

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Strings.sol";

// Contract art.

/*
                                                                                  ..    ' .
                                                                             .l-?}cQd*#MB*r.
                                                              ...,,i><]u0b%%B@@$@$$$@@@8p/`
        -U                                       .    .'i<)0do%8%@@$@$$@@@$$@@@@@@@@&ji.
       ;ob^                               'Il_-/YW8@B@@@B@B@@$$$$$$$$$$$$$$$$$@B%bf,
      'UBX             ..    . .'I_xYOhM&8B$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B%t
      i#MI      ..'"l_/rjzOM8&@@@@@@B@@@@@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@*"
     I&@M_rwOpa*&%B@@@$$@@@@@B@BBowak@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@M~
    !hBB@@@@@@BB%#oahmCz/1-. .      f@@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@8)
    '?xCObB@@Bd'' . .              `0$@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@%j
          .c@@M"                  .'Y$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@81
          .rB@@_                   `0$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@8[
           ?8@$z                   'L$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@&]
           'b@@%|.                  t%@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@#;
          . (B@@Z`                  ~*@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@X.
            ^Q@@B/                  "m@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B|
             <*@@@? .                ;M@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@@@U
              lo@BM}                  J@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@@ai
               io@@8_                 'v%@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@@J'
                (%@@@J`.               `0@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@8)
                .f8$@@k>                ^mB$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$8!
                  ,LBBB8X^.             .'j8B@$$$$$$$$$$$$$$$$$$$$$$$$$$@@a<.
                   .]%@BBBO`             ..-#@@@$$$$$$$$$$$$$$$$$$$$$$@@@o!
                     "uB@@@8v`             .,Y%@@$$$$$$$$$$$$$$$$$$$$@@@Q`
                      ."Y&B@@Bd1^  .          .YWB@@$$$$$$$$$$$$$$@@@BW).
                         '-k@@@@BMJ[:          ."UqB$$$$$$$$$$$$$$@B&t'
                           .[L#BB@@@BMn+>^.        ^juJ*&B$$$$$@@BW/.
                              .!vWB@B@@@@@WWdCxf)/zJ0woM8@@@@$@%f:
                               . .."Yw*WB@@$$@@@@B@@B@@$$@8hqxI
                                        ,<{/0qmW%%B#aQv(-;'
                                                .
*/

// Whoops.

error ItemExists();
error SystemMustCall();

// Another agreement. A contract, if you will.

contract SSAInventory is ERC1155, Ownable {
using Strings for uint256;

  address public mainContractAddress;

  string public _baseURI;

  Item[] public items;
  mapping (string => Item) public inventory;

  struct Item {
    uint id;
    string name;
  }

  // Mods

  modifier onlySystem() {
    if (!(msg.sender == owner() || msg.sender == mainContractAddress)) revert SystemMustCall();
    _;
  }

  // Welcome to the Item Factory.

  constructor() ERC1155("") {}

  function supplyPaidAgents(address _to, uint _amount)
    external
    onlySystem
  {
    _mint(_to, 0, _amount, "");
    _mint(_to, 1, _amount, "");
    _mint(_to, 2, _amount, "");
  }

  // The Agency can shop for itself or others.
  function agencyMint(address _to, uint _itemId, uint _count)
    external
    onlySystem
  {
    _mint(_to, _itemId, _count, "");
  }

  // Admin.

  function addNewItem(string calldata _name)
    public
    onlyOwner
  {
    Item memory item = Item({
      id: items.length,
      name: _name
    });

    items.push(item);
    inventory[_name] = item;
  }

  function createGenesisItems(string[] calldata _names)
    external
    onlyOwner
  {
    for(uint i; i < _names.length;) {
      addNewItem(_names[i]);

      unchecked { ++i; }
    }
  }

  // Giveth. Taketh away.

  function sendAgentItems(address _to, uint _itemId, uint _count)
    external
    onlySystem
  {
    _mint(_to, _itemId, _count, "");
  }

  function destroyAgentItems(address _from, uint _itemId, uint _count)
    external
    onlySystem
  {
    _burn(_from, _itemId, _count);
  }

  // Set.

  function setBaseURI(string calldata baseURI)
    external
    onlyOwner
  {
    _baseURI = baseURI;
  }

  function setMainContractAddress(address _address)
    external
    onlyOwner
  {
    mainContractAddress = _address;
  }

  function uri(uint256 tokenId)
    public
    view
    virtual
    override
  returns (string memory) {
    return bytes(_baseURI).length > 0
      ? string(abi.encodePacked(_baseURI, tokenId.toString()))
      : "";
  }

}
