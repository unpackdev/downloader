// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IObscuraMagnum.sol";
import "./IObscuraMintPass.sol";
import "./AccessControl.sol";
import "./randomiser.sol";


contract MinterV3 is AccessControl, randomiser {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private constant DIVIDER = 10**5;
    uint256 private nextProjectId = 0;
    uint256 private defaultRoyalty;
    IObscuraMagnum private magnum;
    IObscuraMintPass private mintPass;
    address public obscuraTreasury;
    string public defaultCID;

    mapping(uint256 => Project) public projects;
    mapping(uint256 => uint256) public tokenIdToProject;
    mapping(uint256 => mapping(uint256 => bool)) public mpToTokenClaimed;
    mapping(uint256 => uint256) public mpToProjectClaimedCount;
    mapping(uint256 => mapping(uint256 => bool)) public projectToTokenClaimed;

    struct Project {
        uint256 maxTokens;
        uint256 circulatingPublic;
        uint256 royalty;
        uint256 allowedPassId;
        bool isSaleActive;
        string artist;
        string cid;
    }

    constructor(
        address deployedMagnum,
        address deployedMintPass,
        address admin,
        address payable _obscuraTreasury
    ) randomiser(1) {
        magnum = IObscuraMagnum(deployedMagnum);
        mintPass = IObscuraMintPass(deployedMintPass);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
         _setupRole(MODERATOR_ROLE, admin);
        _setupRole(MODERATOR_ROLE, msg.sender);
        obscuraTreasury = _obscuraTreasury;
    }

    function createProject(
        string memory artist,
        uint256 maxTokens,
        uint256 allowedPassId
    ) external onlyRole(MODERATOR_ROLE) {
        require(maxTokens < DIVIDER, "Cannot exceed 100,000");
        require(bytes(artist).length > 0, "Artist name missing");

        uint256 projectId = nextProjectId += 1;

        projects[projectId] = Project({
            artist: artist,
            maxTokens: maxTokens,
            circulatingPublic: 0,
            isSaleActive: false,
            cid: defaultCID,
            royalty: defaultRoyalty,
            allowedPassId: allowedPassId
        });
        setNumTokensLeft(projectId, maxTokens);
    }

    function mint(uint256 projectId) external {
        Project memory project = projects[projectId];

        require(project.maxTokens > 0, "Project doesn't exist");
        require(project.isSaleActive, "Public sale is not open");
        uint256 circulatingPublic = projects[projectId].circulatingPublic += 1;
        require(
            circulatingPublic <= project.maxTokens,
            "All public sale tokens have been minted"
        );

        uint randomizedTokenId = (projectId * DIVIDER) + randomTokenURI(projectId,random());


        projectToTokenClaimed[projectId][randomizedTokenId] = true;
        tokenIdToProject[randomizedTokenId] = projectId;

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

        magnum.mintTo(msg.sender, projectId, randomizedTokenId);
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
        magnum.setProjectCID(projectId, cid);
    }

    function setTokenCID(uint256 tokenId, string calldata cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        magnum.setTokenCID(tokenId, cid);
    }

    function setDefaultCID(string calldata _defaultCID)
        external
        onlyRole(MODERATOR_ROLE)
    {
        magnum.setDefaultPendingCID(_defaultCID);
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
