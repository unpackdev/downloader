// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

         `````                 `````                                                                                                                  
        /NNNNN.               /NNNNN`                                                                                                                 
        /MMMMM.               +MMMMM`                                                                                                                 
        :hhhhh/::::.     -::::sMMMMM`         ``````      ``````````       `...`        ```````     `         `  ````````          ```                
         `````mNNNNs     NNMNFTMMMMM`       ``bddddd.`    mmdddddddd``  .odhyyhdd+`  ``sddddddd/`  gm-       gm/ dmhhhhhhdh+`    `/dddo`              
              mMMMMy     NMMMMMMMMMM`     ``bd-.....bd-`  MM........mm `mM:`` `.oMy  sm/.......sd: gM-       gM+ NM-`````.sMy  `/do...+do`            
              oWAGMI+++++GMMMMMMMMMM`     gm:.      ..gm. MM        MM `NM:.     /:  yM/       `.` gM-       gM+ NM`      :Md /ms.`   `.+mo           
                   /MMMMM`    +MMMMM`     GM.         gM- GMdddddddd:-  -ydhhhs+:.   yM/           gM-       gM+ NM+////+smh. +Ms       +Ms           
                   /MMMMM`    +MMMMM`     GM.         gM- MM::::::::hh    `.-:/ohmh. yM/           gM-       gM+ NMsoooooyNy` +MdsssssssGMs           
              yMMMMs:::::yMMMMMMMMMM`     yh/:      -:yh. MM        MM /h/       sMs yM/       .:` gM/       gM/ NM`      sM+ +Md+++++++GMs           
              gMMMMs     M.OBSCURA.M`       yh/:::::yh.   MM::::::::hh .gM+..``.:CR: oh+:::::::sh: :Nm/.``..oMh` NM`      :My +Ms       +Ms .:.       
         `````mNNNNs     MMMMM'21'MM`         ahhhhh`     hhhhhhhhhh`   `/ydhhhhho.    ohhhhhhh:    .+hdhhhdy/`  hh`      `hy`/h+       /h+ :h+       
        /mmmmm-....`     .....gMMMMM`                                        ``                         ```                                           
        /MMMMM.               +MMMMM`                                                                                                                 
        :mmmmm`               /mmmmm`                                                                                                                 

*/

import "./IObscuraCurated.sol";
import "./IObscuraMintPass.sol";
import "./AccessControlEnumerable.sol";

contract ObscuraMinter is AccessControlEnumerable {
    bytes32 private constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    address private _obscuraAddress;
    uint256 private nextDropId;
    uint256 private nextPassDropId;

    IObscuraCurated private curated;
    IObscuraMintPass private mintPass;
    mapping(uint256 => mapping(uint256 => bool)) public mpToTokenClaimed;
    mapping(uint256 => uint256) public mpToProjectClaimedCount;
    mapping(uint256 => ProjectDrop) public projectDrops;
    mapping(uint256 => PassDrop) public passDrops;

    struct ProjectDrop {
        uint256 circulatingPublic;
        uint256 maxPublic;
        uint256 allowedPassId;
    }

    struct PassDrop {
        uint256 circulatingPublic;
        uint256 maxPublic;
        uint256 passPrice;
    }

    event ObscuraAddressChanged(address oldAddress, address newAddress);

    event SeasonPassBySelectClaimEvent(
        address user,
        uint256 mintPassTokenId,
        uint256 tokenId,
        uint256 projectId,
        uint256 dropId
    );

    constructor(
        address deployedCurated,
        address deployedMintPass,
        address admin,
        address payable obscuraAddress
    ) {
        curated = IObscuraCurated(deployedCurated);
        mintPass = IObscuraMintPass(deployedMintPass);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _obscuraAddress = obscuraAddress;
    }

    function setObscuraAddress(address newObscuraAddress)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _obscuraAddress = payable(newObscuraAddress);

        emit ObscuraAddressChanged(_obscuraAddress, newObscuraAddress);
    }

    function createPassDrop(uint256 passId, uint256 maxPublic)
        external
        onlyRole(MODERATOR_ROLE)
    {
        require(mintPass.getPassMaxTokens(passId) > 0, "Pass doesn't exist");

        uint256 passPrice = mintPass.getPassPrice(passId);

        passDrops[nextPassDropId += 1] = PassDrop({
            circulatingPublic: 0,
            maxPublic: maxPublic,
            passPrice: passPrice
        });
    }

    function setDropAllowedPassId(uint256 dropId, uint256 newPassId)
        external
        onlyRole(MODERATOR_ROLE)
    {
        projectDrops[dropId].allowedPassId = newPassId;
    }

    function createProjectDrop(uint256 projectId, uint256 allowedPassId)
        external
        onlyRole(MODERATOR_ROLE)
    {
        uint256 maxPublic = curated.getProjectMaxPublic(projectId);
        uint256 _allowedPassId = allowedPassId;
        require(maxPublic > 0, "Project doesn't exist");

        projectDrops[nextDropId += 1] = ProjectDrop({
            circulatingPublic: 0,
            maxPublic: maxPublic,
            allowedPassId: _allowedPassId
        });
    }

    function mintMintPass(uint256 passDropId, uint256 passId) external payable {
        bool isSalePublic = mintPass.isSalePublic(passId);
        require(isSalePublic == true, "Public sale is not open");
        passDrops[passId].circulatingPublic += 1;
        PassDrop memory passDrop = passDrops[passDropId];
        require(passDrop.maxPublic > 0, "Pass drop doesn't exist");
        require(
            passDrop.circulatingPublic <= passDrop.maxPublic,
            "All public tokens have been minted"
        );
        require(
            msg.value == passDrop.passPrice,
            "Incorrect amount of ether sent"
        );

        mintPass.mintTo(msg.sender, passId);
    }

    function claimWithSeasonPassBySelect(
        uint256 dropId,
        uint256 projectId,
        uint256 tokenId
    ) external {
        bool isSalePublic = curated.isSalePublic(projectId);
        require(isSalePublic == true, "Public sale is not open");
        projectDrops[dropId].circulatingPublic += 1;
        ProjectDrop memory projectDrop = projectDrops[dropId];
        require(projectDrop.maxPublic > 0, "ProjectDrop doesn't exist");
        require(
            projectDrop.circulatingPublic <= projectDrop.maxPublic,
            "All public tokens have been minted"
        );

        require(tokenId <= projectDrop.maxPublic, "Token ID not in range");
        uint256 mintPassBalance = mintPass.balanceOf(msg.sender);
        require(mintPassBalance > 0, "User has no season pass");
        uint256 allowedPassId = projectDrop.allowedPassId;

        uint256 mintPassTokenId;
        for (uint256 i = 0; i < mintPassBalance; i++) {
            uint256 mpTokenId = mintPass.tokenOfOwnerByIndex(msg.sender, i);
            uint256 tokenPassId = mintPass.getTokenIdToPass(mpTokenId);
            // if its the same pass id and if the token isnt claimed than return it!
            if (
                allowedPassId == tokenPassId &&
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
        require(projectDrop.allowedPassId == passId, "Ineligible pass ID");

        mpToTokenClaimed[projectId][mintPassTokenId] = true;
        mpToProjectClaimedCount[projectId] += 1;
        curated.mintToBySelect(msg.sender, projectId, tokenId);

        emit SeasonPassBySelectClaimEvent(
            msg.sender,
            mintPassTokenId,
            tokenId,
            projectId,
            dropId
        );
    }

    function withdraw() public onlyRole(MODERATOR_ROLE) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_obscuraAddress).call{value: balance}("");
        require(success, "Withdraw: unable to send value");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
