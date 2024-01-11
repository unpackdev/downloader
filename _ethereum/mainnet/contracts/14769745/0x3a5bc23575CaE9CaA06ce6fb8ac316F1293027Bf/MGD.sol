//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "./Initializable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./IMGD.sol";
import "./MGDcontract.sol";

contract MGD is IMGD, ERC1155SupplyUpgradeable {
  bool public override isPaused;

  mapping(uint256 => TokenMetadata) public metadata;
  mapping(string => OrgData) public orgs;
  mapping(string => bool) public orgTaken;
  mapping(address => string) public artists;
  mapping(address => bool) public governance;
  mapping(MGDcontract => bool) public mgdContract;
  mapping(address => bool) public initialGovernanceList;
  mapping(uint256 => bool) public flaggedNFTS;

  uint256 private tokenCount;

  struct TokenMetadata {
    string metadataUri;
    string orgName;
    address author;
    address royaltyReceiver;
    uint24 royalty;
    bool splitPayable;
  }

  struct OrgData {
    string orgDataURI;
    mapping(address => bool) orgGovernance;
    mapping(address => bool) isMember;
    mapping(address => string) memberData;
  }

  string public name; 


  function initialize(address[] memory _addresses) public initializer {
    ERC1155Upgradeable.__ERC1155_init(
      "https://game.example/api/item/{id}.json"
    );
    ERC1155SupplyUpgradeable.__ERC1155Supply_init();
    for (uint256 i = 0; i < _addresses.length; i++) {
      initialGovernanceList[_addresses[i]] = true;
      governance[_addresses[i]] = true;
      emit GovernanceAdded(_addresses[i]);
    }
  }

  /**Modifier functions **/

  modifier onlyGovernance() {
    require(governance[_msgSender()]);
    _;
  }

  modifier onlyIGovernance(address _address) {
    require(initialGovernanceList[_address]);
    _;
  }

  modifier onlyOrgGovernance(string memory _orgName) {
    OrgData storage _org = orgs[_orgName];
    require(_org.orgGovernance[_msgSender()] || governance[_msgSender()]);
    _;
  }

  modifier onlyArtist(string memory _orgName) {
    require(hasAuthorization(_msgSender(), _orgName));
    _;
  }

  modifier notPaused() {
    require(!isPaused);
    _;
  }

  /** Governance functions **/

  /**
    @notice setMGDcontract allows the Governance to give a contract mint permissions
    @dev this is a protected function that only the Governance can call
    */
  function setMGDcontract(address _contract) public override onlyGovernance() {
    mgdContract[MGDcontract(_contract)] = true;
  }

  /**
    @notice createOrganization allows the Governance to create organizations
    @param _orgName is the name of the org being created
    @param _orgData is the orgs informational URI
    @param _address is the first Governance address of an org
    */
  function createOrganization(
    string memory _orgName,
    string memory _orgData,
    address _address
  ) external override onlyGovernance() notPaused() {
    require(!orgTaken[_orgName]);
    OrgData storage _org = orgs[_orgName];
    _org.orgDataURI = _orgData;
    _org.isMember[_address] = true;
    _org.orgGovernance[_address] = true;
    orgTaken[_orgName] = true;
    emit OrganizationCreated(_orgName, _orgData, _address);
  }
  
    /**
    @notice addIGovernance allows a initialGovernance address to add other addresses to the initialGovernance list
    @param _address is the address of the new initialGovernance
    */
  function addIGovernance(address _address)
    external
    override
    onlyIGovernance(_msgSender())
    notPaused()
  {
    initialGovernanceList[_address] = true;
  }

  /**
    @notice removeIGovernance allows a initialGovernance address to remove other addresses from the initialGovernance list
    @param _address is the address from the initialGovernance list being removed
    */
  function removeIGovernance(address _address)
    external
    override
    onlyIGovernance(_msgSender())
    notPaused()
  {
    initialGovernanceList[_address] = false;
  }

  /**
    @notice add Governance allows a governance address to add other addresses to the Governance list
    @param _address is the address of the new Governance
    */
  function addGovernance(address _address)
    external
    override
    onlyGovernance()
    notPaused()
  {
    governance[_address] = true;
    emit GovernanceAdded(_address);
  }

  /**
    @notice removeGovernance allows a governance address to remove other addresses from the Governance list
    @param _address is the address from the Governance list being removed
    */
  function removeGovernance(address _address)
    external
    override
    onlyGovernance()
    notPaused()
  {
    require(!initialGovernanceList[_address]);
    governance[_address] = false;
    emit GovernanceRemoved(_address);
  }

  /**Org Governance functions **/

  /**
    @notice addOrgGovernance allows an Org Governance to add another Governance address to an org
    @param _orgName is the name of the org
    @param _address is the address of the Governance
    */
  function addOrgGovernance(string memory _orgName, address _address)
    external
    override
    onlyOrgGovernance(_orgName)
    notPaused()
  {
    OrgData storage _org = orgs[_orgName];
    _org.orgGovernance[_address] = true;
    emit OrgGovernanceAdded(_orgName, _address);
  }

  /**
    @notice addArtistToOrg allows an Org Governance to add an artist to an organization
    @param _orgName is the name of the org
    @param _artistData is the URI for an artists data
    @param _address is the address of the artist being added
    */
  function addArtistToOrg(
    string memory _orgName,
    string memory _artistData,
    address _address
  ) external override onlyOrgGovernance(_orgName) notPaused() {
    OrgData storage _org = orgs[_orgName];
    _org.isMember[_address] = true;
    _org.memberData[_address] = _artistData;
    emit ArtistAdded(_address, _orgName, _artistData);
  }

  /**
    @notice removeOrgGovernance allows an Org Governance to remove an Org Governance address
    @param _orgName is the name of the org
    @param _address is the address of the Org Governance being removed
    */
  function removeOrgGovernance(string memory _orgName, address _address)
    external
    override
    onlyOrgGovernance(_orgName)
    notPaused()
  {
    OrgData storage _org = orgs[_orgName];
    _org.orgGovernance[_address] = false;
    emit OrgGovernanceRemoved(_orgName, _address);
  }

  /**
    @notice removeArtist allows an Org Governance to remove an artist
    @param _orgName is the name of the org
    @param _address is the address of the artist being removed
    */
  function removeArtist(string memory _orgName, address _address)
    external
    override
    onlyOrgGovernance(_orgName)
    notPaused()
  {
    OrgData storage _org = orgs[_orgName];
    _org.isMember[_address] = false;
    _org.memberData[_address] = " ";
    emit ArtistRemoved(_orgName, _address);
  }

  /**Artist functions **/

  /**
    @notice mint allows an artist to mint a new NFT
    @param _orgName is the name of the org
    @param _metadataUri is the new NFTs metadata URI
    @param _to is the address the NFT is being minted to
    @param _royaltyReceiver is the address of the royalty receiver
    @param _author is the author of the NFT
    @param _issues is the number of issues of an NFT to mint
    @param _royalty is the royalty percentage of a sale that is sent to the artist
    */
  function mint(
    string memory _orgName,
    string memory _metadataUri,
    address _to,
    address _royaltyReceiver,
    address _author,
    uint256 _issues,
    uint24 _royalty,
    bool _splitPayable
  )
    external
    override
    onlyArtist(_orgName)
    notPaused()
    returns (uint256 tokenId_)
  {
    require(_royalty <= 200000);

    tokenId_ = ++tokenCount;

    _mint(_to, tokenId_, _issues, "");

    TokenMetadata storage _metadata = metadata[tokenId_];

    _metadata.metadataUri = _metadataUri;
    _metadata.orgName = _orgName;
    _metadata.author = _author;
    _metadata.royalty = _royalty;
    _metadata.royaltyReceiver = _royaltyReceiver;
    _metadata.splitPayable = _splitPayable;

    flaggedNFTS[tokenId_] = false;

    emit Mint(
      tokenId_,
      _metadata.author,
      _to,
      _metadata.royaltyReceiver,
      _metadata.royalty,
      _issues,
      _metadata.metadataUri,
     _metadata.splitPayable
    );

    emit MintOrg(tokenId_, _orgName);
  }

  /**
    @notice updateMetadata allows an artist to edit an NFT's metadata URI
    @param _tokenId is the NFT's token ID
    @param _metadataUri is the new metadata URI
    @param _royaltyReceiver is the address of the royalty receiver
    @param _royalty is the royalty percentage of a sale that is sent to the artist
    */
  function updateMetadata(
    uint256 _tokenId,
    string memory _metadataUri,
    address _royaltyReceiver,
    uint24 _royalty
  ) external override notPaused() {
    TokenMetadata storage _metadata = metadata[_tokenId];
    require(hasAuthorization(_msgSender(), _metadata.orgName));
    require(_royalty <= 200000);
    _metadata.metadataUri = _metadataUri;
    _metadata.royaltyReceiver = _royaltyReceiver;
    _metadata.royalty = _royalty;

    emit MetadataUpdate(
      _tokenId,
      _msgSender(),
      _metadataUri,
      _royaltyReceiver,
      _royalty
    );
  }

  /** view functions **/

  /**
    @notice Called with the sale price to determine how much royalty
              is owed and to whom.
    @param _tokenId - the NFT asset queried for royalty information
    @param _value - the sale price of the NFT asset specified by _tokenId
    @return _receiver - address of who should be sent the royalty payment
    @return _royaltyAmount - the royalty payment amount for _value sale price
    @dev percentages should be set as parts per million 1000000 == 100% and 100000 == 10%
    */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _value
  )
    external
    view
    override
    returns (
      address _receiver,
      uint256 _royaltyAmount
    )
  {
    TokenMetadata storage _metadata = metadata[_tokenId];
    uint256 royaltyP = _metadata.royalty;
    _royaltyAmount = ((_value * royaltyP) / 1000000);
    _receiver = _metadata.royaltyReceiver;
  }

  /**
    @notice isIGov returns a bool representing whether or not an address in included in initialGovernance list
    @param _address is the address in question
    */
  function isIGovernance(address _address)
    public
    view
    override
    returns (bool)
  {
    return initialGovernanceList[_address];
  }

  /**
    @notice hasAuthorization returns a bool representing whether or not an address has mint permissions
    @param _address is the address in question
    @param _orgName is the name of the org in question
    */
  function hasAuthorization(address _address, string memory _orgName)
    public
    view
    override
    returns (bool)
  {
    OrgData storage _org = orgs[_orgName];
    if (_org.isMember[_address]) {
      return true;
    } else if (mgdContract[MGDcontract(_address)]) {
      return true;
    } else if (_org.orgGovernance[_address]) {
      return true;
    } else if (governance[_address]) {
      return true;
    } else {
      return false;
    }
  }

  /**
        @notice triggerPause allows one of the initial Governance to pause or unpause the functions
                of the MGD platform
    */
  function triggerPause() external override onlyIGovernance(_msgSender()) {
    if (isPaused) {
      isPaused = false;
    } else {
      isPaused = true;
    }
  }

  /**
    @notice unlockPlatform is a proxy function that allows an initial Governance
            to unlock and MGD cointract to NFT's from outside the MGD platform
    @param _mgdContract is the address of the contract being unlocked
    */
  function unlockPlatform(address _mgdContract) external onlyIGovernance(_msgSender()) {
    require(mgdContract[MGDcontract(_mgdContract)]);
    MGDcontract mgdCon = MGDcontract(_mgdContract);
    mgdCon.unlockPlatform();
  }

  /**
   * @dev Gets the base token URI
   * @return string representing the base token URI
   */
  function baseTokenURI() public pure returns (string memory) {
    return "https://mgd-production.mypinata.cloud/ipfs/";
  }

  function uri(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    TokenMetadata storage _metadata = metadata[_tokenId];

    string memory result =
      string(abi.encodePacked(baseTokenURI(), _metadata.metadataUri));
    return result;
  }

  function setName(string memory _name) external {
    name = _name;
  }
  
}
