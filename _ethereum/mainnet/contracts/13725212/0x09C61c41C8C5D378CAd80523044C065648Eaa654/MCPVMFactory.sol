// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

interface IReverseResolver {
  function claim(address owner) external returns (bytes32);
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @title MoonCatPop Vending Machine Factory
 * @dev ERC721 representing the ability to mint 100 cans of MoonCatPop of a specific flavor.
 */
contract MoonCatPopVendingMachineFactory is ERC721Enumerable, Ownable, Pausable {
  using Strings for uint256;
  string public baseURI;

  /* External Contracts */
  address constant MoonCatAcclimator = 0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69;

  /* Remittance */
  address[2] public beneficiaries;

  /* Structs */
  struct WornAccessory {
      uint232 accessoryId;
      uint8 paletteIndex;
      uint16 zIndex;
  }

  struct VendingMachine {
      uint16 moonCatTokenId;
      uint8 color;
      uint8 textcolor;
      uint8 textshadow;
      uint8 scale;
      uint8 gradient;
      uint8 pattern;
      string flavor;
  }

  struct MintData {
      VendingMachine machine;
      uint256 canMintBlockOffset;
      WornAccessory[] accessories;
  }

  /* State */
  mapping (uint256 => uint256) moonCatToVendingMachine; // MoonCat Rescue Order -> Vending Machine token ID (plus nonce)
  mapping (uint256 => uint256) public vendingMachineCanMintStart; // Vending Machine token ID -> Block height
  uint256 public MaxVendingMachines = 256;
  VendingMachine[] public moonCatVendingMachines; // Vending machine token ID -> Vending Machine metadata
  mapping(uint256 => WornAccessory[]) wornAccessories; // MoonCat Rescue Order -> Accessories worn in can graphic

  /* Events */
  event BaseURISet(string baseURI);

  /**
   * @dev Deploy factory contract.
   */
  constructor(address[2] memory _beneficiaries) ERC721("MoonCatPop Vending Machines", "MCPVM") {
    beneficiaries = _beneficiaries;
    _pause();

    // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
    IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148)
      .claim(msg.sender);
  }

  /**
   * @dev Pause the contract.
   * Prevent minting and transferring of tokens
   */
  function paws() public onlyOwner {
      _pause();
  }

  /**
   * @dev Unpause the contract.
   * Allow minting and transferring of tokens
   */
  function unpaws() public onlyOwner {
      _unpause();
  }

  /**
   * @dev Finish minting and seal the collection.
   */
  function endMinting() public onlyOwner {
      MaxVendingMachines = totalSupply();
  }

  /**
   * @dev Get the current base URI for token metadata.
   */
  function _baseURI() internal view override returns (string memory) {
      return baseURI;
  }

  /**
   * @dev Update the base URI for token metadata.
   */
  function setBaseURI(string memory _newbaseURI) public onlyOwner {
    baseURI = _newbaseURI;
    emit BaseURISet(_newbaseURI);
  }

  /**
   * @dev Rescue ERC20 assets sent directly to this contract.
   */
  function withdrawForeignERC20(address tokenContract) public onlyOwner {
    IERC20 token = IERC20(tokenContract);
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  /**
   * @dev Rescue ERC721 assets sent directly to this contract.
   */
  function withdrawForeignERC721(address tokenContract, uint256 tokenId) public onlyOwner {
    IERC721(tokenContract).safeTransferFrom(address(this), owner(), tokenId);
  }

  /**
   * @dev Create a new Vending Machine token.
   */
  function mintVendingMachine(MintData calldata mintData)
    public
    onlyOwner
  {
    require( totalSupply() < MaxVendingMachines, "Vending Machine limit exceeded");
    require( moonCatToVendingMachine[mintData.machine.moonCatTokenId] == 0, "Duplicate MoonCat");

    uint256 tokenId = totalSupply();
    address moonCatOwner = IERC721(MoonCatAcclimator).ownerOf(mintData.machine.moonCatTokenId);
    _safeMint(moonCatOwner, tokenId);

    for (uint256 i = 0; i < mintData.accessories.length; i++){
      wornAccessories[tokenId].push(mintData.accessories[i]);
    }

    moonCatVendingMachines.push(mintData.machine);
    vendingMachineCanMintStart[tokenId] = block.number + mintData.canMintBlockOffset;
    moonCatToVendingMachine[mintData.machine.moonCatTokenId] = tokenId + 10;
  }

  /**
   * @dev Create multiple Vending Machine tokens at once.
   */
  function batchMint(MintData[] calldata batch) public onlyOwner {
      for (uint i = 0; i < batch.length; i++) {
          mintVendingMachine(batch[i]);
      }
  }

  /**
   * @dev Check if a given Vending Machine token exists or not.
   */
  function moonCatVendingMachineExists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  /**
   * @dev What Vending Machine has the specified MoonCat as a spokes-cat?
   */
  function vendingMachineForMoonCat(uint256 _acclimatedMoonCatTokenId) public view returns (uint256) {
    require(moonCatToVendingMachine[_acclimatedMoonCatTokenId] > 0, "No Machine");
    return moonCatToVendingMachine[_acclimatedMoonCatTokenId] - 10;
  }

  /**
   * @dev See {ERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(
      baseURI, _tokenId.toString(), '.json'
    )) : "";
  }

  /**
   * @dev See {ERC721-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Get metadata about a specific Vending Machine and the spokes-cat on it.
   */
  function getVendingMachineMetadata(uint256 _vendingMachineId)
    public
    view
    returns (VendingMachine memory vendingMachine, WornAccessory[] memory accessories)
  {
    return (moonCatVendingMachines[_vendingMachineId], wornAccessories[_vendingMachineId]);
  }

  /**
   * @dev Update a beneficiary of the contract.
   */
  function setBeneficiary(address _beneficiary, uint256 _index) public {
    require(_msgSender() == beneficiaries[_index], "Forbidden");
    beneficiaries[_index] = _beneficiary;
  }

  /**
   * @dev Default funds-receiving method.
   */
  receive() external payable {
    splitFees();
  }

  /**
   * @dev Manually trigger a dispersement of whatever funds are in the contract.
   */
  function withdraw() public {
    splitFees();
  }

  bool firstEntry = true;

  /**
   * @dev Send whatever funds are currently in the account to the beneficiaries, in a 50/50 split.
   */
  function splitFees() internal {
      require(firstEntry, "Reentrant");
      firstEntry = false;
      payable(beneficiaries[0]).transfer(address(this).balance * 50 / 100);
      payable(beneficiaries[1]).transfer(address(this).balance);
      firstEntry = true;
  }

}
