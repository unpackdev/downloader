// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

contract Antipfp is ERC721, Ownable {
  constructor() ERC721("ANTIPFP", "PFP") {}

  /// @notice Custom Errors
  /// @dev attempted to set baseURI after already being set.
  error BaseUriAlreadySet();
  /// @dev attempted to mint more than allowed.
  error InvalidAmount();
  /// @dev message value is not price * num.
  error InvalidValue();
  /// @dev attempted ito mint more than the maximum supply.
  error MaxSupplyExceeded();
  /// @dev attempted action before provenance hash has been set.
  error ProvenanceNotSet();
  /// @dev attempted to set provenance hash after already being set.
  error ProvenanceAlreadySet();
  /// @dev attempted to ineteract with token that does not exist.
  error NonExistentToken();

  //mapping (uint256 => uint256) private _colors;
  bool private _isLive = false;
  uint256 maxSupply = 6969;
  uint256[6969] public _colors;
  uint256 public totalSupply = 0;

  string private _base = "data:application/json;base64,eyJuYW1lIjoiQU5USVBGUCIsICJkZXNjcmlwdGlvbiI6IkFOVElQRlAgTkZUIiwgImF0dHJpYnV0ZXMiOiBbIHsgInRyYWl0X3R5cGUiOiAiQ29sb3IiLCAidmFsdWUiOiAi";
  string[] private _encoded = [
    "Q2FsaWZvcm5pYSBHb2xkIn1dLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpT1RBd0lpQm9aV2xuYUhROUlqa3dNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Y21WamRDQjRQU0l3SWlCNVBTSXdJaUIzYVdSMGFEMGlPVEF3SWlCb1pXbG5hSFE5SWprd01DSWdabWxzYkQwaUkyWm1ZV1l6TmlJK1BDOXlaV04wUGp3dmMzWm5QZz09In0=",
    "Um95YWwgUHVycGxlIn1dLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpT1RBd0lpQm9aV2xuYUhROUlqa3dNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Y21WamRDQjRQU0l3SWlCNVBTSXdJaUIzYVdSMGFEMGlPVEF3SWlCb1pXbG5hSFE5SWprd01DSWdabWxzYkQwaUl6UXdNbUUyWkNJK1BDOXlaV04wUGp3dmMzWm5QZz09In0=",
    "Um95YWwgUmVkIn1dLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpT1RBd0lpQm9aV2xuYUhROUlqa3dNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Y21WamRDQjRQU0l3SWlCNVBTSXdJaUIzYVdSMGFEMGlPVEF3SWlCb1pXbG5hSFE5SWprd01DSWdabWxzYkQwaUkyVmxNREF3TUNJK1BDOXlaV04wUGp3dmMzWm5QZz09In0=",
    "QmVya2VsZXkgQmx1ZSJ9XSwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjNhV1IwYUQwaU9UQXdJaUJvWldsbmFIUTlJamt3TUNJZ2VHMXNibk05SW1oMGRIQTZMeTkzZDNjdWR6TXViM0puTHpJd01EQXZjM1puSWo0OGNtVmpkQ0I0UFNJd0lpQjVQU0l3SWlCM2FXUjBhRDBpT1RBd0lpQm9aV2xuYUhROUlqa3dNQ0lnWm1sc2JEMGlJekF3TXpNMk1pSStQQzl5WldOMFBqd3ZjM1puUGc9PSJ9",
    "RW1lcmFsZCBHcmVlbiJ9XSwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjNhV1IwYUQwaU9UQXdJaUJvWldsbmFIUTlJamt3TUNJZ2VHMXNibk05SW1oMGRIQTZMeTkzZDNjdWR6TXViM0puTHpJd01EQXZjM1puSWo0OGNtVmpkQ0I0UFNJd0lpQjVQU0l3SWlCM2FXUjBhRDBpT1RBd0lpQm9aV2xuYUhROUlqa3dNQ0lnWm1sc2JEMGlJekF4TmpReE5TSStQQzl5WldOMFBqd3ZjM1puUGc9PSJ9",
    "UmliYm9uIFBpbmsifV0sICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlPVEF3SWlCb1pXbG5hSFE5SWprd01DSWdlRzFzYm5NOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6SXdNREF2YzNabklqNDhjbVZqZENCNFBTSXdJaUI1UFNJd0lpQjNhV1IwYUQwaU9UQXdJaUJvWldsbmFIUTlJamt3TUNJZ1ptbHNiRDBpSTJabU5HTmtNaUkrUEM5eVpXTjBQand2YzNablBnPT0ifQ==",
    "QnJvd24ifV0sICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlPVEF3SWlCb1pXbG5hSFE5SWprd01DSWdlRzFzYm5NOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6SXdNREF2YzNabklqNDhjbVZqZENCNFBTSXdJaUI1UFNJd0lpQjNhV1IwYUQwaU9UQXdJaUJvWldsbmFIUTlJamt3TUNJZ1ptbHNiRDBpSXpka05UWTBOeUkrUEM5eVpXTjBQand2YzNablBnPT0ifQ==",
    "WWVsbG93In1dLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpT1RBd0lpQm9aV2xuYUhROUlqa3dNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Y21WamRDQjRQU0l3SWlCNVBTSXdJaUIzYVdSMGFEMGlPVEF3SWlCb1pXbG5hSFE5SWprd01DSWdabWxzYkQwaUkyWmxabVUyTnlJK1BDOXlaV04wUGp3dmMzWm5QZz09In0=",
    "QmxhY2sifV0sICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlPVEF3SWlCb1pXbG5hSFE5SWprd01DSWdlRzFzYm5NOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6SXdNREF2YzNabklqNDhjbVZqZENCNFBTSXdJaUI1UFNJd0lpQjNhV1IwYUQwaU9UQXdJaUJvWldsbmFIUTlJamt3TUNJZ1ptbHNiRDBpSXpBd01EQXdNQ0krUEM5eVpXTjBQand2YzNablBnPT0ifQ==",
    "T3JhbmdlIn1dLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpT1RBd0lpQm9aV2xuYUhROUlqa3dNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Y21WamRDQjRQU0l3SWlCNVBTSXdJaUIzYVdSMGFEMGlPVEF3SWlCb1pXbG5hSFE5SWprd01DSWdabWxzYkQwaUkyVmhOemt3TUNJK1BDOXlaV04wUGp3dmMzWm5QZz09In0=",
    "VHJ1c3RtZSBCbHVlIn1dLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpT1RBd0lpQm9aV2xuYUhROUlqa3dNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Y21WamRDQjRQU0l3SWlCNVBTSXdJaUIzYVdSMGFEMGlPVEF3SWlCb1pXbG5hSFE5SWprd01DSWdabWxzYkQwaUl6QXdZV0ZtT1NJK1BDOXlaV04wUGp3dmMzWm5QZz09In0="
 ];

  function mint(uint256 num) public payable {
    if (num < 1 || num > 10) revert InvalidAmount();
    if (.069 ether * num < msg.value) revert InvalidValue();
    if (totalSupply + num > maxSupply) revert MaxSupplyExceeded();
    if (_isLive == false) revert ("Sale is not live");

    uint256 supply = totalSupply;

    totalSupply += num;
    for (uint256 i = 0; i < num; i++) {
      _colors[supply + i] = _randomNum(block.difficulty, supply + i);
      _safeMint(msg.sender, supply + i);
    }
    delete supply;
  }

  function _randomNum(uint256 _seed, uint256 _salt) private view returns(uint256) {
    uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % maxSupply;
    if (num < 42) {
      return 0;
    } else if (num < 111) {
      return 1;
    } else if (num < 199) {
      return 2;
    } else if (num < 399) {
      return 3;
    } else if (num < 819) {
      return 4;
    } else if (num < 1319) {
      return 5;
    } else if (num < 1819) {
      return 6;
    } else if (num < 2569) {
      return 7;
    } else if (num < 3469) {
      return 8;
    } else if (num < 4469) {
      return 9;
    } else {
      return 10;
    }
  }

  function _getEncoded(uint256 index) private view returns(string memory) {
    return string(abi.encodePacked(_base, _encoded[index]));
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _tokenId <= totalSupply,
      "ERC721Metadata: URI query for nonexistent token"
    );

    return _getEncoded(_colors[_tokenId]);
  }

  function withdraw() public payable onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function toggleSale() public onlyOwner {
    _isLive = !_isLive;
  }

  function contractURI() public pure returns (string memory) {
    return "https://antipfp.com/contract-metadata.json";
  }
}