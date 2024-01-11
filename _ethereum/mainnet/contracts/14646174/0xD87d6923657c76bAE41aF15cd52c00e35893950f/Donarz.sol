// SPDX-License-Identifier: MIT
/// @title Donarz
/**
*       ,---,
*     ,---.'|   ,---.        ,---,              __  ,-.       ,----,
*     |   | :  '   ,'\   ,-+-. /  |           ,' ,'/ /|     .'   .`|
*     |   | | /   /   | ,--.'|'   |  ,--.--.  '  | |' |  .'   .'  .'
*   ,--.__| |.   ; ,. :|   |  ,"' | /       \ |  |   ,',---, '   ./
*  /   ,'   |'   | |: :|   | /  | |.--.  .-. |'  :  /  ;   | .'  /
* .   '  /  |'   | .; :|   | |  | | \__\/: . .|  | '   `---' /  ;--,
* '   ; |:  ||   :    ||   | |  |/  ," .--.; |;  : |     /  /  / .`|
* |   | '/  ' \   \  / |   | |--'  /  /  ,.  ||  , ;   ./__;     .'
* |   :    :|  `----'  |   |/     ;  :   .'   \---'    ;   |  .'
*  \   \  /            '---'      |  ,     .-./        `---'
*   `----'                         `--`---'
*/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";

