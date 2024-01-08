// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";

interface IMagic {
  function abrakadabra(uint256[] calldata tokenIds) external;
}

/*
      ___           ___           ___
     /\  \         /\  \         /\  \
    /26\  \       /20\  \       /13\  \
   /:/\ \  \     /:/\ \  \     /:/\ \  \
  _\:\~\ \  \   _\:\~\ \  \   _\:\~\ \  \
 /\ \:\ \ \__\ /\ \:\ \ \__\ /\ \:\ \ \__\
 \:\ \:\ \/__/ \:\ \:\ \/__/ \:\ \:\ \/__/
  \:\ \:\__\    \:\ \:\__\    \:\ \:\__\
   \:\/:/  /     \:\/:/  /     \:\/:/  /
    \26/  /       \09/  /       \15/  /
     \/__/         \/__/         \/__/
          Secret Scroll Society
*/
contract SecretScrollSociety is ERC721Enumerable, AccessControl, Pausable, Ownable {
  // State 22
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  uint256 public MAX_NFT_SUPPLY = 10000;

  uint256 public nftPrice = 50000000000000000;
  uint8 public maxPerMint = 20;
  uint8 public maxPerAccount = 200;
  uint8 public maxFreeMint = 1;
  uint8 public nftReserve = 200;

  string public provenance = "";

  bool public saleIsActive = false;
  bool public freeMintActive = false;

  string private _tokenBaseURI = "";
  string private _contractURI = "";

  address public treasury;
  IMagic internal magic;

  mapping (address => bool) private _whiteList;
  mapping (address => bool) private _freeMintList;
  mapping (address => uint256) private _freeMintClaimed;

  event Whitelisted(address indexed _address, bool isWhitelisted);
  event ClaimedFreeMint(address indexed _address);

  constructor(address _treasury, address[] memory managers)
    ERC721("Secret Scroll Society", "SSS") {
    treasury = _treasury;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
    _setRoleAdmin(MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _pause();

    for (uint8 i = 0; i < managers.length; i++) {
      _setupRole(MANAGER_ROLE, managers[i]);
    }
  }

  // Modifiers 23

  modifier saleIsOpen() {
    require(totalSupply() <= MAX_NFT_SUPPLY, "Sale over");
    _;
  }

  // Minting & Reserves 8

  function mintNFT(uint _numberOfTokens) public payable saleIsOpen {
    require(!isContract(msg.sender), "SSS: Caller cannot be contract");
    require(saleIsActive || whitelisted(msg.sender), "SSS: Sale not active");
    require(_numberOfTokens > 0 && _numberOfTokens <= maxPerMint, "SSS: Over limit");
    require(msg.value >= nftPrice * _numberOfTokens, "SSS: Not enough eth");
    require(balanceOf(msg.sender) + _numberOfTokens <= maxPerAccount, "SSS: Limit reached");
    require(totalSupply() + _numberOfTokens <= MAX_NFT_SUPPLY, "SSS: Not enough supply");

    uint256[] memory tokensMinted = new uint256[](_numberOfTokens);

    for(uint i = 0; i < _numberOfTokens; i++) {
      uint mintIndex = totalSupply();
      tokensMinted[i] = mintIndex;
      _safeMint(msg.sender, mintIndex);
    }

    magic.abrakadabra(tokensMinted);
  }

  function freeMintNFT() public payable saleIsOpen {
    require(freeMintActive, "SSS: Free minting not active");
    require(_freeMintList[msg.sender], "SSS: Not on list");
    require(_freeMintClaimed[msg.sender] + 1 <= maxFreeMint, "SSS: Nice try");

    _freeMintClaimed[msg.sender] += 1;

    uint256 mintIndex = totalSupply();

    _safeMint(msg.sender, mintIndex);

    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = mintIndex;

    magic.abrakadabra(tokenIds);

    emit ClaimedFreeMint(msg.sender);
  }

  function reserve(address _to, uint8 _reserveAmount) public onlyRole(MANAGER_ROLE) saleIsOpen {
    require(_reserveAmount > 0, "SSS: Reserve amount 0");
    require(_reserveAmount <= nftReserve, "SSS: Not enough reserve");
    require(totalSupply() + _reserveAmount <= MAX_NFT_SUPPLY, "SSS: Not enough supply");

    uint supply = totalSupply();

    uint256[] memory tokensMinted = new uint256[](_reserveAmount);

    nftReserve = nftReserve - _reserveAmount;

    for(uint i = 0; i < _reserveAmount; i++) {
      tokensMinted[i] = supply + i;
      _safeMint(_to, supply + i);
    }

    magic.abrakadabra(tokensMinted);
  }

  function toggleSale() public onlyRole(MANAGER_ROLE) {
    saleIsActive = !saleIsActive;
  }

  // Whitelist & Presale 7

  function togglePresale() public onlyRole(MANAGER_ROLE) {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function toggleFreeMint() public onlyRole(MANAGER_ROLE) {
    freeMintActive = !freeMintActive;
  }

  function whitelisted(address _address) public view returns (bool) {
    if (paused()) {
      return false;
    }
    return _whiteList[_address];
  }

  function checkIfOnFreeList(address _address) external view returns (bool) {
    return _freeMintList[_address];
  }

  function addToWhitelist(address[] calldata _addresses) external onlyRole(MANAGER_ROLE) {
    for (uint i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0), "SSS: Empty address");
      require(!_whiteList[_addresses[i]], "SSS: Already added");

      _whiteList[_addresses[i]] = true;
      emit Whitelisted(_addresses[i], true);
    }
  }

  function removeFromWhitelist(address[] calldata _addresses) external onlyRole(MANAGER_ROLE) {
    for(uint i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0), "SSS: Empty address");

      _whiteList[_addresses[i]] = false;
      emit Whitelisted(_addresses[i], false);
    }
  }

  function addToFreeMint(address[] calldata _addresses) external onlyRole(MANAGER_ROLE) {
    for (uint i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0), "SSS: Empty address");

      _freeMintList[_addresses[i]] = true;
      _freeMintClaimed[_addresses[i]] > 0 ? _freeMintClaimed[_addresses[i]] : 0;
    }
  }

  function removeFromFreeMint(address[] calldata _addresses) external onlyRole(MANAGER_ROLE) {
    for (uint i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0), "SSS: Empty address");

      _freeMintList[_addresses[i]] = false;
    }
  }

  // Utility 26

  function burnTheRest() external onlyOwner {
    MAX_NFT_SUPPLY = totalSupply();
  }

  // Send ETH to partner treasury / payment splitter 21
  function withdraw() external onlyRole(MANAGER_ROLE) {
    payable(treasury).transfer(address(this).balance);
  }

  function setMagicAddress(address _addy) public onlyOwner {
    magic = IMagic(_addy);
  }

  function setMintPrice(uint256 mintPrice) public onlyRole(MANAGER_ROLE) {
    nftPrice = mintPrice;
  }

  function setMaxPerMint(uint8 _maxPerMint) public onlyRole(MANAGER_ROLE) {
    maxPerMint = _maxPerMint;
  }

  function setMaxPerAccount(uint8 _maxPerAccount) public onlyRole(MANAGER_ROLE) {
    maxPerAccount = _maxPerAccount;
  }

  function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
    provenance = _provenanceHash;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _tokenBaseURI = baseURI;
  }

  function setContractURI(string memory contractURI_) public onlyOwner {
    _contractURI = contractURI_;
  }

  function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function contractURI() public view returns (string memory) {
      return _contractURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _tokenBaseURI;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
  // 21
}
