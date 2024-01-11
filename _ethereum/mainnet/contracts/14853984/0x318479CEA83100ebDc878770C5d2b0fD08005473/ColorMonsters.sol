// SPDX-License-Identifier: MIT
/**
 ColorMonsters (https://colormonsters.io/) 1.0.2

 ColorMonsters are the most inclusive NFTs on the blockchain!
 Our passion lies with embracing all humans, of all cultural backgrounds, 
 genders, abilities and needs. Whoever you are, you are welcome here! 
 Be you !roar

 @dev total number of NFTs = 5555 (team, allow list, public, marketing)
 @dev max number of mints per wallet team = 10
 @dev max number of mints per wallet allow list = 2
 @dev max number of mints per wallet public sale = 5
 @dev mintPrice = 0.035
 @dev royalty = 7.5%

 @author Marcin Piekarski - GreenMonster (https://www.linkedin.com/in/kreatific/)

 Standing on the shoulders of giants (Azuki, Broskee, Inverted MFs, OpenZeppelin, Zooverse)
 */
pragma solidity 0.8.13;

import "./console.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract ColorMonsters is ERC721A, IERC2981, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    /// @dev Toggles
    bool public isTeamSaleActive = true;
    bool public isAllowListSaleActive = false;
    bool public isPublicSaleActive = false;
    bool public isRevealed = false;
    bool public isTokenTransfersActive = true;

    /// @dev Wallet config
    address private cmWalletAddress = 0xE355c5dE79e994b90029173AA4567e0947fFAaCF;
    address private cmDevWalletAddress = 0x86F64AEFD216B36226D86847d7DDE3c099B33bfB;

    /// @dev Allowlist config
    bytes32 public teamMerkleRoot;
    bytes32 public allowListMerkleRoot;

    /// @dev Sale config
    uint256 public maxTotalSupply = 5555;
    uint256 public teamMaxPerWallet = 10;
    uint256 public teamMaxPerTx = 10;
    uint256 public allowListMaxPerWallet = 2;
    uint256 public allowListMaxPerTx = 2;
    uint256 public publicMaxPerWallet = 5;
    uint256 public publicMaxPerTx = 5;
    uint256 public mintPrice = 0.035 ether;

    /// @dev 75 is divided by 10 in the royalty info function to make 7.5%
    uint256 public royalty = 75;

    /// @dev Metadata config
    string public metadataExtension = ".json";
    string public notRevealedBaseURI = "https://__UNREVEALED_IPFS__/1.json";
    string public revealedBaseURI = "https://__REVEALED_IPFS__/";
    string private baseURI;

    /// @dev Mappings
    mapping(address => bool) private admins;

    constructor() ERC721A("ColorMonsters", "CLRMON") {
        // Lets pause to begin with to
        // check everything before going live...
        _pause();
    }

    /// ---
    /// @dev Minting
    /// ---

    function reserveMint(uint256 _numberOfTokens) external isAdmin isTotalSupplyRemaining(_numberOfTokens) nonReentrant whenNotPaused {
        _callSafeMint(msg.sender, _numberOfTokens);
    }

    function teamMint(bytes32[] calldata _teamMerkleProof, uint256 _numberOfTokens)
        external
        isSaleActive(isTeamSaleActive, "Team sale is currently closed")
        isTotalSupplyRemaining(_numberOfTokens)
        isValidNumberOfTokensRequested(_numberOfTokens)
        isValidMerkleProof(_teamMerkleProof, teamMerkleRoot)
        tokensInWalletLimit(_numberOfTokens, teamMaxPerWallet)
        nonReentrant
        whenNotPaused
    {
        _callSafeMint(msg.sender, _numberOfTokens);
    }

    function allowListMint(bytes32[] calldata _allowListMerkleProof, uint256 _numberOfTokens)
        external
        payable
        isSaleActive(isAllowListSaleActive, "Allow list sale is currently closed")
        isTotalSupplyRemaining(_numberOfTokens)
        isValidNumberOfTokensRequested(_numberOfTokens)
        isCorrectPayment(_numberOfTokens)
        isValidMerkleProof(_allowListMerkleProof, allowListMerkleRoot)
        tokensInWalletLimit(_numberOfTokens, allowListMaxPerWallet)
        nonReentrant
        whenNotPaused
    {
        _callSafeMint(msg.sender, _numberOfTokens);
    }

    function mint(uint256 _numberOfTokens)
        external
        payable
        isSaleActive(isPublicSaleActive, "Public sale is currently closed")
        isTotalSupplyRemaining(_numberOfTokens)
        isValidNumberOfTokensRequested(_numberOfTokens)
        isCorrectPayment(_numberOfTokens)
        tokensInWalletLimit(_numberOfTokens, publicMaxPerWallet)
        nonReentrant
        whenNotPaused
    {
        _callSafeMint(msg.sender, _numberOfTokens);
    }

    function _callSafeMint(address _to, uint256 _numberOfTokens) internal {
        _safeMint(_to, _numberOfTokens);
    }

    /// ---
    /// @dev Withdraw
    /// ---

    function withdraw() external onlyOwner {
        (bool cmDevWalletSuccess, ) = payable(cmDevWalletAddress).call{value: (address(this).balance * 5) / 100}("");
        require(cmDevWalletSuccess, "Error withdrawing to cmDevWallet");

        (bool cmWalletSuccess, ) = payable(cmWalletAddress).call{value: address(this).balance}("");
        require(cmWalletSuccess, "Error withdrawing to cmWallet");
    }

    /// ---
    /// @dev Royalty
    /// ---

    function royaltyInfo(uint256, uint256 _salePrice) external view override(IERC2981) returns (address Receiver, uint256 royaltyAmount) {
        return (cmWalletAddress, (_salePrice * royalty) / 1000); // eg. (100*75) / 1000 = 7.5
    }

    /// ---
    /// @dev Overrides
    /// ---

    // Start tokens at 1 and not zero
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Query for nonexistent token");
        return getBaseURI(_tokenId);
    }

    function getBaseURI(uint256 _tokenId) public view returns (string memory) {
        if (isRevealed == false) {
            return notRevealedBaseURI;
        } else {
            return string(abi.encodePacked(revealedBaseURI, _tokenId.toString(), metadataExtension));
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        // do stuff before every transfer
        // e.g. check that vote (other than when minted)
        // being transferred to registered candidate
        require(isTokenTransfersActive, "Token transfers currently disabled");
    }

    /// ---
    /// @dev Toggles
    /// ---

    function toggleIsTeamSaleActive() external onlyOwner {
        isTeamSaleActive = !isTeamSaleActive;
    }

    function toggleIsAllowListSaleActive() external onlyOwner {
        isAllowListSaleActive = !isAllowListSaleActive;
    }

    function toggleIsPublicSaleActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleIsRevealed() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function toggleTokenTransfersActive() external onlyOwner {
        isTokenTransfersActive = !isTokenTransfersActive;
    }

    /// ---
    /// @dev Setters
    /// ---

    function setCmWalletAddress(address _cmWalletAddress) external onlyOwner {
        cmWalletAddress = _cmWalletAddress;
    }

    function setCmDevWalletAddress(address _cmDevWalletAddress) external onlyOwner {
        cmDevWalletAddress = _cmDevWalletAddress;
    }

    /// @dev Team Setters --------------

    function setTeamMerkleRoot(bytes32 _teamMerkleRoot) external onlyOwner {
        teamMerkleRoot = _teamMerkleRoot;
    }

    function setTeamMaxPerWallet(uint256 _teamMaxPerWallet) external onlyOwner {
        teamMaxPerWallet = _teamMaxPerWallet;
    }

    function setTeamMaxPerTx(uint256 _teamMaxPerTx) external onlyOwner {
        teamMaxPerTx = _teamMaxPerTx;
    }

    /// @dev Allow List Setters --------------

    function setAllowListMerkleRoot(bytes32 _allowListMerkleRoot) external onlyOwner {
        allowListMerkleRoot = _allowListMerkleRoot;
    }

    function setAllowListMaxPerWallet(uint256 _allowListMaxPerWallet) external onlyOwner {
        allowListMaxPerWallet = _allowListMaxPerWallet;
    }

    function setAllowListMaxPerTx(uint256 _allowListMaxPerTx) external onlyOwner {
        allowListMaxPerTx = _allowListMaxPerTx;
    }

    /// @dev Public Setters --------------

    function setPublicMaxPerWallet(uint256 _publicMaxPerWallet) external onlyOwner {
        publicMaxPerWallet = _publicMaxPerWallet;
    }

    function setPublicMaxPerTx(uint256 _publicMaxPerTx) external onlyOwner {
        publicMaxPerTx = _publicMaxPerTx;
    }

    /// @dev Other Setters --------------

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setRoyalty(uint256 _royalty) external onlyOwner {
        royalty = _royalty;
    }

    function setMetadataExtension(string memory _metadataExtension) external onlyOwner {
        metadataExtension = _metadataExtension;
    }

    function setNotRevealedBaseURI(string memory _notRevealedBaseURI) external onlyOwner {
        notRevealedBaseURI = _notRevealedBaseURI;
    }

    function setRevealedBaseURI(string memory _revealedBaseURI) external onlyOwner {
        revealedBaseURI = _revealedBaseURI;
    }

    /// ---
    /// @dev Getters
    /// ---

    function getCmWalletAddress() external view onlyOwner returns (address) {
        return cmWalletAddress;
    }

    function getCmDevWalletAddress() external view onlyOwner returns (address) {
        return cmDevWalletAddress;
    }

    function getOwnershipsStartTimestamp(uint256 _tokenId) public view returns (uint64) {
        return _ownerships[_tokenId].startTimestamp;
    }

    /// ---
    /// @dev Pause
    /// ---

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// ---
    /// @dev Admin
    /// ---

    function checkAdmin(address _admin) external view onlyOwner returns (bool) {
        return admins[_admin];
    }

    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        delete admins[_admin];
    }

    /// ---
    /// @dev Modifiers
    /// ---

    modifier isSaleActive(bool _isSaleActive, string memory _saleMessage) {
        require(_isSaleActive, _saleMessage);
        _;
    }

    modifier isTotalSupplyRemaining(uint256 _numberOfTokens) {
        require(_totalMinted() + _numberOfTokens <= maxTotalSupply, "Purchase would exceed total supply");
        _;
    }

    modifier isValidNumberOfTokensRequested(uint256 _numberOfTokens) {
        require(_numberOfTokens > 0, "Invalid number of tokens requested");
        _;
    }

    modifier isCorrectPayment(uint256 _numberOfTokens) {
        require(msg.value >= mintPrice * _numberOfTokens, "Not enough ether sent");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _merkleProof, bytes32 _merkleRoot) {
        require(MerkleProof.verify(_merkleProof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address not on approved list");
        _;
    }

    modifier tokensInWalletLimit(uint256 _numberOfTokens, uint256 _maxTokensPerWallet) {
        require(_numberMinted(msg.sender) + _numberOfTokens <= _maxTokensPerWallet, "Cannot exceed max number of tokens in wallet");
        _;
    }

    modifier isAdmin() {
        require(admins[msg.sender], "Unauthorized");
        _;
    }

    /// @dev === Support Functions ==
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }
}
