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

//import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./AccessControlEnumerable.sol";
import "./IERC2981.sol";
import "./Strings.sol";

import "./IObscuraCommunity.sol";

import "./IRNG2.sol";
import "./IRNG_multi_requestor.sol";
import "./randomiser.sol";

import "./console.sol";

contract ObscuraCommunity is ERC721, AccessControlEnumerable, IERC2981, IObscuraCommunity {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private constant DIVIDER = 10**5;
    uint256 private nextProjectId;
    uint256 private defaultRoyalty;
    address private _obscuraAddress;
    string private _contractURI;
    string private _defaultPendingCID;
    string private constant dedication = "https://twitter.com/AppletonDave/status/1504585902160760834";

    mapping(uint256 => string) public  tokenIdToCID;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => uint256) public requestToProject;
    

    
    mapping (bytes32 => uint256[])     waiting;
    uint256                            nextRandomPos = 1;
    mapping(uint256 => uint256)        nextPlaceholder;

    mapping(uint256 => mapping(uint256 => uint256)) tokenIDz;

    // one mint = 1 x 1 photo per artist
    // thus there are #photosPerArtist mints available in a foundry event.

    struct Project {
        uint16 publicMinted;
        uint16 platformMinted;
        uint16 photosPerArtist;
        uint256 royalty;
        string projectName;      // for info only
        string cid;         // root of /artist/multiplePhotoMetadata structure
    }

    event ProjectCreated(
        address caller, 
        uint256 indexed projectId
    );

    event ProjectRandomReceived(
        uint256 projectID,
        uint256[] randoms
    );

    event SetProjectCID(
        address caller,
        uint256 indexed projectId,
        string cid
    );

    event SetTokenCID(address caller, uint256 tokenId, string cid);

    event SetSalePublic(
        address caller,
        uint256 indexed projectId,
        bool isSalePublic
    );

    event ProjectMinted(
        address user,
        uint256 indexed projectId,
        uint256 tokenId
    );

    event ProjectMintedByToken(
        address user,
        uint256 indexed projectId,
        uint256 tokenId
    );

    event ObscuraAddressChanged(address oldAddress, address newAddress);

    event WithdrawEvent(address caller, uint256 balance);

    constructor(address admin, address payable obscuraAddress)
        ERC721("Obscura Community", "OC") 
    {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, admin);
        _setupRole(MODERATOR_ROLE, msg.sender);
        _obscuraAddress = obscuraAddress;
        defaultRoyalty = 100; // 10%
       
    } 

    function setMinter(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, _minter);
    }

    function isMinter(address query) external view returns (bool) {
        return hasRole(MINTER_ROLE, query);
    }

    function _tokenIdToProject(uint256 tokenId) internal pure returns (uint256) {
        return tokenId / DIVIDER;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token doesn't exist");
        uint256 projectId = _tokenIdToProject(tokenId);
        uint256 _royaltyAmount = (salePrice * projects[projectId].royalty) /
            1000;

        return (_obscuraAddress, _royaltyAmount);
    }

    function setDefaultRoyalty(uint256 royaltyPercentPerMille)
        public
        onlyRole(MODERATOR_ROLE)
    {
        defaultRoyalty = royaltyPercentPerMille;
    }

    function setProjectRoyalty(uint256 projectId, uint256 royaltyPercentPerMille)
        public
        onlyRole(MODERATOR_ROLE)
    {
        projects[projectId].royalty = royaltyPercentPerMille;
    }

    function setContractURI(string memory contractURI_)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _contractURI = contractURI_;
    }

    function setProjectCID(uint256 projectId, string calldata cid)
        external override
        onlyRole(MODERATOR_ROLE)
    {
        projects[projectId].cid = cid;

        emit SetProjectCID(msg.sender, projectId, cid);
    }

    function setTokenCID(uint256 tokenId, string calldata cid)
        external override
        onlyRole(MODERATOR_ROLE)
    {
        tokenIdToCID[tokenId] = cid;

        emit SetTokenCID(msg.sender, tokenId, cid);
    }

    function setDefaultPendingCID(string calldata defaultPendingCID)
        external override
        onlyRole(MODERATOR_ROLE)
    {
        _defaultPendingCID = defaultPendingCID;
    }


    function setObscuraAddress(address newObscuraAddress)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _obscuraAddress = payable(newObscuraAddress);
        emit ObscuraAddressChanged(_obscuraAddress, newObscuraAddress);
    }

    function createProject(
        string memory _projectName,
        uint16 _photosPerArtist,
        string memory cid
    ) external override onlyRole(MINTER_ROLE) {
       require(bytes(_projectName).length > 0, "Artist name missing");
        uint256 projectId = nextProjectId += 1;

        projects[projectId] = Project({
            photosPerArtist : _photosPerArtist,
            projectName: _projectName,
            publicMinted: 0,
            platformMinted: 0,
            cid: cid,
            royalty: defaultRoyalty
        });

        emit ProjectCreated(msg.sender, projectId);
    }

    function latestProject() external view returns (uint256) {
        return nextProjectId;
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function mintTo( // passes burden to the minter to allocate the tokenIds
        address to,
        uint256 projectId,
        uint256 passID
    ) external  override onlyRole(MINTER_ROLE) {
        _mintTo(to,projectId,passID);
    }

    function mintBatch( // passes burden to the minter to allocate the tokenIds
        address to,
        uint256 projectId,
        uint32[] memory  tokenIDs
    ) external  override onlyRole(MINTER_ROLE) {
        // Project memory project = projects[projectId];
        // project.publicMinted = project.publicMinted + uint16(tokenIDs.length);
        uint256 prefix = projectId * DIVIDER;
        projects[projectId].publicMinted += uint16(tokenIDs.length);
        for (uint j = 0; j < tokenIDs.length; j++) {
             _mint(to, tokenIDs[j]+ prefix);
             emit ProjectMinted(to, projectId, tokenIDs[j]);
        }
    }


    function _mintTo( // passes burden to the minter to allocate the tokenIds
        address to,
        uint256 projectId,
        uint256 tokenID
    ) internal {
        Project memory project = projects[projectId];
        project.publicMinted += 1;
        // can we mint any more ?

        _mint(to, tokenID);
        emit ProjectMinted(to, projectId, tokenID);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory tokenCID = tokenIdToCID[tokenId];

        if (bytes(tokenCID).length > 0) {
            return string(abi.encodePacked("https://arweave.net/", tokenCID));
        }

        uint256 projectId = _tokenIdToProject(tokenId);
        Project memory thisProject = projects[projectId];
        string memory projectCID = thisProject.cid;

        if (bytes(projectCID).length > 0) { //&& ((tid) <= (thisProject.photosPerArtist * thisProject.numberOfArtists))){
            uint256 tid = (tokenId % DIVIDER)-1;
            uint256 folder = (tid / thisProject.photosPerArtist) + 1;
            uint256 photo  = (tid % thisProject.photosPerArtist) + 1;
            return
                string(
                    abi.encodePacked(
                        "https://arweave.net/",
                        projectCID,
                        "/",
                        folder.toString(),
                        "/",
                        photo.toString()
                    )
                );
        }

        return
            string(
                abi.encodePacked("https://arweave.net/", _defaultPendingCID)
            );
    }

 
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}
