//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// """"""""""""""""""""""""""""""""""""""""""""""""""""" Noun Cats – The Early Birbs """"""""""""""""""""""""""""""""""""""""""""""
// """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
// """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""""""""""""""":-------------------------------_______-i"""""""""""""""""""""""""""""""""
// """"""""""""""""""""""""""""""""""""""""""""""""""""""lmwqqqpppqqqqqqqqqqqqqqqqqqqqqqqqdhkkbddt"""""""""""""""""""""""""""""""""
// """"""""""""""""""""""""""""""""""""""""""""""""""""""lwppppppqqqqqqqppppqqqqpppppppppqpoakbddf"""""""""""""""""""""""""""""""""
// """"""""""""""""""""""""""""""""""""""""""""""""""""""!qppdddddddddddddddppppddddddddddd*ohkkbf"""""""""""""""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""{mmmmmmmmmmmmwqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqqqdbddqwwmmmmwwC,"""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""}wwwwwwwwwqqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwkakbbbpppqpppC,"""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""}wwwwwwwqqpppqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwkoakbddddppppC,"""""""""""""""""""
// """""""""""""""""""""""""""""""""",Illlll(wwwwwqqppppppqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqkahkkbdddddddL!l!lll:"""""""""""""
// """""""""""""""""""""""""""""""""":mwqwqqwwwqqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwpakbddp["""""""""""""
// """""""""""""""""""""""""""""""""":mwwwwqqwqqpppqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqqqqqqqqqqboakbbd["""""""""""""
// """""""""""""""""""""""""""""""""";mqpdddpppppddqwwqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqqqqqqqqqqqqqqqqbooakdd}"""""""""""""
// """""""""""""""""""""""""""""""""";mwwwqqwwwwqqqwwwqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqwwwwqqqqqqqqqqqqpqqqqw1"""""""""""""
// """""""""""""""""""""""""""""""""";wwqqqqqqqqqqqqqqqqqqpppppppppqqqqqqqqqqqqqqqqqqqqqqpppppppppppppppppppppppppppp}"""""""""""""
// """""""""""""""""""""""""""""""""";qqppppppppppppppppppddddppppppppppppppppqqqpppppppppddddddddddddddddddppppdpppp}"""""""""""""
// """""""""""""""""""""""""""""""""";Zwwqqqqwwwqqqqqqqqqqqqqqqqqqqwwwwqqqqqwpdpppppwwwwqqqqqqqqqqqqqqqqqqqqqqqqqqqqq{,,,,,,"""""""
// """""""""""""""""""""""""""""""""":|(|(((((((((((((((((((((((((((((((((((|vbbbdpq/(((|||||||||||||||||||||||||||||(|(||(}"""""""
// """""""""""""""""""""""""""""""""":(((((((((((((((((((((((((((((((((((((((chkkbbb/|(((((((((((((((((((((((((((((((((((((}"""""""
// """""""""""""""""""""""""""""""""";((((((((||((((((((((((((((((((((((((((|cahbbdd||(((((((((((((((((((((((((((((((((((((}"""""""
// """""""""""""""""""""""""""""""""":((((((;            ^wwwwwwwwqqqpw|((((|vahbbdd||((((+ .          .wdddddddddddp/((((|}"""""""
// """""""""""""""""""""""""""""""""^;(((((|:            ^M########M##*|(((((vahkbdd||((((_             h#MM####MMMM#/|(((|}"""""""
// """""""""""""""""""""""""""""""""";((((((;            ^M###########o|(((((vaahhkb|(((((_             k#MM########*/(||(|}"""""""
// """""""""""""""""""""""""""""""""":((((((;            ^M###########o|(((((cM##akb|(((((_             k#MM########*/(||(|}"""""""
// """""""""""""",|((((((((((((((((||||(((((:            ^############o|((((((((((((((((((_             k#MM#MMMM###*/(||||}"""""""
// """""""""""""",|((((((((((((((((||||(((((:            ^############o|((((((((((((((((((_             k#MM#MMMM###*/(||||}"""""""
// """""""""""""",|(((((((((((((((((|(|(((((;            ^#####MMMM###o|((((((((((((((((((_             k#MM#MMMM###*/|||||}"""""""
// """""""""""""",|((((([!llllllll!l!>|(((((;            ^#####MMMM###o|(((((rLLLLLL/(((((_             k#MM#MMMM###*/|||||}"""""""
// """""""""""""",|(((((-"""""""""""":((((((:            ^#####MMMM###o|(((((z*oaahk/(((((_             k#MM#MMMM###*/(||||}"""""""
// """""""""""""",|(((((-"""""""""""":((((((;            ^############o|(((((c*ahhkd/((((|_             k#MM#MMMM###*/|||||}"""""""
// """""""""""""",|(((((-"""""""""""":((((((;            ^############o|((((|c*ahhkd/((((|_             k#MM#MMMM###*/|||||}"""""""
// """""""""""""",|(((()-"""""""""""":((((((;            ^############o|(((((coahkbb/((((|_             k#MM#MMMM###*/|||||{"""""""
// """""""""""""",|(((()_"""""""""""":((((((;            ^MMMM########o|(((((cahhbbb/((((|_             k#MM#MMMM###*/|||||{"""""""
// """""""""""""",|((())_"""""""""""":((((((;            ^MMMM########o|(((((cahhbbp/((((|_             k####MMMM###*/|||||{"""""""
// """""""""""""""_+++++i"""""""""""":((((((~;;;;;;;;;;;;lUUUUUUUUUUJUz|((((|vahhkbd/|((((];;I;;;;;;;;;lzYYYYYXXXYYUX/||||({"""""""
// """""""""""""""""""""""""""""""""":(((((((((((((((((((((((((((((((((((((((cahhkbd/|((((((|((((((((((((|||||||||((||||||({"""""""
// """""""""""""""""""""""""""""""""":((((((((((((((((((((|||||||||((((((((((cahhkkp|((((((((((((((((((((((((((((((((((||((}"""""""
// """""""""""""""""""""""""""""""""":((((((((((((((((((((||||||||((((((((((|coahkbp|((((((((((((((((((((((((((((((((||||||{"""""""
// """""""""""""""""""""""""""""""""";wpbbbbbbbbbbbbbbbbkkkkkkkkkkkkkkkkkkkkb);;IIII;;;;;;>hhhhkkkkkbkkkkkkkkkkkbkkkk}"""""""""""""
// """""""""""""""""""""""""""""""""";qpqppppppdppppppppddddddbdddbbbddddddpp1III;;;;;;;;I<hahhbbbbddddpppppppppppppp["""""""""""""
// """""""""""""""""""""""""""""""""";qqqqqqqqqqqqqqqqpqqqppddddddddddppppqqq{III;;;;;;;;I<aahkbbdpppppqqqqqqqqqqqqqq["""""""""""""
// """"""""Iiiiii>iiiiiiiiiiii>>iiiii~wwqwwqwwqqqqqqqqppppqpppddddpppppdppppq1II;;;;;;;;;;!JCJUUYZpppqqqqqqqqqqqqqqqq}"""""""""""""
// """"""",twwwwwqwwwwwwwwwwwwqqwwwwwwwwwwwwwqqqqqqqqqpppqOOOOOOOOOOOOOkkdpqq1II;;;;;;;;;;;;;;;;;cbbppqqqqqqwqqqqwwww}"""""""""""""
// """"""",twwwwwqwwmwwwwwwwwwqqwwwwwwwwwwwwqqqqpqqqpppppqZOOOOOOOOOOOOhkbppq1II;;;;;;;;;;;;;;;;;cbdpppqqwwwwwwwwwwww}"""""""""""""
// """"""",twwwwwwwwwwwwwwwwwwqwwwwwwwwwwwwqqqppddddddbbbdZZOOOOOOOOOOOhkdppq)III;;;;;;;;;;;;I;;;cddppqqwwwwwwwwwwwww}"""""""""""""
// """"""",twwwwwqwwwwwwwwwwwwqwwwwwwwwwwwqqmZOOOZZZZOOZZZmmwwwwwwwwwwZhbbppqwwwwwwwwwwwwwwwwwwqqbdppqqwwwwwwwwwwwwww}"""""""""""""
// """"""",fwwwwqqwwwwwwwwwwwwqwwwwwwwwqqqqpwOOOOOOOOOOOOZwwwwwwwwwwmwmhkdppqqqqqqqqqqqqqqqqqqqqqqqqqqqwwwwwwwwwwwwww}"""""""""""""
// """"""",fwwwwqqwwwwwwwwwwwwqwwwwwwqqqppppwOOOOOOOOOOOOZmwwwwwwwwwwwmakdppqqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww}"""""""""""""
// """"""",(CCCCCCwqqqqqqwwqqqqwwwwqqqwqpdddqZOZOZZZZZZZZZmwwwwwwwwwwwmhkdppqqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww}"""""""""""""
// """""""""""""",qppdbbbbkkkkkqwwwwqqZZOOOOmwwwwwwwwwwwwwwwwwwwwwwwwwmhkdppqqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww}"""""""""""""
// """"""""""""""^wqqqqqqqqqqppwwwwqqqZZZZZZmwwwwwwwwwwwwwwwwwwwwwwwwwmhkdpqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww}"""""""""""""
// """""""""""""""wwwwwwwwqqqqqwwwwwwwZZZZOOmwwwwmmmwwwwwwwwwwwwwwwwwwmhkbpqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww}"""""""""""""
// """""""""""""",llllll?wwwwqqpdbbkkkpdbbkhpZZZZZZZZZZZZmwwwwwwwwwwwwmkkbpqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww}"""""""""""""
// """""""""""""""""""""~wwwwqqqqpppddqppddbwOOOOOOOOOOOOZwwwwwwwwwwwwmhkbpqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww}"""""""""""""
// """""""""""""""""""""~wwwwwqqqqqpppqqqqqpmOOOOOOOOOOOOZwwwwwwwwwmwwmhkbpqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww}^""""""""""""
// """""""""""""""""""""~ZZZZZZZZZZmmmqqwqqqmOOOOOOZZOOOOZwwwwwmmmmmwwmhkbpqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqwwq}^""""""""""""
// """""""""""""""""""""""""""""""""";wwwwwwwqdbbbbbkkkhhaZOOOOOOOOOOZOhkbpqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwdoaahhk["""""""""""""
// """""""""""""""""""""""""""""""""";wwwwwwwqqqqppppppddpOOOOOOOOOOOZOhkdpqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwdohkbpp["""""""""""""
// """""""""""""""""""""""""""""""""";mwwwwwwqqqqqqwqqqqpqOOOOOOOOOOOO0hkdpqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqhkbdpq["""""""""""""
// """""""""""""""""""""""""""""""""":++++++fdbbbkkdbdddbbdddddpdddppppkbbbbbbddddbbbdddddddddbbbbbddddbkkkkbkZ_+~~~~I"""""""""""""
// """""""""""""""""""""""""""""""""""""""""{bbkkkhdddpddddbbbbbbbbbbbbbbbbdbbbdddddddddddddddddddddddddoaahhhZ,"""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""}ddbbbkpqqqqqqqqqqppdpddddddddppppppppppqqqqqqqqqqqqqqppppqqhakbbb0""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""}pqppdbpqwwwwwqwqwqpqqppppppppppqqqqqqqqqwwwwwwqqqqqqwqqqqqqhhkbdpQ""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""^^^^^""""^^^^:kkkkkk/^^^^^^^"""^^^^^^^^^^^^^^^"qkkkkkt^^^^"""""^^""""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""""""""""""""";bkkkkbf^"""""""""""""""""""""""^"qhkkkkt^^"""""""""""""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""""""""""""""":dbbbdd/""""""""""""""""""""""""""wbbbbbt^^"""""""""""""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""""""""""""""":xnuuun}IIII::""""""""""""""""""""jnnxxx1III;;:,""""""""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""""""""""""""",llllll[)]-+~>""""""""""""""""""",IllIIl])[-+<<,""""""""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""""""""""""""""llllll[([?+~<""""""""""""""""""",llllll])[-+<>,""""""""""""""""""""""""""
// """""""""""""""""""""""""""""""""""""""""""""""""""""""Illlll-{?+~<i""""""""""""""""""",llllll-}?+~<>,""""""""""""""""""""""""""

