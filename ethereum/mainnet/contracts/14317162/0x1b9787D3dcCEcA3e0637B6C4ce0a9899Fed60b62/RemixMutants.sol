// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title RemixMutants
 * @dev A gas-efficient ERC721 for the REMIX Mutants
 * @note Loosely based on Nuclear nerds ERC721 contract by @nftchance & @masonnft
 */

import "./AdminControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721OffChainEnumerable.sol";

contract RemixMutants is ERC721OffChainEnumerable, Pausable, ReentrancyGuard, AdminControl, Ownable {
  using Strings for uint256;

  uint256 public MAX_SUPPLY = 300;

  // ========== Immutable Variables ==========

  /// @notice Remix Contract Address
  address payable public immutable REMIX_CONTRACT_ADDRESS;
  /// @notice An address to withdraw balance to
  address payable public immutable PAYABLE_ADDRESS_1;
  /// @notice An address to send donations
  address payable public immutable DONATION_ADDRESS;

  // ========== Mutable Variables ==========

  string public baseURI;

  // Mint Windows
  enum MintWindowType {
    STAGE_1,
    STAGE_2,
    STAGE_3,
    STAGE_4,
    STAGE_5,
    ANY
  }

  mapping(MintWindowType => uint256) public stageStartTimes;

  mapping(address => uint256) public numberOfTokensMintedInAllowlistByAddress;

  bytes32 public allowlistMerkleTreeRoot;
  uint8 public allowlistWalletLimit = 1;
  uint256 public allowlistMintCostETH = 0;

  uint256 public generalMintCostETH = 0.01 ether;

  // Proxies
  mapping(address => bool) public projectProxy;

  // ========== Constructor ==========

  constructor(
    address payable _REMIX_CONTRACT_ADDRESS,
    address payable _DONATION_ADDRESS,
    address _payableAddress
  ) ERC721("REMIX! Mutants", "REMIX 2")
  {
    baseURI = "https://storageapi.fleek.co/apedao-bucket/remix-mutants/";
    REMIX_CONTRACT_ADDRESS = _REMIX_CONTRACT_ADDRESS;
    DONATION_ADDRESS = _DONATION_ADDRESS;

    PAYABLE_ADDRESS_1 = payable(_payableAddress);

    // Start with the current mint window as gold and pause sale
    _pause();
  }

  // ========== Minting ==========

  function mint(uint256 _quantity) public payable whenNotPaused nonReentrant {
    require(_quantity > 0, "Quantity must be greater than 0");
    require(isAllowlistStage() == false, "Allowlist is required for this mint window");
    require(hasRemix(), "You must be a Remix holder to mint");

    uint256 mintCost = calcluateMintCost(_quantity);

    internalMint(_msgSender(), _quantity);

    if (msg.value > mintCost) {
      DONATION_ADDRESS.call{value: msg.value - mintCost}("");
    }
  }

  /**
    * @notice Mints a token for the given address, if the address is on a allowlist.
   */
  function mintAllowlist(uint256 _quantity, MintWindowType stage, bytes32[] calldata proof) public payable whenNotPaused nonReentrant {
    require(_quantity > 0, "Quantity must be greater than 0");
    require(isAllowlistStage() == true, "Allowlist is not required for this mint window");
    require(block.timestamp >= stageStartTimes[stage], "Stage is not valid");

    string memory payload = string(abi.encodePacked(_msgSender()));
    require(_verify(_leaf(uint256(stage), payload), proof), "Invalid Merkle Tree proof supplied.");

    // Check Wallet Limit
    require(numberOfTokensMintedInAllowlistByAddress[msg.sender] + _quantity <= allowlistWalletLimit, "You have reached your wallet limit");

    uint256 mintCost = calcluateMintCost(_quantity);

    internalMint(_msgSender(), _quantity);

    if (msg.value > mintCost) {
      DONATION_ADDRESS.call{value: msg.value - mintCost}("");
    }

    numberOfTokensMintedInAllowlistByAddress[_msgSender()] += _quantity;
  }

  function calcluateMintCost(uint256 _quantity) internal view returns (uint256){
    uint256 mintPrice;

    if(isAllowlistStage()) {
      mintPrice = allowlistMintCostETH;
    } else {
      mintPrice = generalMintCostETH;
    }

    uint256 mintCost = mintPrice * _quantity;

    require(msg.value >= mintCost, "Insufficient ETH for minting");

    return mintCost;
  }

  function ownerMint(address _to) public onlyAdmin {
    internalMint(_to, 1);
  }

  function internalMint(address _to, uint256 _quantity) internal {
    uint256 totalSupply = _owners.length;
    require(totalSupply + _quantity <= MAX_SUPPLY, "Exceeds max supply.");

    for(uint i = 1; i <= _quantity; i++) {
        _mint(_to, totalSupply + i);
    }
  }

  function hasRemix() internal view returns (bool) {
    IERC721 remixContract = IERC721(REMIX_CONTRACT_ADDRESS);
    uint256 remixBalance = remixContract.balanceOf(msg.sender);

    return remixBalance > 0;
  }

  // @dev Any stage before the ANY stage is an allowlist stage
  function isAllowlistStage() internal view returns (bool) {
    return block.timestamp < stageStartTimes[MintWindowType.ANY];
  }

  // ========== Public Methods ==========

  function isRemixHolderRequired() public view returns (bool) {
    return !isAllowlistStage();
  }

  function getMintCostETH() public view returns (uint256) {
    if(isAllowlistStage()) {
      return allowlistMintCostETH;
    } else {
      return generalMintCostETH;
    }
  }

  function getWalletLimit() public view returns (uint16) {
    if(isAllowlistStage()) {
      return allowlistWalletLimit;
    } else {
      return 0;
    }
  }

  // ========== Admin ==========

  function setBaseURI(string memory _baseURI) public onlyAdmin {
    baseURI = _baseURI;
  }

  function setStageStartTimes(uint256[] calldata startTimes) public onlyAdmin {
    require(startTimes.length == 6, "Must supply 6 stage start times");
    require(startTimes[1] > startTimes[0], "Stage 2 must start after Stage 1");
    require(startTimes[2] > startTimes[1], "Stage 3 must start after Stage 2");
    require(startTimes[3] > startTimes[2], "Stage 4 must start after Stage 3");
    require(startTimes[4] > startTimes[3], "Stage 5 must start after Stage 4");
    require(startTimes[5] > startTimes[4], "Any Stage must start after Stage 5");

    stageStartTimes[MintWindowType.STAGE_1] = startTimes[0];
    stageStartTimes[MintWindowType.STAGE_2] = startTimes[1];
    stageStartTimes[MintWindowType.STAGE_3] = startTimes[2];
    stageStartTimes[MintWindowType.STAGE_4] = startTimes[3];
    stageStartTimes[MintWindowType.STAGE_5] = startTimes[4];
    stageStartTimes[MintWindowType.ANY] = startTimes[5];
  }

  function setAllowlistMintCostETH(uint256 _mintCost) public onlyAdmin {
    allowlistMintCostETH = _mintCost;
  }

  function setGeneralMintCostETH(uint256 _mintCost) public onlyAdmin {
    generalMintCostETH = _mintCost;
  }

  function setAllowlistMerkleTreeRoot(bytes32 _root) public onlyAdmin {
    allowlistMerkleTreeRoot = _root;
  }

  function withdraw() public onlyAdmin {
    PAYABLE_ADDRESS_1.call{value: address(this).balance}("");
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  function flipProxyState(address proxyAddress) public onlyAdmin {
    projectProxy[proxyAddress] = !projectProxy[proxyAddress];
  }

  // ========== MerkleTree Helpers ==========

  function _leaf(uint list, string memory payload) internal pure returns (bytes32) {
      return keccak256(abi.encodePacked(payload, list));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
      return MerkleProof.verify(proof, allowlistMerkleTreeRoot, leaf);
  }

  // ============ Overrides ========

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AdminControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 id) internal override(ERC721OffChainEnumerable) {
    super._beforeTokenTransfer(from, to, id);
  }

  function _mint(address account, uint256 id) internal override(ERC721) {
    super._mint(account, id);
  }

  function burn(uint256 tokenId) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
    _burn(tokenId);
  }

  function _burn(uint256 id) internal override(ERC721) {
    super._burn(id);
  }

  function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
    if(projectProxy[operator]) return true;
    return super.isApprovedForAll(_owner, operator);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId > 0 && _tokenId <= MAX_SUPPLY, "URI requested for invalid token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
  }
}
