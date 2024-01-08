// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC165.sol";
import "./BridgeContext.sol";

///
///
///  █████╗ ██████╗ ████████╗
/// ██╔══██╗██╔══██╗╚══██╔══╝
/// ███████║██████╔╝   ██║
/// ██╔══██║██╔══██╗   ██║
/// ██║  ██║██║  ██║   ██║
/// ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
///
/// ██████╗ ██████╗ ██╗██████╗  ██████╗ ███████╗
/// ██╔══██╗██╔══██╗██║██╔══██╗██╔════╝ ██╔════╝
/// ██████╔╝██████╔╝██║██║  ██║██║  ███╗█████╗
/// ██╔══██╗██╔══██╗██║██║  ██║██║   ██║██╔══╝
/// ██████╔╝██║  ██║██║██████╔╝╚██████╔╝███████╗
/// ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ ╚══════╝
///
///
/// @title Art Bridge NFT Platform Token
/// @author artbridge.eth
/// @notice ArtBridge controls all project metadata and financial parameters
contract ArtBridge is ERC721Enumerable, ERC721Burnable, BridgeContext {
  using Strings for uint256;

  event Mint(
    address indexed _to,
    uint256 indexed _id,
    uint256 indexed _tokenId
  );
  event RegisterProject(uint256 indexed _id);

  mapping(uint256 => BridgeBeams.Project) public projects;
  mapping(address => bool) public minters;
  mapping(uint256 => address) public projectToArtistAddress;
  mapping(uint256 => uint256) public projectToTokenPrice;
  mapping(uint256 => string) public projectToBaseURI;

  uint256 public constant MAX_PROJECT_TOKENS = 1_000_000;
  uint256 public nextProjectId = 0;
  string public bridgeAPI;

  /// @param _id target bridge project id
  modifier onlyUnreleased(uint256 _id) {
    require(_id < nextProjectId, "invalid _id");
    require(!BridgeBeams.isReleased(projects[_id]), "released");
    _;
  }

  modifier onlyMinter() {
    require(minters[msg.sender], "!minter");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _api
  ) ERC721(_name, _symbol) {
    bridgeAPI = _api;
  }

  /// @param _minter address to add as minter
  function addMinter(address _minter) external onlyOwner {
    minters[_minter] = true;
  }

  /// @param _minter address to remove as minter
  function removeMinter(address _minter) external onlyOwner {
    minters[_minter] = false;
  }

  /// @param _name project name
  /// @param _artist artist payment address
  /// @param _maxSupply maximum mintable tokens
  function registerProject(
    string memory _name,
    address _artist,
    uint256 _maxSupply
  ) external onlyOwner {
    require(_maxSupply > 0, "max supply must be at least one");
    require(_maxSupply <= MAX_PROJECT_TOKENS, "exceed max project tokens");
    uint256 projectId = nextProjectId;
    BridgeBeams.Project memory project = BridgeBeams.Project({
      id: projectId,
      name: _name,
      artist: "",
      description: "",
      website: "",
      supply: 0,
      maxSupply: _maxSupply,
      startBlock: 0
    });
    projects[projectId] = project;
    projectToArtistAddress[projectId] = _artist;
    nextProjectId = nextProjectId + 1;
    emit RegisterProject(projectId);
  }

  /// @param _id target bridge project id
  /// @param _artist artist name
  /// @param _description project description
  /// @param _website artist personal website url
  function setArtistData(
    uint256 _id,
    string memory _artist,
    string memory _description,
    string memory _website
  ) external onlyUnreleased(_id) onlyOwner {
    require(bytes(_artist).length > 0, "empty artist");
    require(bytes(_description).length > 0, "empty description");
    BridgeBeams.Project memory project = projects[_id];
    project.artist = _artist;
    project.description = _description;
    project.website = _website;
    projects[_id] = project;
  }

  /// @param _id target bridge project id
  /// @param _price token price in wei
  function setProjectTokenPrice(uint256 _id, uint256 _price)
    external
    onlyUnreleased(_id)
    onlyOwner
  {
    projectToTokenPrice[_id] = _price;
  }

  /// @param _id target bridge project id
  /// @param _name project name
  function setProjectName(uint256 _id, string memory _name)
    external
    onlyUnreleased(_id)
    onlyOwner
  {
    require(bytes(_name).length > 0, "empty name");
    projects[_id].name = _name;
  }

  /// @param _id target bridge project id
  /// @param _artist artist name
  function setArtist(uint256 _id, string memory _artist)
    external
    onlyUnreleased(_id)
    onlyOwner
  {
    require(bytes(_artist).length > 0, "empty artist");
    projects[_id].artist = _artist;
  }

  /// @param _id target bridge project id
  /// @param _description project description
  function setDescription(uint256 _id, string memory _description)
    external
    onlyUnreleased(_id)
    onlyOwner
  {
    require(bytes(_description).length > 0, "empty description");
    projects[_id].description = _description;
  }

  /// @param _id target bridge project id
  /// @param _website artist personal website url
  function setWebsite(uint256 _id, string memory _website)
    external
    onlyUnreleased(_id)
    onlyOwner
  {
    projects[_id].website = _website;
  }

  /// @param _id target bridge project id
  /// @param _startBlock network block project activates at
  function setStartBlock(uint256 _id, uint256 _startBlock)
    external
    onlyUnreleased(_id)
    onlyOwner
  {
    require(_startBlock > block.number, "block must be in the future");
    projects[_id].startBlock = _startBlock;
  }

  /// @notice sets the start block to the current block, activating the project
  /// @param _id target bridge project id
  function setActive(uint256 _id) external onlyUnreleased(_id) onlyOwner {
    projects[_id].startBlock = block.number;
  }

  /// @notice sets the max supply to current supply, making the project not mintable
  /// @param _id target bridge project id
  function setComplete(uint256 _id) external onlyOwner {
    require(_id < nextProjectId, "invalid _id");
    require(BridgeBeams.isMintable(projects[_id]), "!mintable");
    projects[_id].maxSupply = projects[_id].supply;
  }

  /// @param _id target bridge project id
  /// @param _maxSupply maximum mintable tokens
  function setMaxSupply(uint256 _id, uint256 _maxSupply)
    external
    onlyUnreleased(_id)
    onlyOwner
  {
    require(_maxSupply > 0, "max supply must be at least one");
    require(_maxSupply <= MAX_PROJECT_TOKENS, "exceed max project tokens");
    projects[_id].maxSupply = _maxSupply;
  }

  /// @param _id target bridge project id
  /// @param _baseURI custom token base URI
  function setTokenURI(uint256 _id, string memory _baseURI) external onlyOwner {
    projectToBaseURI[_id] = _baseURI;
  }

  /// @param _api art bridge external API url
  function setBridgeAPI(string memory _api) external onlyOwner {
    require(bytes(_api).length > 0, "empty api");
    bridgeAPI = _api;
  }

  /// @param _id target bridge project id
  /// @param _amount number of tokens to mint
  /// @param _to address to mint tokens for
  function mint(
    uint256 _id,
    uint256 _amount,
    address _to
  ) external onlyMinter {
    require(BridgeBeams.isMintable(projects[_id]), "!mintable");
    _mint(_id, _amount, _to);
  }

  /// @param _id target bridge project id
  /// @param _amount number of tokens to mint
  /// @param _to address to mint tokens for
  function reserve(
    uint256 _id,
    uint256 _amount,
    address _to
  ) external onlyMinter {
    require(BridgeBeams.isInitialized(projects[_id]), "!initialized");
    _mint(_id, _amount, _to);
  }

  /// @param _id target bridge project id
  /// @param _amount number of tokens to mint
  /// @param _to address to mint tokens for
  function _mint(
    uint256 _id,
    uint256 _amount,
    address _to
  ) private {
    BridgeBeams.Project memory project = projects[_id];
    require(
      project.supply + _amount <= project.maxSupply,
      "not enough tokens to mint"
    );
    uint256 baseTokenId = _id * MAX_PROJECT_TOKENS + project.supply;
    for (uint256 i = 0; i < _amount; i++) {
      _mint(_to, baseTokenId + i);
      emit Mint(_to, _id, baseTokenId + i);
    }
    projects[_id].supply += _amount;
  }

  /// @param _id target bridge project id
  /// @return token associated project id
  function tokenToProject(uint256 _id) public view returns (uint256) {
    require(_exists(_id), "invalid _id");
    return _id / MAX_PROJECT_TOKENS;
  }

  /// @param _id target bridge project id
  /// @return all minted project token ids
  function projectToTokens(uint256 _id) public view returns (uint256[] memory) {
    require(_id < nextProjectId, "invalid _id");
    uint256[] memory tokenIds = new uint256[](projects[_id].supply);
    uint256 baseTokenId = _id * MAX_PROJECT_TOKENS;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenIds[i] = baseTokenId + i;
    }
    return tokenIds;
  }

  /// @param _id target bridge project id
  /// @return project state struct derived from given input
  function projectState(uint256 _id)
    external
    view
    returns (BridgeBeams.ProjectState memory)
  {
    require(_id < nextProjectId, "invalid _id");
    return BridgeBeams.projectState(projects[_id]);
  }

  /// @param _tokenId target bridge project token id
  /// @return URI containing token metadata
  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(_tokenId), "!token");
    string memory baseURI = projectToBaseURI[tokenToProject(_tokenId)];
    string memory tokenBaseURI = bytes(baseURI).length == 0
      ? bridgeAPI
      : baseURI;
    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
  }

  /// @param _owner token owner address
  /// @return array of token ids belonging to the requested owner
  function tokensOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory tokenIds = new uint256[](balanceOf(_owner));
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
