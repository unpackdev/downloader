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
import "./ERC721X.sol";
import "./AccessControlEnumerable.sol";
import "./IERC2981.sol";
import "./Strings.sol";

import "./IRNG.sol";
import "./IRNGrequestor.sol";
import "./randomiser.sol";

import "./console.sol";

contract ObscuraFoundry is ERC721X, AccessControlEnumerable, IERC2981, IRNGrequestor, randomiser {
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
    

    IRNG                               rng;
    mapping (bytes32 => uint256[])     waiting;
    uint256                            nextRandomPos = 1;
    mapping(uint256 => uint256)        nextPlaceholder;

    // one mint = 1 x 1 photo per artist
    // thus there are #photosPerArtist mints available in a foundry event.

    struct Project {
        uint16 numberOfArtists;
        uint16 photosPerArtist;      
        uint16 publicMinted;
        uint16 platformMinted;
        uint16 platformMintingReserve; // number of MINTS reserved for obscura use. Cannot be public Minted
        uint16 firstRandom;
        uint256 royalty;
        bool active;        // can be redeemed
        string projectName;      // for info only
        string cid;         // root of /artist/multiplePhotoMetadata structure
    }

    event ProjectCreatedEvent(address caller, uint256 indexed projectId);

    event SetProjectCIDEvent(
        address caller,
        uint256 indexed projectId,
        string cid
    );

    event SetTokenCIDEvent(address caller, uint256 tokenId, string cid);

    event SetSalePublicEvent(
        address caller,
        uint256 indexed projectId,
        bool isSalePublic
    );

    event ProjectMintedEvent(
        address user,
        uint256 indexed projectId,
        uint256 tokenId
    );

    event ProjectMintedByTokenEvent(
        address user,
        uint256 indexed projectId,
        uint256 tokenId
    );

    event ObscuraAddressChanged(address oldAddress, address newAddress);

    event WithdrawEvent(address caller, uint256 balance);

    constructor(address admin, address payable obscuraAddress, IRNG _rng)
        ERC721X("Obscura Foundry", "OF") randomiser(1)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, admin);
        _setupRole(MODERATOR_ROLE, msg.sender);
        _obscuraAddress = obscuraAddress;
        defaultRoyalty = 100; // 10%
        rng = _rng;
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
        external
        onlyRole(MODERATOR_ROLE)
    {
        projects[projectId].cid = cid;

        emit SetProjectCIDEvent(msg.sender, projectId, cid);
    }

    function setTokenCID(uint256 tokenId, string calldata cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        tokenIdToCID[tokenId] = cid;

        emit SetTokenCIDEvent(msg.sender, tokenId, cid);
    }

    function setDefaultPendingCID(string calldata defaultPendingCID)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _defaultPendingCID = defaultPendingCID;
    }

    function setSalePublic(uint256 projectId, bool _isSalePublic)
        external
        onlyRole(MODERATOR_ROLE)
    {
        projects[projectId].active = _isSalePublic;

        emit SetSalePublicEvent(msg.sender, projectId, _isSalePublic);
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
        uint16 _numberOfArtists,
        uint16 _photosPerArtist,
        uint16 _platformMintingReserve, 
        string memory cid
    ) external onlyRole(MINTER_ROLE) {
        uint16 numberOfTokens = _numberOfArtists * _photosPerArtist;
        require(numberOfTokens < DIVIDER / 2, "Total tokens in drop cannot exceed 50,000");
        require(bytes(_projectName).length > 0, "Artist name missing");
        require(
            _platformMintingReserve < _photosPerArtist,
            "Platform reserve too high."
        );

        uint256 projectId = nextProjectId += 1;
        uint16 randomPos = uint16(nextRandomPos);
        nextRandomPos += _numberOfArtists;

        projects[projectId] = Project({
            projectName: _projectName,
            numberOfArtists : _numberOfArtists,
            photosPerArtist : _photosPerArtist,
            publicMinted: 0,
            platformMinted: 0,
            platformMintingReserve: _platformMintingReserve,
            active: false,
            cid: cid,
            royalty: defaultRoyalty,
            firstRandom : randomPos
        });


        for (uint j = 0; j < _numberOfArtists; j++) {
            console.log("set R(",randomPos+j,") to ",_photosPerArtist);
            setNumTokensLeft(randomPos+j, _photosPerArtist);
        }

        nextPlaceholder[projectId] = 1;


        emit ProjectCreatedEvent(msg.sender, projectId);
    }

    function latestProject() external view returns (uint256) {
        return nextProjectId;
    }

    function mintPlatformReserve(
        address to,
        uint256 projectId
    ) external onlyRole(MINTER_ROLE) {
       _mintTo(to,projectId);
    }

    function mintTo( // passes burden to the minter to allocate the tokenIds
        address to,
        uint256 projectId
    ) external onlyRole(MINTER_ROLE) {
        _mintTo(to,projectId);
    }

    function _mintTo( // passes burden to the minter to allocate the tokenIds
        address to,
        uint256 projectId
    ) internal {
        Project memory project = projects[projectId];
        uint photosPerArtist = project.photosPerArtist;
        project.publicMinted += 1;
        // can we mint any more ?
        require( photosPerArtist - project.publicMinted - project.platformMintingReserve > 0,"No public mints left");

        uint256[] memory placeHolderRecord = new uint256[](project.numberOfArtists);
        uint tokenId = nextPlaceholder[projectId];
        for (uint j = 0; j < project.numberOfArtists; j++){
            uint256 newTokenId = (projectId * DIVIDER) + (DIVIDER/2) + tokenId++;
            console.log("minting ",newTokenId);
            placeHolderRecord[j] = newTokenId;
            _mint(to, newTokenId);
            emit ProjectMintedEvent(to, projectId, newTokenId);
        }
        bytes32 hash = rng.requestRandomNumberWithCallback();
        console.logBytes32(hash);
        waiting[hash] = placeHolderRecord;
        nextPlaceholder[projectId] = tokenId;
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

    function isSalePublic(uint256 projectId)
        external
        view
        returns (bool active)
    {
        return projects[projectId].active;
    }

    function getProjectMaxPublic(uint256 projectId)
        external
        view
        returns (uint16 maxTokens)
    {
        maxTokens = projects[projectId].numberOfArtists * projects[projectId].photosPerArtist;
        return
            maxTokens - projects[projectId].platformMintingReserve;
    }

    function getProjectCirculatingPublic(uint256 projectId)
        external
        view
        returns (uint256 maxTokens)
    {
        return
            projects[projectId].publicMinted -
            projects[projectId].platformMintingReserve;
    }

    function getProjectPlatformReserve(uint256 projectId)
        external
        view
        returns (uint256 platformReserveAmount)
    {
        return projects[projectId].platformMintingReserve;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721X, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function process(uint256 rand, bytes32 requestId) external override {
        uint256 random = rand;
        require(msg.sender == address(rng),"Unauthorised");
        uint256[] memory holders = waiting[requestId];
        uint256 projectID = holders[0] / DIVIDER;
        uint256 base      = (projectID * DIVIDER);
        Project memory project = projects[projectID];
        uint256 artistID = project.firstRandom;
        for (uint j = 0; j < holders.length; j++) {
            require(holders[j] != 0,"Invalid holder");
            uint256 randVal = random & 0xffff;
            random = random >> 16;
            uint randomizedTokenId =  base  + randomTokenURI(artistID++,randVal);
            base += project.photosPerArtist;
            console.log("reassign to ",randomizedTokenId);
            _reassign(holders[j], randomizedTokenId);
        } 
    }
}
