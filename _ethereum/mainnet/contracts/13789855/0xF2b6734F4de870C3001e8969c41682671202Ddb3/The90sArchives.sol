// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

//
//╭━━━┳━━━╮╱╱╭━━━╮╱╱╱╱╭╮
//┃╭━╮┃╭━╮┃╱╱┃╭━╮┃╱╱╱╱┃┃
//┃╰━╯┃┃┃┃┣━━┫┃╱┃┣━┳━━┫╰━┳┳╮╭┳━━┳━━╮
//╰━━╮┃┃┃┃┃━━┫╰━╯┃╭┫╭━┫╭╮┣┫╰╯┃┃━┫━━┫
//╭━━╯┃╰━╯┣━━┃╭━╮┃┃┃╰━┫┃┃┃┣╮╭┫┃━╋━━┃
//╰━━━┻━━━┻━━┻╯╱╰┻╯╰━━┻╯╰┻╯╰╯╰━━┻━━╯
//

import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./I90Archive.sol";

contract The90sArchives is ERC721Enumerable, Ownable {


    struct The90sArchivesStruct {
        uint256 bg;
        uint256 skin;
        uint256 mouth;
        uint256 cloth1;
        uint256 cloth2;
        uint256 cloth3;
        uint256 hair;
        uint256 eyes;
        uint256 ear1;
        uint256 ear2;
        uint256 headwear;
        uint256 headgear;
        uint256 extra;
    }

    struct The90sArchiveParts {
        address owner;
        uint256 partInTheBody;
    }

    // ManagerInterface public manager;
    using Strings for uint256;

    /// @dev Emitted when {startPreSale} is executed and the presale isn't on.
    event PreSaleStarted();
    /// @dev Emitted when {startSale} is executed and the sale isn't on.
    event SaleStarted();
    /// @dev Emitted when {pauseSale} is executed and the sale is on.
    event SalePaused();
    /// @dev Emitted when {SetPresaleWhitelist} is executed and the sale is on.
    event SetPresaleWhitelist();
    /// @dev Emitted when {SetSpecialWhitelist} is executed and the sale is on.
    event SetSpecialWhitelist();
    /// @dev Emitted when {SetTargetNFTWhitelist} is executed and the sale is on.
    event SetTargetNFTWhitelist();
    /// @dev Emitted when {SetPriorityNFTWhitelist} is executed and the sale is on.
    event SetPriorityNFTWhitelist();
    /// @dev Emitted when {SetOGNFTWhitelistLimit} is executed and the sale is on.
    event SetOGNFTWhitelistLimit();
    /// @dev Emitted when {startSale} is executed for the first time.
    event ClaimsReserveUpdated(uint256 indexed reserve);
    /// @dev Emitted when a The90s token is claimed based on a Rat held
    event ArchiveClaimed(uint256 indexed ratId, uint256 indexed goodGuyId);
    /// @dev Emitted when {reveal} is executed.
    event Reveal(uint256 indexed startingIndex);
    /// @dev Emitted when {setTokenURI} is executed.
    event TokenURISet(string indexed tokenUri);
    /// @dev Emitted when {lockTokenURI} is executed (once-only).
    event TokenURILocked(string indexed tokenUri);
    /// @dev Emitted when owners of deadbod parts have been set.
    event SetArchivePartsOwner();
    /// @dev Emitted when the reserved 90s archieves have been minted
    event MintReserveArchives();
    /// @dev Emitted when the influencer 90s archieves have been minted
    event MintInfluencerArchives();
    /// @dev Emitted when the public 90s archieves have been minted
    event MintPublicArchives();

    IERC721 public BAYC = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    string public The90sArchives_PROVENANCE = "";
    bool private onTransfer = true;
    uint256 public constant MAX_The90s_SUPPLY = 9090;
    uint256 public PUBLIC_CAP = 5000;
    uint256 public The90s_PACK_LIMIT = 10;
    uint256 public The90s_PRICE = 6 ether / 100;
    uint256 public The90s_PRICE_PRESALE = 4 ether / 100;
    uint256 private constant CLAIM_PERIOD_DURATION = 1 weeks;
    string private constant PLACEHOLDER_SUFFIX = "";
    string private constant METADATA_INFIX = "metadata/";

    uint256 public startingIndex = 300;
    uint256 public remainIndex = 0;
    // uint256[] public remainArchive;
    bool public preSaleStarted;
    bool public saleStarted;
    uint256 public saleStartedAt;
    bool public tokenURILocked;
    mapping (address => bool) public preSaleWhitelist;
    mapping (address => bool) public specialWhitelist;
    mapping (uint256 => address) public targetNFTWhitelist; //Obsoleted
    mapping (uint256 => address) public priorityNFTWhitelist; //Obsoleted
    mapping (address => uint256) public OGNFTWhitelistLimit;
    mapping(uint256 => The90sArchivesStruct) public deadbod;
    mapping(uint256 => The90sArchiveParts) public deadpart;

    // current metadata base prefix
    string private _baseTokenUri;

    // prevent callers from sending ETH directly
    receive() external payable {
        revert();
    }

    // prevent callers from sending ETH directly
    fallback() external payable {
        revert();
    }

    constructor() ERC721("The90sArchives", "DeadBod") {
    }

    // ----- PUBLIC -----
    // ------------------
     /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        The90sArchives_PROVENANCE = provenanceHash;
    }

    function setCollabContract(address _addr) public onlyOwner {
        BAYC = IERC721(_addr);
    }

    function checkCollabBalance() public view returns(uint256) {
        return BAYC.balanceOf(msg.sender);
    }

    function setStartIndexPublicSale(uint256 index) public onlyOwner {
        startingIndex = index;
        emit Reveal(startingIndex);
    }

    function setPublicCapRound(uint256 cap) public onlyOwner {
        PUBLIC_CAP = cap;
    }

    function setArchivesPrice(uint256 price) public onlyOwner {
        The90s_PRICE = (price * 1 ether ) / 100;
    }

    function setPackLimit(uint256 limit) public onlyOwner {
        The90s_PACK_LIMIT = limit;
    }

    function startPreSale() public onlyOwner {
        // will also restart when on pause
        if (!preSaleStarted) {
            preSaleStarted = true;
            emit PreSaleStarted();
        }
    }

    function setTransfer(bool tran) public onlyOwner {
        onTransfer = tran;
    }

    function setArchivePartsOwner(uint256[] memory partIDs, address[] memory _owner, uint256[] memory bodySection) public onlyOwner {
        require(partIDs.length == _owner.length, "Number of body parts and owners must be equal");
        require(partIDs.length == bodySection.length, "Number of body parts and bodySection must be equal");
        for (uint256 i = 0; i < partIDs.length; i++) {
            deadpart[partIDs[i]] = The90sArchiveParts({
                owner : _owner[i],
                partInTheBody : bodySection[i]
            });
        }
    }

    function preSetTraitNFTs(uint256[] memory tokenIDs, uint256[] memory archiveTraits) public onlyOwner {
        require(tokenIDs.length * 10 == archiveTraits.length, "Number of traits must equal to number of tokens*attr");

        uint256 j = 0;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            deadbod[tokenIDs[i]] = The90sArchivesStruct({
                    bg : archiveTraits[j],
                    skin : archiveTraits[j+1],
                    mouth : archiveTraits[j+2],
                    cloth1 : archiveTraits[j+3],
                    cloth2 : archiveTraits[j+4],
                    cloth3 : archiveTraits[j+5],
                    hair : archiveTraits[j+6],
                    eyes : archiveTraits[j+7],
                    ear1 : archiveTraits[j+8],
                    ear2 : archiveTraits[j+9],
                    headwear : archiveTraits[j+10],
                    headgear : archiveTraits[j+11],
                    extra : archiveTraits[j+12]
                });
                j += 10;
        }
    }

    function pausePreSale() public onlyOwner {
        // will also restart when on pause
        if (preSaleStarted) {
            preSaleStarted = false;
        }
    }

    /*
     * @dev Start or restart distribution. Only callable by the owner.
     * On the first call,
     * - set claim reserve value (once-only)
     * - set sale start timestamp and emit {ClaimsReserveUpdated} (once-only)
     * - emit {SaleStarted}
     *
     * On subsequent calls,
     * - restart sale and emit {SaleStarted} if paused;
     *   otherwise, do nothing
     */
    function startSale() public onlyOwner {
        // will also restart when on pause
        if (!saleStarted) {
            saleStarted = true;
            emit SaleStarted();
        }
        // once-only: set timestamp and update reserve
        if (saleStartedAt == 0) {
            saleStartedAt = block.timestamp;
        }
    }

    /*
     * @dev If sale is on, pause it and emit {SalePaused}; otherwise, do nothing.
     *   Only callable by the owner.
     */
    function pauseSale() public onlyOwner {
        if (saleStarted) {
            saleStarted = false;
            emit SalePaused();
        }
    }

    function setPresaleWhitelist(address[] memory account, bool isAdd) external onlyOwner {
        for(uint256 i=0; i < account.length; i++) {
            preSaleWhitelist[account[i]] = isAdd;
        }

        emit SetPresaleWhitelist();
    }

    function setSpecialWhitelist(address[] memory account, bool isAdd) external onlyOwner {
        for(uint256 i=0; i < account.length; i++) {
            specialWhitelist[account[i]] = isAdd;
        }

        emit SetSpecialWhitelist();
    }

    //Obsoleted
    function setTargetNFTWhitelist(address[] memory account, uint256[] memory tokenId) external onlyOwner {
        require(account.length == tokenId.length, "No of accounts & tokens don't match");
        for(uint256 i=0; i < tokenId.length; i++) {
            targetNFTWhitelist[tokenId[i]] = account[i];
        }

        emit SetTargetNFTWhitelist();
    }

    //Obsoleted
    function setPriorityNFTWhitelist(address[] memory account, uint256[] memory tokenId) external onlyOwner {
        require(account.length == tokenId.length, "No of accounts & tokens don't match");
        for(uint256 i=0; i < tokenId.length; i++) {
            priorityNFTWhitelist[tokenId[i]] = account[i];
        }

        emit SetPriorityNFTWhitelist();
    }

    function setOGNFTWhitelistLimit(address[] memory account, uint256[] memory limit) external onlyOwner {
        require(account.length == limit.length, "No of accounts & tokens don't match");
        for(uint256 i=0; i < limit.length; i++) {
            OGNFTWhitelistLimit[account[i]] = limit[i];
        }

        emit SetOGNFTWhitelistLimit();
    }


    /**
     * @dev Mint `numberOfThe90ss` 90Archives.
     * - Will only mint up to (`MAX_The90s_SUPPLY` - `ratClaimsReserve`) 90Archives.
     * - Will mint up to `The90s_PACK_LIMIT` items at once.
     * - Will only mint after the sale is started.
     * - ETH sent must equal (`numberOfThe90ss` * `The90s_PRICE`)
     *
     * @param numberOfThe90s The number of 90Archives NFTs to mint.
     */
    function mintThe90sPreSale(uint256 numberOfThe90s) public payable returns (uint256[] memory){
        //Whitelisted
        if(preSaleStarted){
            require(preSaleWhitelist[msg.sender], "You are not in the private list");
        }else{
            _enforceSaleStarted();
        }
        require(startingIndex + totalSupply() <= MAX_The90s_SUPPLY, "Archieves sold out");
        require(balanceOf(msg.sender) + numberOfThe90s <= The90s_PACK_LIMIT + OGNFTWhitelistLimit[msg.sender], "Buy limit exceeded");
        require(numberOfThe90s > 0, "Need to mint at least one");
        require(The90s_PRICE_PRESALE * numberOfThe90s == msg.value, "Invalid ETH Amount");

        uint256[] memory resultIDs = new uint256[](numberOfThe90s);
        //Minting loop
        for (uint256 i = 0; i < numberOfThe90s; i++) {
            // require(!_exists(archiveIDs[i]), "ERC721: token already minted");
            // require(targetNFTWhitelist[archiveIDs[i]] == msg.sender, "This token is reserved by others");
            // _safeMint(msg.sender, archiveIDs[i]);
            uint256 tokenId = totalSupply() + startingIndex + 1;
            _safeMint(msg.sender, tokenId);
            resultIDs[i] = tokenId;
        }

        emit MintReserveArchives();
        return resultIDs;

    }

    /**
     * @dev Mint `numberOfThe90s` 90Archives.
     * - Will only mint up to (`MAX_The90s_SUPPLY` - `ratClaimsReserve`) 90Archives.
     * - Will mint up to `The90s_PACK_LIMIT` items at once.
     * - Will only mint after the sale is started.
     * - ETH sent must equal (`numberOfThe90ss` * `The90s_PRICE`)
     *
     * @param numberOfThe90s The number of 90Archives NFTs to mint.
     */
    function mintThe90sPublic(uint256 numberOfThe90s) public payable returns (uint256[] memory){
        _enforceSaleStarted();
        require(startingIndex + totalSupply() <= MAX_The90s_SUPPLY, "Archieves sold out");
        require(startingIndex + totalSupply() <= PUBLIC_CAP, "Archieves exceeded this round");
        require(numberOfThe90s <= The90s_PACK_LIMIT, "Buy limit exceeded");
        require(numberOfThe90s > 0, "Need to mint at least one");
        if(BAYC.balanceOf(msg.sender) > 0 || specialWhitelist[msg.sender]){
            require(The90s_PRICE_PRESALE * numberOfThe90s == msg.value, "Invalid ETH Amount");
        }
        else{
            require(The90s_PRICE * numberOfThe90s == msg.value, "Invalid ETH Amount Public");
        }

        uint256[] memory resultIDs = new uint256[](numberOfThe90s);
        for (uint256 i = 0; i < numberOfThe90s; i++) {
            //Mint the remaining from reserve first
            // if(remainArchive.length > 0 && remainIndex < remainArchive.length){
            //     _safeMint(msg.sender, remainArchive[remainIndex]);
            //     remainIndex++;
            // }else{
            //     //Public sale token number starts from startingIndex
            //     // _safeMint(msg.sender, startingIndex);
            //     _safeMint(msg.sender, totalSupply() + startingIndex + 1);
            //     _calculateStartingIndex();
            // }
            uint256 tokenId = totalSupply() + startingIndex + 1;
            _safeMint(msg.sender, tokenId);
            resultIDs[i] = tokenId;
        }

        emit MintPublicArchives();
        return resultIDs;

    }

    function mintThe90sOG(uint256 numberOfThe90s) public returns (uint256[] memory){
        //Whitelisted
        require(startingIndex + totalSupply() <= MAX_The90s_SUPPLY, "Archieves sold out");
        require(numberOfThe90s <= The90s_PACK_LIMIT, "Buy limit exceeded");
        require(numberOfThe90s > 0, "Need to mint at least one");
        require(numberOfThe90s <= OGNFTWhitelistLimit[msg.sender], "Mint limit exceeded");

        uint256[] memory resultIDs = new uint256[](numberOfThe90s);
        //Minting loop
        for (uint256 i = 0; i < numberOfThe90s; i++) {
            // require(!_exists(archiveIDs[i]), "ERC721: token already minted");
            // _safeMint(msg.sender, archiveIDs[i]);
            // _safeMint(msg.sender, totalSupply() + 1);
            uint256 tokenId = totalSupply() + startingIndex + 1;
            _safeMint(msg.sender, tokenId);
            OGNFTWhitelistLimit[msg.sender] = OGNFTWhitelistLimit[msg.sender] - 1;
            resultIDs[i] = tokenId;
        }

        emit MintInfluencerArchives();
        return resultIDs;

    }

    function mintThe90sAdmin(uint256[] memory archiveIDs, address[] memory receivers) public onlyOwner {
        require(totalSupply() <= MAX_The90s_SUPPLY, "Archieves sold out");
        require(archiveIDs.length > 0, "Need to mint at least one");
        require(archiveIDs.length == receivers.length, "Number of tokens and receivers must be equal");

        //Minting loop
        for (uint256 i = 0; i < archiveIDs.length; i++) {
            require(!_exists(archiveIDs[i]), "ERC721: token already minted");
            _safeMint(receivers[i], archiveIDs[i]);
        }

    }

    /**
     * @dev Change traits of the minted 90Archives NFT
     *
     * @param tokenId Token id of the 90Archives NFTs to be changed.
     * @param traits traits of the 90Archives deadbods.
     */
    function changeTraits(uint256 tokenId, uint256[] memory traits) public payable {
        _enforceSaleStarted();
        require(ownerOf(tokenId) == msg.sender , "Need to be the archive owner to change traits");
        //Add available traits conditions
        require(traits.length == 10, "Invalid number of traits");
            deadbod[tokenId] = The90sArchivesStruct({
                bg : traits[0],
                skin : traits[1],
                mouth : traits[2],
                cloth1 : traits[3],
                cloth2 : traits[4],
                cloth3 : traits[5],
                hair : traits[6],
                eyes : traits[7],
                ear1 : traits[8],
                ear2 : traits[9],
                headwear : traits[10],
                headgear : traits[11],
                extra : traits[12]
            });
    }

    /**
     * @dev Set base token URI. Only callable by the owner and only
     * if token URI hasn't been locked through {lockTokenURI}. Emit
     * TokenURISet with the new value on every successful execution.
     *
     * @param newUri The new base URI to use from this point on.
     */
    function setTokenURI(string memory newUri)
        public
        onlyOwner
        whenUriNotLocked
    {
        _baseTokenUri = newUri;
        emit TokenURISet(_baseTokenUri);
    }

    function withdraw() public onlyOwner returns (bool success) {
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }

    /**
     * @dev Prior to execution of {reveal}, return the placeholder URI for
     * any token minted or claimed; after the execution of {reveal}, return
     * adjusted URIs based on `startingIndex` cyclic shift.
     *
     * @param tokenId Identity of an existing (minted) The90s NFT.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "UnknownTokenId");

        string memory result = indexedTokenURI(tokenId);

        return result;
    }

    // ---- INTERNAL ----
    // ------------------

    function claimPeriodInProgress() internal view returns (bool) {
        return (block.timestamp <= (saleStartedAt + CLAIM_PERIOD_DURATION));
    }

    function _enforceSaleStarted() internal view {
        require(saleStarted, "SaleNotOn");
    }

    function _enforceClaimPeriod(bool on) internal view {
        if (on) {
            require(claimPeriodInProgress(), "ClaimPeriodHasEnded");
        } else {
            require(!claimPeriodInProgress(), "ClaimPeriodHasntEnded");
        }
    }

    function _calculateStartingIndex() internal {
        startingIndex++;
    }

    modifier whenUriNotLocked() {
        require(!tokenURILocked, "TokenURILockedErr");
        _;
    }

    function placeholderURI() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    METADATA_INFIX,
                    PLACEHOLDER_SUFFIX
                )
            );
    }

    function indexedTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    METADATA_INFIX,
                    tokenId.toString()
                    // ".json"
                )
            );
    }

    // function _transfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal override {
    //     require(onTransfer, "Transfer not on" );
    //     super._transfer(from, to, tokenId);
    // }
}
