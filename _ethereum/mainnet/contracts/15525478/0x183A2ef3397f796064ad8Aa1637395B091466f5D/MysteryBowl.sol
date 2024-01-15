// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Base64Upgradeable.sol";

interface IAnomura {
    function mintAnomura(address _address) external returns (uint256 anomuraId);
    function mintMultiple(address _address, uint256[] calldata _tokenArray) external;
}

contract MysteryBowl is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    IAnomura public anomuraContract;
    struct XP {
        uint256 savedXP;
        uint256 lastSaveBlock;
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    string public bowlFull;
    string public bowlEmpty;

    /**
     * @dev
     * White List (1800 phase 1, 2000 phase 2)
     * Public List - no limited
     */

    uint256 public constant SALE_PRICE = 0.075 ether;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public maxTotalSupply;
    uint256 public maxMultiplier;
    
    /**
     * @dev Used to validate merke root
     */
    bytes32 public whiteListMerkleRoot;

    bool public isPaused;
    bool public isPublicSale;
    bool public canSetBowlStatus;
    /**
     * @dev Keep track of starfish from tokenId
     */
    mapping(uint256 => XP) public starfishMap;

    /**
     * @dev Keep track of bowl status, false by default
     */
    mapping(uint256 => bool) public bowls;

    /**
    * @dev Keep track of bowl minted per wallet
    */
    mapping(address => uint256) public bowlsMintedPerWallet;

    /// @dev Emit an event when the contract is deployed
    event ContractDeployed(
        address owner, 
        bool isPublicSale,
        bool isPaused,
        uint256 maxMultiplier
        );

    /// @dev Emit an event when the merkle root for team is updated
    event UpdatedMerkleRootOfTeamMint(bytes32 newHash, address updatedBy);

    /// @dev Emit an event when the merkle root for early list is updated
    event UpdatedMerkleRootOfEarlyListMint(bytes32 newHash, address updatedBy);

    /// @dev Emit an event when the merkle root for whitelist is updated
    event UpdatedMerkleRootOfWhiteListMint(bytes32 newHash, address updatedBy);

    /// @dev Emit an event when status of bowl is changed
    event UpdatedBowlStatus(uint256 bowlId, bool bowlStatus, address updatedBy);

    /// @dev Emit an event when public sale is changed
    event UpdatedIsPublicSale(bool isPublicSale, address updatedBy);

    /// @dev Emit an event when public sale is changed
    event UpdatedPauseContract(bool isPaused, address updatedBy);

    /// @dev Emit an event when starfish max multiplier is changed
    event UpdatedStarfishMaxMultiplier(uint256 multiplier, address updatedBy);

    /// @dev Emit an event when max whitelist supply is changed
    event UpdatedMaxWhiteListMint(uint256 maxWhiteList, address updatedBy);

    /// @dev Emit an event when anomura contract address is set
    event UpdatedAnomuraContractAddress(address anomuraAddress, address updatedBy);

    /// @dev Emit an event when bowl IPFS is changed
    event UpdatedBowlIPFS(string bowlImage, address updatedBy);

    /// @dev Emit an event when bowl empty IPFS is changed
    event UpdatedBowlEmptyIPFS(string bowlImage, address updatedBy);

    event UpdatedMaxTotalSupply(uint256 maxTotalSuppy, address updatedBy);

    function initialize() external initializer {
        __ERC721_init("Mystery Bowl", "Bowl");
        __ERC721Enumerable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        isPublicSale = false;
        isPaused = false;
        canSetBowlStatus = false;
        maxMultiplier = 24;
        bowlFull = "https://www.anomuragame.com/img/Bowl_With_Anomura.gif";
        bowlEmpty = "https://www.anomuragame.com/img/Bowl_Empty.gif";

        maxTotalSupply = 2000;

        // to have anomuraId starts at 1, instead of 0
        _tokenIds.increment();

        // emit event contract is deployed
        emit ContractDeployed(msg.sender, isPublicSale, isPaused, maxMultiplier);
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    /**
     * @dev To check if the origin is same as the address of the caller who calls this function
     */
    modifier isOrigin() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(msg.sender == tx.origin && size == 0, "Is not origin");
        _;
       
    }

    /**
     * @dev Throw when the submitted proof not valid under its root
     */
    modifier isValidMerkleProof(
        bytes32[] calldata _merkleProof,
        bytes32 _root
    ) {
        require(_root != "", "root is empty");
        require(
            MerkleProofUpgradeable.verify(
                _merkleProof,
                _root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    /**
     * @dev Throws if called when contract is paused.
     */
    modifier isNotPaused() {
        require(isPaused == false, "Contract Paused");
        _;
    }

    /**
     * @dev Throws if token not existed on contract.
     */
    modifier isTokenExist(uint256 _tokenId) {
        require(_exists(_tokenId), "Nonexistent token");
        _;
    }

    /**
     * @dev Throws if called by account with ether less than sale price, or when reach max total supply.
     */
    modifier canBulkMint(uint256 _quantity) {
        require(
            msg.value >= SALE_PRICE * _quantity,
            "Not enough ether to mint"
        );
        require(_quantity > 0, "Missing purchase quantity");
        require(totalSupply() + _quantity <= maxTotalSupply, "Reached Total Supply Limit");
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING =============

    /**
     * @notice mints 1 token per whitelist member address, charge a fee
     * @return mintId tokenId minted
     */
    function mintWhiteList(bytes32[] calldata _merkleProof, uint256 _quantity)
        external
        payable
        canBulkMint(_quantity)
        isValidMerkleProof(_merkleProof, whiteListMerkleRoot)
        isNotPaused
        nonReentrant
        returns (uint256 mintId)
    {
        require(bowlsMintedPerWallet[msg.sender] + _quantity <= MAX_PER_WALLET, "Mints per wallet exceeded");
        
        for (uint256 mintCounter = 0; mintCounter < _quantity; mintCounter++) {
            mintId = _tokenIds.current();
            _tokenIds.increment();
            bowlsMintedPerWallet[msg.sender]++;
            mint(mintId);
        }
    }

    /**
     * @dev Public mint token, charge a fee
     */
    function mintPublic(uint256 _quantity)
        external
        payable
        canBulkMint(_quantity)
        isNotPaused
        nonReentrant
        returns (uint256 mintId)
    {
        require(isPublicSale != false, "Sale is not public");

        for (uint256 mintCounter = 0; mintCounter < _quantity; mintCounter++) {
            mintId = _tokenIds.current();
            _tokenIds.increment();
            mint(mintId);
        }
    }

    /**
     * @dev Only Owner mint token. Do not check Max ToTAL SUPPLY.
     */
    function mintToWallet(uint256 _quantity, address _walletAddress)
        external
        isNotPaused
        nonReentrant
        onlyOwner
        returns (uint256 mintId)
    {
        for (uint256 mintCounter = 0; mintCounter < _quantity; mintCounter++) {
            mintId = _tokenIds.current();
            _tokenIds.increment();

            _safeMint(_walletAddress, mintId);
            starfishMap[mintId] = XP({savedXP: 0, lastSaveBlock: block.number});
            bowls[mintId] = true;
        }
    }

    /**
     * @notice Internal mint a bowl, called by other external mint functions
     * It sets the bowl to be not empty
     * It maps the bowl id to be owned by msg.sender
     * Start calculating starfish at current block number
     * @param _tokenId Id of the token
     */
    function mint(uint256 _tokenId) internal {
        _safeMint(msg.sender, _tokenId);
        starfishMap[_tokenId] = XP({savedXP: 0, lastSaveBlock: block.number});
        bowls[_tokenId] = true;
    }

    /**
     * @notice Summon an anomura from existing bowl
     * @param _tokenId Id of the Bowl
     */
    function hatchAnomura(uint256 _tokenId)
        external
        isTokenExist(_tokenId)
        isOrigin
        returns (uint256 anomuraId)
    {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Caller does not own this bowl."
        );
        require(bowls[_tokenId] == true, "Bowl is empty");
        require(
            address(anomuraContract) != address(0x0),
            "Anomura contract address is 0"
        );

        bowls[_tokenId] = false;

        anomuraId = anomuraContract.mintAnomura(msg.sender);

        // emit bowl status change to false
        emit UpdatedBowlStatus(_tokenId, false, msg.sender);
    }

    function starfish(uint256 _tokenId) public view returns (uint256 total) {
        uint256 lastBlock = starfishMap[_tokenId].lastSaveBlock;

        if (lastBlock == 0) {
            return 0;
        }
        uint256 delta = block.number - lastBlock; 
        uint256 multiplier = delta / 6000;
        if (multiplier > maxMultiplier) {
            multiplier = maxMultiplier;
        }

        total =
            starfishMap[_tokenId].savedXP +
            ((delta * (multiplier + 1)) / 10000);

        if (total < 1) total = 1;
    }

    function save(uint256 _tokenId) private {
        starfishMap[_tokenId].savedXP = starfish(_tokenId);
        starfishMap[_tokenId].lastSaveBlock = block.number;
    }

    /**
    @notice Takes a tokenId and returns base64 string to represent the Bowl metadata
    @param _tokenId Id of the token
    @return string base64
    */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        isTokenExist(_tokenId)
        returns (string memory)
    {
        string memory bowlImage = bowls[_tokenId] == true ? bowlFull : bowlEmpty;
        string memory bowlDescription = bowls[_tokenId] == true ? "Full Mystery Bowl" : "Empty Mystery Bowl";

        string memory json = Base64Upgradeable.encode(
            bytes(
                string(abi.encodePacked("{\"name\": \"Mystery Bowl #", StringsUpgradeable.toString(_tokenId), "\", \"description\":\"", bowlDescription, "\", \"image\":\"", bowlImage, "\", \"attributes\": [{\"trait_type\":  \"Summoning Power\",\"value\":\"", bowls[_tokenId] == true ? "Yes" : "No","\"}, {\"trait_type\":  \"Starfish\",\"value\":\"", StringsUpgradeable.toString(starfish(_tokenId)),"\"}]""}"))
                )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
    @notice Transfer the toker to a new address, and reset the starfish map of this token
    @param _from The token to be transferred from
    @param _to The token to be transferred to
    @param _tokenId tokenId to be transferred
    */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) 
    internal 
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        save(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    @notice Takes an eth address and returns the tokenIds that this user owns
    @param _ownerAddr Owner of the tokens
    @return tokenIds The list of owned tokens
    */
    function getTokensByOwner(address _ownerAddr)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        require(_ownerAddr != address(0), "Cannot query address 0");

        uint256 numTokens = balanceOf(_ownerAddr);
        tokenIds = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_ownerAddr, i);
        }
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    /**
    @notice Change status of the bowl, can only be set by contract owner.
    @param _tokenId Id of the token
    @param _bowlStatus new bowl status
     onlyOwner
    */
    function setBowlStatus(uint256 _tokenId, bool _bowlStatus)
        external
        isTokenExist(_tokenId)
        onlyOwner
    {
        require(canSetBowlStatus == true, "Set Bowl is false");
        bowls[_tokenId] = _bowlStatus;
        emit UpdatedBowlStatus(_tokenId, _bowlStatus, msg.sender);
    }

    /**
    @notice Change the image of the bowl when it is full
    @param _bowlFull link to new image
    */
    function setBowlImage(string calldata _bowlFull) external onlyOwner {
        bowlFull = _bowlFull;
        emit UpdatedBowlIPFS(_bowlFull, msg.sender);
    }

    /**
    @notice Change the image of the bowl when it is empty
    @param _bowlEmpty link to new empty bowl image
    */
    function setBowlEmptyImage(string calldata _bowlEmpty) external onlyOwner {
        bowlEmpty = _bowlEmpty;
        emit UpdatedBowlEmptyIPFS(_bowlEmpty, msg.sender);
    }

    /**
    @notice Change status of public sale, to allow public minting
    @param _isPublicSale new status of isPublicSale
    */
    function setPublicSale(bool _isPublicSale) external onlyOwner {
        isPublicSale = _isPublicSale;
        emit UpdatedIsPublicSale(_isPublicSale, msg.sender);
    }

    /**
    @notice Change status of isPaused, to pause all minting functions
    @param _isPaused boolean to pause
    */
    function setContractPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
        emit UpdatedPauseContract(_isPaused, msg.sender);
    }

    /**
    @notice Set new multiplier to calculate starfish
    @param _multiplier new multiplier
    */
    function setMaxMultiplier(uint256 _multiplier) external onlyOwner {
        maxMultiplier = _multiplier;
        emit UpdatedStarfishMaxMultiplier(_multiplier, msg.sender);
    }

    /**
    @notice Manual set a new max total supply
    Allow the owner to set a new total supply
    */
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        require(_maxTotalSupply > maxTotalSupply, "New max less than old max");
        maxTotalSupply = _maxTotalSupply;
        emit UpdatedMaxTotalSupply(_maxTotalSupply, msg.sender);
    }

    /**
    @notice Disable renounceOwnership since this contract has multiple onlyOwner functions
    */
    function renounceOwnership() public view override onlyOwner {
        revert("renounceOwnership is not allowed");
    }

    /**
    @notice Manual set a new merkle root for whiteListMerkleRoot
    @param _merkleRoot new merkle root
    */
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
        emit UpdatedMerkleRootOfWhiteListMint(_merkleRoot, msg.sender);
    }

    /**
    @notice withdraw current balance to msg.sender address
    */
    function withdrawAvailableBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
    @notice Manual set the address of the Anomura contract deployed
    This should be set to a deployed anomura address. Once we set, we should not call it again as the anomura address is a proxy address.
    @param _anomura Anomura's address deployed
    */
    function setAnomuraContractAddress(address _anomura) external onlyOwner {
        // require(address(anomuraContract) == address(0x0), "The anomura address has been set before.");
        // accidentally we may put a wrong address and we cannot revert
        anomuraContract = IAnomura(_anomura);
        emit UpdatedAnomuraContractAddress(_anomura, msg.sender);
    }

     /**
     * @dev Throw when the submitted proof not valid under its root
     */
    function checkMerkleProof(
        bytes32[] calldata _merkleProof,
        bytes32 _root,
        address sender
    ) external pure returns (bool isValid) {
        require(_root != "", "root is empty");
        
        isValid = MerkleProofUpgradeable.verify(
                _merkleProof,
                _root,
                keccak256(abi.encodePacked(sender)));
    }
}