contract DonarzToken is ERC721A, Ownable, ReentrancyGuard {
  uint public constant PRICE = 0.06 ether;
  uint public constant PRIVATE_SALE_PRICE = 0.045 ether;
  uint public constant MAX_SUPPLY = 7000;
  uint public constant PRIVATE_SALE_MAX_MINT_AMOUNT = 3;
  uint public constant PRIVATE_SALE_OG_MAX_MINT_AMOUNT = 4;
  uint public constant MAX_MINT_AMOUNT = 10;  
  uint public constant MAX_PUBLIC_MINT_AMOUNT = 1500;

  bool public isPublicSaleActive = false;
  bool public isPrivateSaleActive = false;

  bytes32 private ogMerkleRoot;
  bytes32 private whitelistMerkleRoot;

  struct Whitelist {
    address addr;
    uint qtyMinted;
  }

  mapping(address => Whitelist) private oglist;
  address[] private oglistAddr;

  mapping(address => Whitelist) private whitelist;
  address[] private whitelistAddr;

  string private _contractURI;
  string private baseURI;

  constructor(
    bytes32 _ogMerkleRoot,
    bytes32 _whitelistMerkleRoot,
    string memory _initBaseURI,
    string memory _initContractURI) ERC721A('Donarz', 'DONARZ') {
    ogMerkleRoot = _ogMerkleRoot;
    whitelistMerkleRoot = _whitelistMerkleRoot;
    baseURI = _initBaseURI;
    _contractURI = _initContractURI;
  }

  /// Minting Region
  /// @notice Pause sale if active, make active if paused.
  function togglePublicSaleState() public onlyOwner {
    isPublicSaleActive = !isPublicSaleActive;
  }

  /// @notice Pause private sale if active, make active if paused.
  function togglePrivateSaleState() public onlyOwner {
    isPrivateSaleActive = !isPrivateSaleActive;
  }

  /// @notice returns whether public mint is sold out or not
  function isPublicMintSoldOut() view public returns (bool) {
    return totalSupply() >= MAX_PUBLIC_MINT_AMOUNT;
  }

  /**
  * @notice Treasury mints by owner to be used for promotions and awards.
  * @param quantity the quanity of Donarz NFTs to mint.
  */
  function mintTreasury(uint quantity) public onlyOwner {
    uint currentTotalSupply = totalSupply();
    uint totalSupplyAfterMint = currentTotalSupply + quantity;

    /// @notice Treasure mints can't be more than max supply
    require(totalSupplyAfterMint <= MAX_SUPPLY, "DonarzToken should not exceed total supply");
    _safeMint(msg.sender, quantity);
  }

  function presaleMint(uint256 quantity, bool isOg, bytes32[] calldata proof) external payable {
    require(isPrivateSaleActive, "Private sale must be active");

    if (isOg) {
      uint qtyMintedByOglistAddr = getOglistAddressMinedQty(msg.sender);
      require(isOglisted(proof), "Sender is not an OG and can't mint During private sale");
      require(quantity + qtyMintedByOglistAddr <= PRIVATE_SALE_OG_MAX_MINT_AMOUNT, "Og can only mine PRIVATE_SALE_OG_MAX_MINT_AMOUNT amount during presale");
      if (qtyMintedByOglistAddr < 1) {
        require(msg.value == (quantity - 1) * PRIVATE_SALE_PRICE, "DonarzToken Not enough value sent");
      } else {
        require(msg.value > 0 && msg.value == quantity * PRIVATE_SALE_PRICE, "DonarzToken Not enough value sent");
      }
    } else {
      uint qtyMintedByWhitelistAddr = getWhiteListAddressMintedQty(msg.sender);
      require(isWhitelisted(proof), "Sender is not in WL and can't mint during private sale");
      require(quantity + qtyMintedByWhitelistAddr <= PRIVATE_SALE_MAX_MINT_AMOUNT, "Whitelist can only mine PRIVATE_SALE_MAX_MINT_AMOUNT amount during presale");
      require(msg.value > 0 && msg.value == quantity * PRIVATE_SALE_PRICE, "DonarzToken Not enough value sent");
    }

    uint currentTotalSupply = totalSupply();
    require(currentTotalSupply + quantity <= MAX_PUBLIC_MINT_AMOUNT, "DonarzToken Not enough public mints remaining");

    _safeMint(msg.sender, quantity);

    if (isOg) {
      oglist[msg.sender].qtyMinted = quantity + getOglistAddressMinedQty(msg.sender);
    } else {
      whitelist[msg.sender].qtyMinted = quantity + getWhiteListAddressMintedQty(msg.sender);
    }
  }

  function mint(uint256 quantity) external payable {
    require(isPublicSaleActive, "Sale must be active");
    uint currentTotalSupply = totalSupply();
    require(currentTotalSupply + quantity <= MAX_PUBLIC_MINT_AMOUNT, "DonarzToken Not enough public mints remaining");
    require(quantity <= MAX_MINT_AMOUNT, 'DonarzToken mint per txn amount exceeds maximum');
    require(msg.value > 0 && msg.value == quantity * PRICE, "DonarzToken Not enough value sent");
    _safeMint(msg.sender, quantity);
  }

  /// Contract Metadata Region
  /**
  * @notice sets the base URI
  * @param _newBaseURI is the address of the ipfs base uri
  */
  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function _baseURI() internal override view returns (string memory){
    return baseURI;
  }

  /**
  * @notice sets the contract uri
  * @param _newContractURI uri to the contract ipfs address
  */
  function setContractURI(string memory _newContractURI) external onlyOwner {
    _contractURI = _newContractURI;
  }
  
  function contractURI() external view returns (string memory){
    return _contractURI;
  }

  /// Private Sale List Region
  function isOglisted(bytes32[] calldata ogProof) public view returns (bool isWhiteListed) {
    if (MerkleProof.verify(ogProof, ogMerkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
      return true;
    } else {
      return false;
    }
  }

  function isWhitelisted(bytes32[] calldata wlProof) public view returns (bool isWhiteListed) {
    if (MerkleProof.verify(wlProof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
      return true;
    } else {
      return false;
    }
  }

  /**
  * @notice count of how much a specific address minted if they are in the whitelist
  * @param _address to check against list
  */
  function getWhiteListAddressMintedQty(address _address) view public returns (uint) {
    return (whitelist[_address].qtyMinted);
  }

  /**
  * @notice count of how much a specific address minted if they are in the oglist
  * @param _address to check against list
  */
  function getOglistAddressMinedQty(address _address) view public returns (uint) {
    return (oglist[_address].qtyMinted);
  }

  /// Merkle Region
  /// @notice sets the whitelist merkle root
  function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    whitelistMerkleRoot = _merkleRoot;
  }

  /// @notice sets the oglist merkle root
  function setOglistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    ogMerkleRoot = _merkleRoot;
  }

  /// @notice Sends balance of this contract to owner
  function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      require(balance > 0, "No balance to withdraw");

      (bool success, ) = payable(msg.sender).call{value: balance}("");
      require(success, "Failed to withdraw payment");
  }
}