// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IObscuraFoundry.sol";
import "./IObscuraOnetimeMintPass.sol";
import "./AccessControl.sol";
import "./randomiser.sol";


import "./console.sol";

// V3 Minter for Curated Projects

contract IMinter {
    mapping(uint256 => mapping(uint256 => bool)) public mpToTokenClaimed;
}

contract FoundryMinter is AccessControl, randomiser {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private constant DIVIDER = 10**5;
    uint256 private nextProjectId ;
    uint256 private nextRandom;
    uint256 private defaultRoyalty = 10;
    IObscuraFoundry private foundryToken;
    IObscuraOnetimeMintPass private mintPass;
    address public obscuraTreasury;
    string public defaultCID;

    mapping(uint256 => Project) public projects;
    mapping(uint256 => uint256) public tokenIdToProject;
    mapping(uint256 => mapping(uint256 => bool)) public mpToTokenClaimed;
    mapping(uint256 => uint256) public mpToProjectClaimedCount;
    mapping(uint256 => mapping(uint256 => bool)) public projectToTokenClaimed;


    struct TokenProject {
        uint16 numberOfArtists;
        uint16 photosPerArtist;      
        uint16 publicMinted;
        uint16 platformMinted;
        uint16 platformMintingReserve; // number of MINTS reserved for obscura use. Cannot be public Minted
        uint256 royalty;
        bool active;        // can be redeemed
        string artist;      // for info only
        string cid;         // root of /artist/multiplePhotoMetadata structure
    }

    struct Project {
        uint16 numberOfArtists;
        uint16 photosPerArtist;      
        uint16 publicMinted;
        uint16 platformMinted;
        uint16 platformMintingReserve; // number of MINTS reserved for obscura use. Cannot be public Minted
        uint256 royalty;
        uint256 allowedPassId;
        bool isSaleActive;
        string projectName;
        uint256 firstRandom;
    }

    constructor(
        address deployedFoundry,
        address deployedMintPass,
        address admin,
        address payable _obscuraTreasury
    ) randomiser(1) {
        foundryToken = IObscuraFoundry(deployedFoundry);
        mintPass = IObscuraOnetimeMintPass(deployedMintPass);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
         _setupRole(MODERATOR_ROLE, admin);
        _setupRole(MODERATOR_ROLE, msg.sender);
        obscuraTreasury = _obscuraTreasury;
    }

    function createProject(
        string memory _projectName,
        uint256 allowedPassId,
        uint16 _numberOfArtists,
        uint16 _photosPerArtist,
        uint16 _platformMintingReserve, 
        string memory cid
    ) external onlyRole(MODERATOR_ROLE) {
        uint16 maxTokens = _photosPerArtist*_numberOfArtists;
        require(maxTokens < DIVIDER, "Cannot exceed 100,000");
        require(bytes(_projectName).length > 0, "Project name missing");

        uint256 projectId = nextProjectId += 1;

        uint256 randomID  = nextRandom + 1;

        projects[projectId] = Project({
            numberOfArtists : _numberOfArtists,
            photosPerArtist : _photosPerArtist,
            platformMintingReserve: _platformMintingReserve,
            platformMinted : 0,
            publicMinted : 0,
            projectName: _projectName,
            isSaleActive: false,
            royalty: defaultRoyalty,
            allowedPassId: allowedPassId,
            firstRandom : randomID
        });

        for (uint j = 0; j < _numberOfArtists; j++) {
            console.log("set R(",randomID+j,") to ",_photosPerArtist);
            setNumTokensLeft(randomID+j, _photosPerArtist);
        }

       

        foundryToken.createProject(_projectName,_numberOfArtists,_photosPerArtist,_platformMintingReserve,cid);
    }

    function latestProject() external view returns (uint256) {
        return nextProjectId;
    }


    function mint(uint256 projectId) external {
        Project memory project = projects[projectId];
        require(project.numberOfArtists > 0, "Project doesn't exist");
        require(project.isSaleActive, "Mint is not open yet");
        uint256 publicMinted = projects[projectId].publicMinted += 1;
        require(
            publicMinted <= project.photosPerArtist - project.platformMintingReserve,
            "All public sale tokens have been minted"
        );

        uint256 mintPassBalance = mintPass.balanceOf(msg.sender);
        require(mintPassBalance > 0, "User has no season pass");
        uint256 allowedPassId = project.allowedPassId;

        uint256 mintPassTokenId;
        for (uint256 i = 0; i < mintPassBalance; i++) {
            uint256 mpTokenId = mintPass.tokenOfOwnerByIndex(msg.sender, i);
            uint256 mpTokenPassId = mintPass.getTokenIdToPass(mpTokenId);

            // return mint pass token ID if allowed pass ID and user owned token's pass ID are the same.
            if (
                allowedPassId == mpTokenPassId &&
                !mpToTokenClaimed[projectId][mpTokenId]
            ) {
                mintPassTokenId = mpTokenId;
            }
        }
        require( 
            !mpToTokenClaimed[projectId][mintPassTokenId],
            "All user mint passes have already been claimed"
        );

        uint256 passId = mintPass.getTokenIdToPass(mintPassTokenId);
        require(
            project.allowedPassId == passId,
            "No pass ID or ineligible pass ID"
        );
        mpToTokenClaimed[projectId][mintPassTokenId] = true;
        mpToProjectClaimedCount[projectId] += 1;

 
        foundryToken.mintTo(msg.sender, projectId); 
        mintPass.redeemToken(mintPassTokenId);
    }

    uint256 randNonce = 1;

    function random() internal returns (uint256) {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) ;
    }

    function setSaleActive(uint256 projectId, bool isSaleActive)
        external
        onlyRole(MODERATOR_ROLE)
    {
        projects[projectId].isSaleActive = isSaleActive;
    }

    function setProjectCID(uint256 projectId, string calldata cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        foundryToken.setProjectCID(projectId, cid);
    }

    function setTokenCID(uint256 tokenId, string calldata cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        foundryToken.setTokenCID(tokenId, cid);
    }

    function setDefaultCID(string calldata _defaultCID)
        external
        onlyRole(MODERATOR_ROLE)
    {
        foundryToken.setDefaultPendingCID(_defaultCID);
    }

    function withdraw() public onlyRole(MODERATOR_ROLE) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(obscuraTreasury).call{value: balance}("");
        require(success, "Withdraw: unable to send value");
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
