// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC721ABurnable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Sqwizz is ERC721ABurnable, ReentrancyGuard, Ownable {
    uint256 public constant MAX_SUPPLY = 500;

    string public baseTokenUri;
    string public notRevealedUri;
    uint256 public maxMintAmount = 5;
    uint256 public salePrice = .1 ether;

    bool public revealed;
    bool public publicSale;
    bool public neonlistSale;
    bool public paused = true;

    bytes32 private _neonlistMerkleRoot;

    mapping(address => uint256) public totalMint;

    constructor() ERC721A("Sqwizz", "SQZ") {}

    // events
    event MintToken(uint256 indexed startId, uint256 indexed quantity);

    // modifiers
    modifier eligibleToMint(uint256 _mintAmount) {
        uint256 supply = totalSupply();

        require(supply <= MAX_SUPPLY, "None left to mint");
        require(_mintAmount > 0, "Must mint atleast 1");
        require(_mintAmount <= maxMintAmount, "Over max mint amount");
        require(supply + _mintAmount <= MAX_SUPPLY, "Minting over max supply");

        if (_msgSender() != owner()) {
            require(!paused, "Contract paused");
            require(
                totalMint[_msgSender()] + _mintAmount <= maxMintAmount,
                "Wallet is over the max mint amount"
            );

            require(
                msg.value >= totalCost(_mintAmount),
                "Value sent below cost"
            );
        }
        _;
    }

    modifier neonlistEligible(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) {
        if (_msgSender() != owner()) {
            require(neonlistSale, "NeonList sale has not started yet");

            require(isNeonListed(_merkleProof), "User is not on the NeonList");
            uint256 ownerTokenCount = balanceOf(_msgSender());
        }
        _;
    }

    modifier publicSaleEligible() {
        if (_msgSender() != owner()) {
            require(publicSale, "Public sale has not started yet");
        }
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "Cannot be called by a contract");
        _;
    }

    // internal
    function _baseTokenUri() internal view returns (string memory) {
        return baseTokenUri;
    }

    function _mintHelper(uint256 _mintAmount) internal {
        uint256 id = totalSupply();

        emit MintToken(id + 1, _mintAmount);
        _safeMint(_msgSender(), _mintAmount);
    }

    // public
    function totalCost(uint256 _count) public view returns (uint256) {
        return salePrice * _count;
    }

    function isNeonListed(bytes32[] memory _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 sender = keccak256(abi.encodePacked(_msgSender()));

        return MerkleProof.verify(_merkleProof, _neonlistMerkleRoot, sender);
    }

    function neonlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
        neonlistEligible(_mintAmount, _merkleProof)
        eligibleToMint(_mintAmount)
    {
        totalMint[_msgSender()] += _mintAmount;
        _mintHelper(_mintAmount);
    }

    function mintPublic(uint256 _mintAmount)
        external
        payable
        callerIsUser
        publicSaleEligible
        eligibleToMint(_mintAmount)
    {
        totalMint[_msgSender()] += _mintAmount;
        _mintHelper(_mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseTokenUri();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /// only owner
    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyOwner
    {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseTokenURI(string memory _newBaseURI) external onlyOwner {
        baseTokenUri = _newBaseURI;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        salePrice = _mintPrice;
    }

    function withdraw() external payable nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(_msgSender()).transfer(address(this).balance);
    }

    function setNeonlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _neonlistMerkleRoot = _merkleRoot;
    }

    function getNeonlistMerkleRoot() external view onlyOwner returns (bytes32) {
        return _neonlistMerkleRoot;
    }

    function setMaxMintAmount(uint32 _quantity) external onlyOwner {
        maxMintAmount = _quantity;
    }

    // toggles
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function toggleNeonlistSale() external onlyOwner {
        neonlistSale = !neonlistSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    // overrides
    /// @dev Start token id @ 1 vs 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
