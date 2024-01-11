interface IEthTerrestrials {
   function LINK_address() external view returns (address);

   function VRF_coordinator_address() external view returns (address);

   function VRF_randomness() external view returns (uint256);

   function _UFOhasArrived() external view returns (bool);

   function _contractsealed() external view returns (bool);

   function _mothershipHasArrived() external view returns (bool);

   function abduct(uint256 quantity) external;

   function address_genesis_descriptor() external view returns (address);

   function address_opensea_token() external view returns (address);

   function address_v2_descriptor() external view returns (address);

   function approve(address to, uint256 tokenId) external;

   function authorizedMinter() external view returns (address);

   function balanceOf(address owner) external view returns (uint256);

   function blockhashData(uint256) external view returns (bytes8);

   function changeLinkFee(
      uint256 _fee,
      address _VRF_coordinator_address,
      bytes32 _keyhash
   ) external;

   function checkType(uint256 tokenId) external pure returns (uint8);

   function distributeOneOfOnes() external;

   function emergencyWithdraw(uint256 tokenId) external;

   function genesisSupply() external view returns (uint256);

   function genesisTokenOSSStoNewTokenId(uint256) external view returns (uint256);

   function getApproved(uint256 tokenId) external view returns (address);

   function getRandomNumber() external returns (bytes32 requestId);

   function getTokenSeed(uint256 tokenId) external view returns (uint8[10] memory);

   function isApprovedForAll(address owner, address operator) external view returns (bool);

   function maxMintsPerTransaction() external view returns (uint256);

   function maxTokens() external view returns (uint256);

   function mintAdmin(address to, uint256 quantity) external;

   function mintToContract() external;

   function name() external view returns (string memory);

   function onERC1155Received(
      address operator,
      address from,
      uint256 tokenId,
      uint256 value,
      bytes memory data
   ) external returns (bytes4);

   function owner() external view returns (address);

   function ownerOf(uint256 tokenId) external view returns (address);

   function payee(uint256 index) external view returns (address);

   function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external;

   function rawSeedForTokenId(uint256 tokenId) external view returns (uint256);

   function release(address account) external;

   function release(address token, address account) external;

   function released(address token, address account) external view returns (uint256);

   function released(address account) external view returns (uint256);

   function renounceOwnership() external;

   function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
   ) external;

   function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
   ) external;

   function seal() external;

   function setAddresses(
      address _genesis_descriptor,
      address _v2_descriptor,
      address _os_address,
      address _authorizedMinter
   ) external;

   function setApprovalForAll(address operator, bool approved) external;

   function setGenesisTokenIds(uint256[] memory _OSSS_id, uint256[] memory _newTokenId) external;

   function setReverseRecord(string memory _name, address registrar_address) external;

   function setv2Price(uint256 _price) external;

   function shares(address account) external view returns (uint256);

   function supportsInterface(bytes4 interfaceId) external view returns (bool);

   function symbol() external view returns (string memory);

   function togglePublicMint() external;

   function toggleUpgrade() external;

   function tokenIdToBlockhashIndex(uint256 tokenId) external view returns (uint16);

   function tokenMap(uint256) external view returns (uint16 startingTokenId, uint16 blockhashIndex);

   function tokenSVG(uint256 tokenId, bool background) external view returns (string memory);

   function tokenURI(uint256 tokenId) external view returns (string memory);

   function totalReleased(address token) external view returns (uint256);

   function totalReleased() external view returns (uint256);

   function totalShares() external view returns (uint256);

   function totalSupply() external view returns (uint256);

   function transferFrom(
      address from,
      address to,
      uint256 tokenId
   ) external;

   function transferOwnership(address newOwner) external;

   function v2oneOfOneCount() external view returns (uint256);

   function v2price() external view returns (uint256);

   function v2supplyMax() external view returns (uint256);
}
