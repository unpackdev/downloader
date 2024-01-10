// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IObscuraCommunity.sol"; 
import "./IObscuraOnetimeMintPass.sol";
import "./AccessControl.sol";
import "./randomiser.sol";
import "./IRNG2.sol";


import "./console.sol";

// Community
// 10 photographers, 15 photos
// 30 mint passes
//
// on sale start we allocate who gets what
// pre-allocated array of pass => []photographer
//
// saleStart :
// [numMintPasses]randoms requested, 1 per mintpass
// split into 16 randoms of which 6 are used
// #1 used to get random allocation of []photographer
// #2 - #6 used to get a random item from each
//
// platformMintingReserve relates to number of passes reserved for platform

contract IMinter {
    mapping(uint256 => mapping(uint256 => bool)) public mpToTokenClaimed;
}

contract CommunityMinter2 is AccessControl, randomiser {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private constant DIVIDER = 10**5;
    uint256 private nextProjectId ;
    uint256 private nextRandom;
    uint256 private defaultRoyalty = 10;
    IObscuraCommunity private communityToken;
    IObscuraOnetimeMintPass private mintPass;
    address                                      public obscuraTreasury;
    string                                       public defaultCID;

    mapping(uint256 => CommunityProject)         public projects;
    mapping(uint256 => uint256)                  public tokenIdToProject;
    mapping(uint256 => mapping(uint256 => bool)) public mpToTokenClaimed;
    mapping(uint256 => uint256)                  public mpToProjectClaimedCount;
    mapping(uint256 => mapping(uint256 => bool)) public projectToTokenClaimed;
    mapping(uint256 => uint256)                  public projectToRequest;

    mapping (uint256 => uint256)                requestToProject;
    mapping (uint256 => uint256[])              projectRandoms;


    IRNG2                                       rng;


    constructor(
        address deployedCommunity,
        address deployedMintPass,
        address admin,
        address payable _obscuraTreasury,
        IRNG2   _rng
    ) randomiser(1) {
        communityToken = IObscuraCommunity(deployedCommunity);
        mintPass = IObscuraOnetimeMintPass(deployedMintPass);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
         _setupRole(MODERATOR_ROLE, admin);
        _setupRole(MODERATOR_ROLE, msg.sender);
        obscuraTreasury = _obscuraTreasury;
        rng = _rng;
    }

    function createProject(
        string memory _projectName,
        uint256 allowedPassId,
        uint16 _numberOfArtists,
        uint16 _photosPerArtist,
        uint16 _platformMintingReserve, 
        uint16 _numberOfPasses,
        uint16 _numberPerPass,
        uint256[] memory _photographerAllocation,
        string memory cid
    ) external onlyRole(MODERATOR_ROLE) {
        uint16 maxTokens = _photosPerArtist*_numberOfArtists;
        require(maxTokens < DIVIDER, "Cannot exceed 100,000");
        require(bytes(_projectName).length > 0, "Project name missing");

        uint256 projectId = nextProjectId += 1;

        uint256 randomID  = nextRandom + 1;
        

        projects[projectId] = CommunityProject({
            numberOfArtists : _numberOfArtists,
            photosPerArtist : _photosPerArtist,
            platformMintingReserve: _platformMintingReserve,
            platformMinted : 0,
            publicMinted : 0,
            projectName: _projectName,
            isSaleActive: false,
            royalty: defaultRoyalty,
            allowedPassId: allowedPassId,
            firstRandom : randomID,
            numberOfPasses : _numberOfPasses,
            photographerAllocation : _photographerAllocation,
            numberPerPass : _numberPerPass
        });

        setNumTokensLeft(randomID, _numberOfPasses);
        for (uint j = 0; j < _numberOfArtists; j++) {
            console.log("set R(",randomID+j,") to ",_photosPerArtist);
            setNumTokensLeft(randomID+j+1, _photosPerArtist);
        }

        communityToken.createProject(_projectName,_photosPerArtist,cid);
    }

    function latestProject() external view returns (uint256) {
        return nextProjectId;
    }

    function updateRand(IRNG2   _rng) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rng = _rng;
    }


    function mint(uint256 projectId) external {

        CommunityProject memory project = projects[projectId];
        require(project.numberOfArtists > 0, "Project doesn't exist");
        require(project.isSaleActive, "Mint is not open yet");
        require(projectRandoms[projectId].length > 0, "waiting for CL");

        uint256 publicMinted = projects[projectId].publicMinted += 1;
        require(
            publicMinted <= project.numberOfPasses - project.platformMintingReserve,
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

        console.log("mintpass found",mintPassTokenId);

        uint256 random16 = projectRandoms[projectId][mintPassTokenId % DIVIDER];

        uint256 pAllocation = randomTokenURI(project.firstRandom, random16 & 0xff) - 1; // function is 1 based
        console.log("pAllocation",pAllocation);
        uint256 allocation = project.photographerAllocation[pAllocation];
        console.log("allocation",pAllocation, allocation);
        random16 = random16 >> 0;
        uint32[] memory tokenz = new uint32[](project.numberPerPass) ;
        for (uint j = 0; j < project.numberPerPass; j++) {
                uint photographerID = (allocation & 0xff) - 1;
                console.log("photographerID",photographerID);
                allocation = allocation >> 8;
                console.log("random ID" , project.firstRandom + photographerID + 1);
                uint tokenInProject = randomTokenURI(project.firstRandom + photographerID + 1, random16 & 0xff);
                uint32 tokenID = uint32((project.photosPerArtist * photographerID) + tokenInProject);
                random16 = random16 >> 8;
                tokenz[j] = tokenID;
        }

        communityToken.mintBatch(msg.sender, projectId, tokenz); 
        
        mintPass.redeemToken(mintPassTokenId);
    }

    

    function setSaleActive(uint256 projectId, bool isSaleActive)
        external
        onlyRole(MODERATOR_ROLE)
    {
        projects[projectId].isSaleActive = isSaleActive;
        if (projectToRequest[projectId] == 0){
            uint256 requestID = rng.requestRandomWordsWithCallback(projects[projectId].numberOfPasses, 0);
            requestToProject[requestID] = projectId;
            console.log("r2p");
            projectToRequest[projectId] = requestID;
            console.log("p2r");
        }
    }

    function isSalePublic(uint256 projectId)
        external
        view
        returns (bool active)
    {
        return projects[projectId].isSaleActive;
    }


    function setProjectCID(uint256 projectId, string calldata cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        communityToken.setProjectCID(projectId, cid);
    }

    function setTokenCID(uint256 tokenId, string calldata cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        communityToken.setTokenCID(tokenId, cid);
    }

    function setDefaultCID(string calldata _defaultCID)
        external
        onlyRole(MODERATOR_ROLE)
    {
        communityToken.setDefaultPendingCID(_defaultCID);
    }

    function withdraw() public onlyRole(MODERATOR_ROLE) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(obscuraTreasury).call{value: balance}("");
        require(success, "Withdraw: unable to send value");
    }


    struct CommunityProject {
        uint16 numberOfArtists;
        uint16 photosPerArtist;      
        uint16 publicMinted;
        uint16 platformMinted;
        uint16 platformMintingReserve; // number of MINTS reserved for obscura use. Cannot be public Minted
        uint16 numberOfPasses;          // number of passes issued
        uint16 numberPerPass;           // number of NFTS pass holder gets
        uint256[] photographerAllocation;

        uint256 royalty;
        uint256 allowedPassId;
        bool isSaleActive;
        string projectName;
        uint256 firstRandom;
    }



    function multi_process(uint256[] memory randomWords, uint256 _requestId) external {
        require(msg.sender == address(rng),"Unauthorised Requestor");
        uint256 projectID = requestToProject[_requestId];
        projectRandoms[projectID] = randomWords;
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
