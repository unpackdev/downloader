//SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

interface IBrainDrops {
   function mint(address recipient, uint _projectId) external payable returns (uint256);

   function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) external;

   function updateProjectDescription(uint256 _projectId, string memory _projectDescription) external;

   function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) external;

   function updateProjectLicense(uint256 _projectId, string memory _projectLicense) external;

   function updateProjectBaseURI(uint256 _projectId, string memory _projectBaseURI) external;

   function updateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) external;

   function toggleProjectIsPaused(uint256 _projectId) external;

   function setProvenanceHash(uint256 _projectId, string memory provenanceHash) external;

   function balanceOf(address owner) external view returns (uint256 balance);

   function ownerOf(uint256 tokenId) external view returns (address owner);

   function isWhitelisted(address sender) external view returns (bool whitelisted);

   function transferFrom(address from, address to, uint256 tokenId) external;
}

contract ArtistProxy is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    constructor(address _braindropsAddress) {
      braindrops = IBrainDrops(_braindropsAddress);
    }

    IBrainDrops public braindrops;

    mapping(uint256 => mapping(address => bool)) public projectIdToGenesisDropAddressMinted;
    mapping(uint256 => mapping(address => bool)) public projectIdToProjectAntiBotAddressMinted;

    mapping(uint256 => address) public projectIdToArtistAddress;
    mapping(uint256 => bool) public projectIdToProjectActivated;
    mapping(uint256 => bool) public projectIdToProjectAntiBotActivated;
    mapping(uint256 => bool) public projectIdToHolderActivated;
    mapping(uint256 => bool) public projectIdToGenesisDropActivated;

    mapping(uint256 => uint256) public projectIdToOlderProjectId;
    mapping(uint256 => uint256) public projectIdToBurnableProjectId;
    mapping(uint256 => address) public projectIdToBotPreventionAddress;

    address public signingAddress;

    modifier onlyArtist(uint256 _projectId) {
        require(msg.sender == projectIdToArtistAddress[_projectId], "Only artist");
        _;
    }

    modifier onlyWhitelisted() {
        require(braindrops.isWhitelisted(msg.sender), "Only whitelisted");
        _;
    }

    modifier onlyHolders(uint256 _projectId) {
        require(braindrops.balanceOf(msg.sender) > 0, "Holders only");
        _;
    }

    function setSigningAddress(address _signingAddress) public onlyWhitelisted {
        signingAddress = _signingAddress;
    }

    function setArtist(uint projectId, address artistAddress) public onlyWhitelisted {
        projectIdToArtistAddress[projectId] = artistAddress;
    }

    function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) onlyArtist(_projectId) public {
        braindrops.updateProjectArtistName(_projectId, _projectArtistName);
    }

    function updateProjectDescription(uint256 _projectId, string memory _projectDescription) onlyArtist(_projectId) public {
        braindrops.updateProjectDescription(_projectId, _projectDescription);
    }

    function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) onlyArtist(_projectId) public {
        braindrops.updateProjectWebsite(_projectId, _projectWebsite);
    }

    function updateProjectLicense(uint256 _projectId, string memory _projectLicense) onlyArtist(_projectId) public {
        braindrops.updateProjectLicense(_projectId, _projectLicense);
    }

    function updateProjectBaseURI(uint256 _projectId, string memory _projectBaseURI) onlyArtist(_projectId) public {
        braindrops.updateProjectBaseURI(_projectId, _projectBaseURI);
    }

    function updateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) onlyArtist(_projectId) public {
        braindrops.updateProjectPricePerTokenInWei(_projectId, _pricePerTokenInWei);
    }

    function toggleProjectIsPaused(uint256 _projectId) public onlyArtist(_projectId) {
        braindrops.toggleProjectIsPaused(_projectId);
    }

    function setProvenanceHash(uint256 _projectId, string memory provenanceHash) public onlyArtist(_projectId) {
        braindrops.setProvenanceHash(_projectId, provenanceHash);
    }

    function toggleProjectIsActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToProjectActivated[_projectId] = !projectIdToProjectActivated[_projectId];
    }

    function toggleProjectAntiBotActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToProjectAntiBotActivated[_projectId] = !projectIdToProjectAntiBotActivated[_projectId];
    }

    function toggleProjectIsHolderActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToHolderActivated[_projectId] = !projectIdToHolderActivated[_projectId];
    }

    function toggleProjectIsGenesisDropActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToGenesisDropActivated[_projectId] = !projectIdToGenesisDropActivated[_projectId];
    }

    function setProjectIdToOlderProjectId(uint256 _projectId, uint256 _olderProjectId) public onlyArtist(_projectId) {
        projectIdToOlderProjectId[_projectId] = _olderProjectId;
    }

    function setProjectIdToBurnableProjectId(uint256 _projectId, uint256 _olderProjectId) public onlyArtist(_projectId) {
        projectIdToBurnableProjectId[_projectId] = _olderProjectId;
    }

    function _validateServerSignedMessage(bytes32 message, bytes calldata signature, uint _projectId) internal virtual {
        require(projectIdToProjectAntiBotAddressMinted[_projectId][msg.sender] == false, "Cannot replay transaction");

        bytes32 expectedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", '20', msg.sender));
        require(message == expectedMessage, "Malformed message");

        address signer = message.recover(signature);
        require(signer == signingAddress, "Invalid signature");

        projectIdToProjectAntiBotAddressMinted[_projectId][msg.sender] = true;
    }

  function mintForServerSigned(address recipient, uint _projectId, bytes32 message, bytes calldata signature)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          require(projectIdToProjectAntiBotActivated[_projectId], "Project must be active for anti-bot minting");
          _validateServerSignedMessage(message, signature, _projectId);

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function mintForProjectBurnersOnly(address recipient, uint _projectId, uint _tokenId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          uint burnableProjectId = projectIdToBurnableProjectId[_projectId];
          require(burnableProjectId > 0, "Project must be active for project-holder burn-mints");

          uint projectId = (_tokenId - (_tokenId % 1000000)) / 1000000;
          require(projectId == burnableProjectId, "token must belong to the project to burn");

          braindrops.transferFrom(msg.sender, address(this), _tokenId);
          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function mintForArtistsOnly(address recipient, uint _projectId)
        public
        payable
        onlyArtist(_projectId)
        returns (uint256)
      {
          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function mintForProjectSpecificHoldersOnly(address recipient, uint _projectId, uint _projectTokenId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          uint olderProjectId = projectIdToOlderProjectId[_projectId];
          require(olderProjectId > 0, "Project must be active for project-holder specific mints");

          uint _projectIdFromTokenId = (_projectTokenId - (_projectTokenId % 1000000)) / 1000000;
          require(_projectIdFromTokenId == olderProjectId, "must pass in a token id from the correct project");
          require(braindrops.ownerOf(_projectTokenId) == msg.sender, "sender must own token id passed in");

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function mintForGenesisDropHoldersOnly(address recipient, uint _projectId, uint _project1TokenId, uint _project2TokenId, uint _project3TokenId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          require(projectIdToGenesisDropActivated[_projectId], "Project must be active for genesis set holders");
          require(projectIdToGenesisDropAddressMinted[_projectId][msg.sender] == false, "One mint per address");

          uint _project1Id = (_project1TokenId - (_project1TokenId % 1000000)) / 1000000;
          require(_project1Id == 1, "must pass in a token id from project 1");

          uint _project2Id = (_project2TokenId - (_project2TokenId % 1000000)) / 1000000;
          require(_project2Id == 2, "must pass in a token id from project 2");

          uint _project3Id = (_project3TokenId - (_project3TokenId % 1000000)) / 1000000;
          require(_project3Id == 3, "must pass in a token id from project 3");

          require(braindrops.ownerOf(_project1TokenId) == msg.sender, "must own the selected token from project 1");
          require(braindrops.ownerOf(_project2TokenId) == msg.sender, "must own the selected token from project 2");
          require(braindrops.ownerOf(_project3TokenId) == msg.sender, "must own the selected token from project 3");

          projectIdToGenesisDropAddressMinted[_projectId][msg.sender] = true;
          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function mintForHoldersOnly(address recipient, uint _projectId)
        public
        payable
        nonReentrant
        onlyHolders(_projectId)
        returns (uint256)
      {
          require(projectIdToHolderActivated[_projectId], "Project must be active for holders");

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function mint(address recipient, uint _projectId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          require(projectIdToProjectActivated[_projectId], "Project must be active");

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

}

