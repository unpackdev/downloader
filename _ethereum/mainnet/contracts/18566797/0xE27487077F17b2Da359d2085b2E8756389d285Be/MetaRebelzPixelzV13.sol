pragma solidity ^0.8.17;

import "./ERC721AQueryableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./MerkleProof.sol";
import "./ERC721ABurnableUpgradeable.sol";
import "./ERC721A.sol";
import "./MetaRebelzV6.sol";

contract MetaRebelzPixelzV13 is ERC721AQueryableUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, DefaultOperatorFiltererUpgradeable, ERC721ABurnableUpgradeable {
    uint256 public cost;   
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    address public withdrawWallet;
    bool public mintable;
    bool public preSale;
    string baseURI;
    bytes32 public merkleRoot;
    bytes32 public merkleRootAmount;
    uint256 public reservedAmount;
    mapping(address => uint256) public freeClaims;
    mapping(uint256 => bool) tokenProtected;
    uint256 public requiredClaimAmount;
    uint256 public claimGiveAmount;
    address public smallBrosContract;
    address public okaybearsContract;
    address public hongozContract;
    bool public claimable;

   /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setupClaims() public onlyOwner {
        claimable = false;
        requiredClaimAmount = 20;
        claimGiveAmount = 1;
        smallBrosContract = 0xb18380485f7bA9C23Deb729bEDD3A3499Dbd4449;
        okaybearsContract = 0x4BEcbdf97747413A18C5a2a53321D09198d3a100;
        hongozContract = 0x5284323dFe87527280BA5521Cc6187b5fA1A19e9;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

function claimOriginal(uint256[] memory tokenIds) public payable {
    require(
        claimable && 
        balanceOf(msg.sender) >= requiredClaimAmount && 
        msg.value == 0, 
        "Check claim conditions"
    );

    ERC721A smallBros = ERC721A(smallBrosContract);
    ERC721A okaybears = ERC721A(okaybearsContract);
    ERC721AUpgradeable hongoz = ERC721AUpgradeable(hongozContract);

    require(
        smallBros.balanceOf(msg.sender) >= 1 && 
        okaybears.balanceOf(msg.sender) >= 1 && 
        hongoz.balanceOf(msg.sender) >= 1, 
        "Check token ownership"
    );

    for (uint i = 0; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        burn(tokenId);
    }

    MetaRebelzV6(0x94c2911cEB9B3684204C63b8E204A660990b7318).sendClaim(claimGiveAmount, msg.sender);
}

    function setRequiredClaimAmount(uint256 claimAmount) public onlyOwner
    {
        requiredClaimAmount = claimAmount;
    }

    function setClaimGiveAmount(uint256 giveAmount) public onlyOwner
    {
        claimGiveAmount = giveAmount;
    }

    function toggleClaimable() public onlyOwner
    {
        claimable = !claimable;
    }

    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner
    {
        merkleRoot = merkleRootHash;
    }

    function setMerkleRootAmount(bytes32 merkleRootHash) external onlyOwner
    {
        merkleRootAmount = merkleRootHash;
    }

    function verifyAddress(bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function verifyAddressAmount(bytes32[] calldata _merkleProof, uint256 _claimAmount) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(abi.encodePacked(msg.sender, ":", _claimAmount)));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function setReservedAmount(uint256 _reservedAmount) public onlyOwner {
        reservedAmount = _reservedAmount;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintAmount(uint256 _newMax) public onlyOwner {
        maxMintAmount = _newMax;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function toggleMintable() public onlyOwner {
        mintable = !mintable;
    }

    function togglePreSale() public onlyOwner {
        preSale = !preSale;
    }

    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function airdrop(address to, uint256 _mintAmount) public onlyOwner {
        _mint(to, _mintAmount);
    }

    function lockToken(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender);
            tokenProtected[tokenId] = true;
        }
    }

     function unlockToken(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender);
            tokenProtected[tokenId] = false;
        }
    }

    function lockToken(uint256 tokenId, bool isAdmin) public onlyOwner {
        require(isAdmin);
        tokenProtected[tokenId] = true;
    }

    function unlockToken(uint256 tokenId, bool isAdmin) public onlyOwner {
        require(isAdmin);
        tokenProtected[tokenId] = false;
    }

    function isLocked(uint256 tokenId) external view returns (bool) {
        return (true == tokenProtected[tokenId]);
    }

    function isUnlocked(uint256 tokenId) internal view returns (bool) {
        return (false == tokenProtected[tokenId]);
    }

    function mint(uint256 _mintAmount) external payable {
        require(mintable);
        require(!preSale);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(_totalMinted() + _mintAmount <= maxSupply - reservedAmount, "Exceeds non-reserved supply");
        require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount);

        if (msg.sender != owner()) {            
            require(msg.value >= cost * _mintAmount);
        }

        _mint(msg.sender, _mintAmount);
    }

    function mint(address to, uint256 _mintAmount) external payable {
        require(mintable);
        require(!preSale);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(_totalMinted() + _mintAmount <= maxSupply - reservedAmount, "Exceeds non-reserved supply");
        require(balanceOf(to) + _mintAmount <= maxMintAmount);

        if (msg.sender != owner()) {            
            require(msg.value >= cost * _mintAmount);
        }

        _mint(to, _mintAmount);
    }


    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable {
        require(mintable);
        require(preSale);
        require(verifyAddress(_merkleProof), "Not in whitelist for presale");
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(_totalMinted() + _mintAmount <= maxSupply - reservedAmount, "Exceeds non-reserved supply");
        require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount);

        if (msg.sender != owner()) {            
            require(msg.value >= cost * _mintAmount);
        }

        _mint(msg.sender, _mintAmount);
    }

    function claim(uint256 _claimAmount, bytes32[] calldata _merkleProof) public {
        require(mintable);
        require(preSale);
        require(_claimAmount > 0);
        require(reservedAmount > 0);
        require(_claimAmount <= maxMintAmount, "Exceeds maximum mint amount");
        require(verifyAddress(_merkleProof), "Invalid proof");
        require(_totalMinted() + _claimAmount <= maxSupply, "Exceeds maximum supply");
        require(_claimAmount <= reservedAmount, "Exceeds reserved amount");
        require(balanceOf(msg.sender) == 0, "Cannot claim twice");
    
        _mint(msg.sender, _claimAmount);
    
        reservedAmount -= _claimAmount;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory _URI = _baseURI();
        return bytes(_URI).length != 0 ? string(abi.encodePacked(_URI, _toString(tokenId))) : '';
    }

    function _startTokenId() internal view virtual override(ERC721AUpgradeable) returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal whenNotPaused virtual override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable virtual 
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.safeTransferFrom(from, to, tokenId, data);
    } 
}