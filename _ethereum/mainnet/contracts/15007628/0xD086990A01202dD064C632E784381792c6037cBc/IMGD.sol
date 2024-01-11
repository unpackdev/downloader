//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "./IERC1155Upgradeable.sol";

interface IMGD is IERC1155Upgradeable {
    event OrganizationCreated(
        string organization,
        string metadata,
        address orgAdmin
    );

    event GovernanceAdded(address _address);

    event GovernanceRemoved(address _address);

    event OrgGovernanceAdded(string organization, address _address);

    event ArtistAdded(address artist, string organization, string metadata);

    event Mint(
        uint256 id,
        address indexed author,
        address indexed to,
        address royaltyReceiver,
        uint24 royalty,
        uint256 issues,
        string metadataUri,
        bool splitPayable
    );

    event MintOrg(uint256 tokenId, string orgName);

    event MetadataUpdate(
        uint256 indexed id,
        address author,
        string metadataUri,
        address indexed royaltyReceiver,
        uint24 royalty
    );

    event OrgDataUpdated(string _orgName, string newURI);

    event OrgGovernanceRemoved(string _orgName, address _address);

    event ArtistRemoved(string _orgName, address _address);

    event NFTflagged(uint256 tokenId);

    event PlatformPaused(bool _isPaused);

    /**Protocol Admin functions **/

    /**
    @notice setMGDcontract allows the Governance to give a contract mint permissions
    @dev this is a protected function that only the Governance can call
    */
    function setMGDcontract(address _contract) external;

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
    ) external;

    /**
    @notice add Governance allows a governance address to add other addresses to the Governance list
    @param _address is the address of the new Governance
    */
    function addGovernance(address _address) external;

    /**
    @notice add Governance allows a governance address to add other addresses to the Governance list
    @param _address is the address of the new Governance
    */
    function addIGovernance(address _address) external;

    /**
    @notice removeGovernance allows a governance address to remove other addresses from the Governance list
    @param _address is the address from the Governance list being removed
    */
    function removeGovernance(address _address) external;

    /**
    @notice removeGovernance allows a governance address to remove other addresses from the Governance list
    @param _address is the address from the Governance list being removed
    */
    function removeIGovernance(address _address) external;

    /**Org Admin functions **/

    /**
    @notice addOrgGovernance allows an Org Governance to add another Governance address to an organizastion
    @param _orgName is the name of the organizastion
    @param _address is the address of the Governance
    */
    function addOrgGovernance(string memory _orgName, address _address) external;

    /**
    @notice addArtistToOrg allows an Org Governance to add an artist to an organization
    @param _orgName is the name of the organizastion
    @param _artistData is the URI for an artists data
    @param _address is the address of the artist being added
    */
    function addArtistToOrg(
        string memory _orgName,
        string memory _artistData,
        address _address
    ) external;

    /**
    @notice removeOrgGovernance allows an Org Governance to remove an Org Governance address
    @param _orgName is the name of the org
    @param _address is the address of the Org Governance being removed
    */
    function removeOrgGovernance(string memory _orgName, address _address) external;

    /**
    @notice removeArtist allows an Org Governance to remove an artist
    @param _orgName is the name of the org
    @param _address is the address of the artist being removed
    */
    function removeArtist(string memory _orgName, address _address) external;


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
    ) external returns (uint256 tokenId_);

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
    ) external;

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
        returns (
            address _receiver,
            uint256 _royaltyAmount
        );

      /**
    @notice isIGovernance returns a bool representing whether or not an address in included in initialGovernance list
    @param _address is the address in question
    */
  function isIGovernance(address _address)
    external
    view
    returns (bool);

    /**
        @notice hasAuthorization returns a bool representing whether or not an address has mint permissions
        @param _address is the address in question
        @param _orgName is the name of the org in question
        */
    function hasAuthorization(address _address, string memory _orgName)
        external
        view
        returns (bool);

    /**
        @notice pausePlatform allows one of the initial Protocol Admins to pause or unpause the functions
                of the MGD platform
        */
    function triggerPause() external;

    function isPaused() external returns (bool);
}
