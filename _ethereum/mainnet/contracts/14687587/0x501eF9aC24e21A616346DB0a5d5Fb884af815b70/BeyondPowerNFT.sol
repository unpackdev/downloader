//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "Pausable.sol";
import "AccessControl.sol";
import "ERC2981.sol";

/**
* @title BeyondPowerNFT contract
* @author beyondpower.dev
*/
contract BeyondPowerNFT is ERC721A, Ownable, AccessControl, ERC2981, Pausable {
  // Create a new role identifier for the minter role
  bytes32 private constant MINTER_ROLE             = keccak256("MINTER_ROLE");
  //max supply
  uint256 private constant MAX_SUPPLY              = 5000;
  //NFT Mint Price
  uint256 private mint_price                       = 0.05 ether;
  //Max Mint Per address
  uint8   private max_mint_per_owner               = 7;
  //Tracks if the contract is in presale mode
  bool    private inPreSale    = true;
  //BaseURI
  string  private baseTokenURI = '';
  //ContractURI
  string  private contractURL  = '';
  //Royalty Address
  address private royaltyAddress = 0x40d0B1D389eA61d76ABd8Da86d42796aFBB4E437;
  //Royalty Fee
  uint96  private royaltyFee     = 750;
  //Owners wallet
  address private mintWallet;

  //Function Modifier for ensuring a whitelisted minter has the MINTER_ROLE
  modifier onlyMinter {
      if (inPreSale) {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a whitelisted minter");
      }
      _;
   }

   /** @dev BeyondPowerNFT Contract constructor
     * @param baseURI baseURI of contract.
     * @param contractURI contractURI of contract.
     */
  constructor(string memory baseURI, string memory contractURI) ERC721A("BeyondPower", "BP") {
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(MINTER_ROLE, msg.sender);
      setBaseURI(baseURI);
      setContractURI(contractURI);
      _setDefaultRoyalty(royaltyAddress, royaltyFee);
      mintWallet = owner();
      pause();
  }

  /** @dev mint function
    * @param quantity the number of NFTs to mint.
    */
  function mint(uint256 quantity) external payable onlyMinter whenNotPaused {
      require(msg.value >= mint_price * quantity, "Not enough ETH sent, check the mint price");
      require(_totalMinted() + quantity < MAX_SUPPLY, "BeyondPower NFT Collection is sold out");
      require(_numberMinted(msg.sender) < max_mint_per_owner, "Maximum number of mints exceeded");

      payable(mintWallet).transfer(msg.value);
      _safeMint(msg.sender, quantity);
  }

  /** @dev returns the total number of NFT's minted
    * @return totalMinted the number of NFT's minted so far
    */
  function totalMinted() public view returns (uint256) {
      return _totalMinted();
  }

  /** @dev checks whether the contract is currently in presale
    * @return inPreSale if in presale
    */
  function getPreSale() public view returns (bool) {
      return inPreSale;
  }

  /** @dev returns the contractURI
    * @return contractURL
    */
  function contractURI() public view returns (string memory) {
        return contractURL;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl, ERC2981) returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseTokenURI;
  }

  /**
    onlyOwner functions start here
  **/
  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
      baseTokenURI = _baseTokenURI;
  }

  function setContractURI(string memory _contractURI) public onlyOwner {
      contractURL = _contractURI;
  }

  function withdraw() public onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
  }

  function mintToOwner(uint256 quantity) public onlyOwner {
      _safeMint(msg.sender, quantity);
  }

  function mintToAddress(address addr, uint256 quantity) public onlyOwner {
      _safeMint(addr, quantity);
  }

  function reserveNFTs(uint256 quantity) public onlyOwner {
      _safeMint(msg.sender, quantity);
  }

  function setPreSale(bool state) public onlyOwner {
      inPreSale = state;
  }

  function addMinter(address minter) public onlyOwner {
      _grantRole(MINTER_ROLE, minter);
  }

  function removeMinter(address minter) public onlyOwner {
      _revokeRole(MINTER_ROLE, minter);
  }

  function addMinters(address[] calldata addresses) public onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
        addMinter(addresses[i]);
      }
  }

  function removeMinters(address[] calldata addresses) public onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
        removeMinter(addresses[i]);
      }
  }

  function tokenOwner(uint256 tokenId) public onlyOwner view returns (address, uint64) {
        TokenOwnership memory ownership = ownershipOf(tokenId);
        return (ownership.addr, ownership.startTimestamp);
  }

  function setMintPrice(uint256 _mint_price) public onlyOwner {
      mint_price = _mint_price;
  }

  function setMaxMintPerOwner(uint8 _max_mint) public onlyOwner {
      max_mint_per_owner = _max_mint;
  }

  function setRoyaltyAddress(address royalty_address) public onlyOwner {
     royaltyAddress = royalty_address;
  }

  function setRoyaltyFee(uint96 fee) public onlyOwner {
     royaltyFee = fee;
  }

  function setMintWallet(address addr) public onlyOwner {
      mintWallet = addr;
  }

  function pause() public onlyOwner {
      _pause();
  }

  function unpause() public onlyOwner {
      _unpause();
  }

  /**
    onlyOwner functions end here
  **/

}