// Contract by @backseats_eth

// Audited by: @SuperShyGuy0

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

// Errors

error ExceedsMaxSupply();
error ClaimClosed();
error BuyClosed();
error NoContracts();
error WrongAmount();
error WrongETHAmount();

// Noun Cats Invisibles Interface

interface IInvisibles {
  function ownerOf(uint256 tokenId) external returns (address);
}

// The Early Birbs are a community-created CC0 collection by the Noun Cats commmunity. Birbs are free to mint as long as you hold an Invisible Noun Cat (which, for the time being, can still be minted at NounCats.com). Each Invisible entitles you to one Early Birb. Invisibles cannot be reused. Enjoy the Birbs and thank you to the community for creating this together!
contract TheEarlyBirbs is ERC721A, ERC2981, Ownable {

  // 5,000 Invisibles, Cats, and Birbs
  uint256 public constant MAX_SUPPLY = 5_000;

  // The price is 0.025 ETH
  uint256 public price = 0.025 ether;

  // The Early Birbs treasury wallet
  address public _withdrawAddress = 0x3d7f75ff0cf322D43e39868BA3Ef4D2742Cc0384;

  // The IPFS URI where our data can be found
  string public _baseTokenURI;

  // A mapping of Invisible IDs to whether they've been used to mint an Early Birb or not
  mapping(uint256 => bool) public _didInvisibleClaimBirb;

  // An enum and associated variable tracking the state of the mint
  enum MintState {
    CLOSED,
    CLAIM,
    BUY
  }

  MintState public _mintState;

  // Modifiers

  modifier ensureSupply(uint256 _amount){
    if (totalSupply() + _amount > MAX_SUPPLY) revert ExceedsMaxSupply();
    _;
  }

  modifier noContracts() {
    if (msg.sender != tx.origin) revert NoContracts();
    _;
  }

  modifier claimable() {
    if (_mintState != MintState.CLAIM) revert ClaimClosed();
    _;
  }

  modifier purchaseable() {
    if (_mintState != MintState.BUY) revert BuyClosed();
    _;
  }

  // Constructor

  constructor() ERC721A("The Early Birbs", "BIRB") {
    // Mint to Brandon Mighty, the inspiration for The Early Birbs
    _mint(0x66Df0A3C697F25134a73fd3030F2c3A9a6861BBC, 1);
    // Mint Love Birb to Elle, who made it
    _mint(0xaf81d5Cd82417Bd17F533CdF5443521F871729Dc, 1);

    // Burn two of Backseats' claims for the gifts above
    _didInvisibleClaimBirb[1] = true;
    _didInvisibleClaimBirb[33] = true;
  }

  // Claim and Mint

  /**
  @notice Hatches Early Birbs using the ID of the corresponding Invisible. Skips any IDs that have already been used
  */
  function hatchEarlyBirbs(uint256[] calldata _tokenIDs) external claimable() noContracts() {
    // Noun Cats Invisibles Contract: https://contractreader.io/address/0xb5942db8d5be776ce7585132616d3707f40d46e5
    IInvisibles invis = IInvisibles(0xB5942dB8d5bE776CE7585132616D3707f40D46e5);

    uint256 count;
    uint256 length = _tokenIDs.length;
    for (uint256 i; i < length;) {
      uint256 id = _tokenIDs[i];

      if (invis.ownerOf(id) == msg.sender && _didInvisibleClaimBirb[id] == false) {
        _didInvisibleClaimBirb[id] = true;
        unchecked { ++count; }
      }

      unchecked { ++i; }
    }

    if (totalSupply() + count > MAX_SUPPLY) revert ExceedsMaxSupply();

    _mint(msg.sender, count);
  }

  /**
  @notice Allows users to buy an Early Birb after the claiming window is over
  */
  function buyABirb(uint256 _amount) external payable noContracts() purchaseable() ensureSupply(_amount) {
    if (_amount > 20) revert WrongAmount();
    if (_amount * price != msg.value) revert WrongETHAmount();

    _mint(msg.sender, _amount);
  }

  // Setters

  /**
  @notice Sets the contract-wide royalty info
  */
  function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
      _setDefaultRoyalty(receiver, feeBasisPoints);
  }

  /**
  @notice Sets the baseURI for the collection
  */
  function setBaseURI(string calldata _baseURI) external onlyOwner {
    _baseTokenURI = _baseURI;
  }

  /**
  @notice Sets the withdraw address
  */
  function setWithdrawAddress(address _val) external onlyOwner {
    _withdrawAddress = _val;
  }

  /**
  @notice Sets the price
  // Important: Set new price in wei (i.e. 50000000000000000 for 0.05 ETH)
  */
  function setPrice(uint _newPrice) external onlyOwner {
    price = _newPrice;
  }

  /**
  @notice Sets the mint state for the contract
  */
  function setMintState(uint256 _status) external onlyOwner {
    require(_status <= uint256(MintState.BUY), "Bad status");
    _mintState = MintState(_status);
  }

  // View Functions

  /**
  @notice Overrides ERC721A's default starting token value of 0. Early Birbs IDs run 1-5,000
  */
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  /**
  @notice Checks if the Invisible ID was previously used to mint an Early Birb
  */
  function checkIfClaimed(uint256 _id) external view returns (bool) {
    return _didInvisibleClaimBirb[_id];
  }

  /**
  @notice Returns the baseURI of the collection
  */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /**
  @notice Boilerplate to support ERC721A and ERC2981
  */
  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // Withdraw

  function withdrawFunds() external onlyOwner {
    (bool sent, ) = payable(_withdrawAddress).call{value: address(this).balance}('');
    require(sent, "Withdraw failed");
  }

}
