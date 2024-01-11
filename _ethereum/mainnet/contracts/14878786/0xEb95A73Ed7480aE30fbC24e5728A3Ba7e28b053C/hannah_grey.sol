// SPDX-License-Identifier: UNLICENSED

//                       █░█ ▄▀█ █▄░█ █▄░█ ▄▀█ █░█   █▀▀ █▀█ █▀▀ █▄█   █░█ █▀▀ █▄░█ ▀█▀ █░█ █▀█ █▀▀ █▀
//                       █▀█ █▀█ █░▀█ █░▀█ █▀█ █▀█   █▄█ █▀▄ ██▄ ░█░   ▀▄▀ ██▄ █░▀█ ░█░ █▄█ █▀▄ ██▄ ▄█
//
//                                         ███████╗██╗░░░██╗███╗░░██╗██████╗░  ██╗
//                                         ██╔════╝██║░░░██║████╗░██║██╔══██╗  ██║
//                                         █████╗░░██║░░░██║██╔██╗██║██║░░██║  ██║
//                                         ██╔══╝░░██║░░░██║██║╚████║██║░░██║  ██║
//                                         ██║░░░░░╚██████╔╝██║░╚███║██████╔╝  ██║
//╚                                        ═╝░░░░░░╚═════╝░╚═╝░░╚══╝╚═════╝░  ╚═╝
//
// ███╗   ███╗ █████╗ ██████╗ ███████╗    ██╗    ██╗██╗████████╗██╗  ██╗    ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝    ██║    ██║██║╚══██╔══╝██║  ██║    ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗      ██║ █╗ ██║██║   ██║   ███████║    ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝      ██║███╗██║██║   ██║   ██╔══██║    ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗    ╚███╔███╔╝██║   ██║   ██║  ██║    ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝     ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.13;

import "./AccessControl.sol";
import "./EIP712Common.sol";
import "./Toggleable.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

error ExceedsMaxSupply();
error ExceedsMaxPerWallet();

contract HannahGrey is ERC721A, Ownable, Toggleable, AccessControl, EIP712Common{
  uint256 public MAX_SUPPLY;
  uint256 public MAX_PER_WALLET;

  constructor (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _customBaseURI,
    uint256 _tokensForSale
  ) ERC721A(_tokenName, _tokenSymbol) {
    customBaseURI = _customBaseURI;

    MAX_SUPPLY = _tokensForSale;
    MAX_PER_WALLET = 1;
  }

  function whitelistMint(uint256 _count, bytes calldata _signature) external requiresWhitelist(_signature) noContracts requireActiveWhitelist{
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
    if(_numberMinted(msg.sender) + _count > MAX_PER_WALLET) revert ExceedsMaxPerWallet();

    _mint(msg.sender, _count);
  }

  function ownerMint(uint256 _count, address recipient) external onlyOwner() {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();

    _mint(recipient, _count);
  }

  function checkWhitelist(bytes calldata _signature) public view requiresWhitelist(_signature) returns (bool) {
    return true;
  }

  function allowedMintCount(address _minter) public view returns (uint256) {
    return MAX_PER_WALLET - _numberMinted(_minter);
  }

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
    MAX_PER_WALLET = _maxPerWallet;
  }

  string private customBaseURI;

  function baseTokenURI() public view returns (string memory) {
    return customBaseURI;
  }

  function setBaseURI(string memory _customBaseURI) external onlyOwner {
    customBaseURI = _customBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }
}
