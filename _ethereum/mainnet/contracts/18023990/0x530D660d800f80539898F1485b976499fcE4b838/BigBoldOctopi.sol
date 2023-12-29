// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC721A.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";
import "./UpdatableOperatorFilterer.sol";
import "./RevokableDefaultOperatorFilterer.sol";
import "./ECDSA.sol";

contract BigBoldOctopi is
    ERC721A,
    Ownable,
    ERC2981,
    RevokableDefaultOperatorFilterer
{
    using ECDSA for bytes32;
    uint256 constant MAX_SUPPLY = 10_000;
    uint256 constant WL_LIMIT_PER_WALLET = 5;
    uint256 constant PUBLIC_LIMIT_PER_WALLET = 3;
    uint256 public PUBLIC_MINT_PRICE = 0.06 ether;
    uint256 public WL_MINT_PRICE = 0.06 ether;
    bool public PUBLIC_MINT_STATUS = false;
    bool public WL_MINT_STATUS = false;
    string public baseURI = "";
    string public hiddenURI = "ipfs://QmNTxv4emR9EbSMVnFZL7WvESnAYTDh6BBaynkt15ugRhs";

    /**
     * @notice Used to validate whitelist addresses         
     */
    address immutable signerAddress = 0x1D7E0fD3bc430753500A77f39a2e52Eb8E6aD57d;

    mapping(address => uint8) public PUBLIC_MINTED;
    mapping(address => uint8) public WL_MINTED;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor() ERC721A("Big Bold Octopi", "BBO") {
        _setDefaultRoyalty(0xfa8bee811a6B526b3fB693390A05919d5B3cE420, 300);
    }

    /**
     * @dev Big Bold Octopi public sale function.
     */
    function mint(uint8 amount) external payable {
        require(
            PUBLIC_MINT_STATUS,
            "Minting services are paused at the moment."
        );
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Big Bold Octopi's have sold out."
        );
        require(
            msg.value >= amount * PUBLIC_MINT_PRICE, "Insufficient Ether sent."
        );
        require(
            PUBLIC_MINTED[msg.sender] < PUBLIC_LIMIT_PER_WALLET,
            "You have already minted your allocated Big Bold Octopi's."
        );
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: msg.value}("");
        require(os);
        // =============================================================================
        PUBLIC_MINTED[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    /**
     * @dev treasury mint
     */
    function treasury(address buyer, uint256 _amount) external onlyOwner {
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "Big Bold Octopi's have sold out."
        );
        _safeMint(buyer, _amount);
    }

    /**
     * @notice Verify signature for whitelisted users.
     */
    function verifyAddressSigner(bytes memory signature)
        private
        view
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        return
            signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @notice Big Bold Octopi whitelist sale function.
     */
    function whitelistMint(bytes memory signature, uint8 amount)
        external
        payable
    {
        require(verifyAddressSigner(signature), "You're not whitelist.");

        require(WL_MINT_STATUS, "Minting services are paused at the moment.");
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Big Bold Octopi's have sold out."
        );
        require(
            WL_MINTED[msg.sender] < WL_LIMIT_PER_WALLET,
            "You have already minted your allocated Big Bold Octopi's."
        );
        require(
            msg.value >= amount * WL_MINT_PRICE, "Insufficient Ether sent."
        );

        // =============================================================================
        (bool os, ) = payable(owner()).call{value: msg.value}("");
        require(os);
        // =============================================================================

        WL_MINTED[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns the baseURL.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the hiddenURL.
     */
    function _hiddenURI() internal view returns (string memory) {
        return hiddenURI;
    }

    /**
     * @dev Returns the tokenURI.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Err: ERC721AMetadata - URI query for nonexistent token"
        );

   
            return
                bytes(_baseURI()).length > 0
                    ? string(
                        abi.encodePacked(
                            _baseURI(),
                            "/",
                            _toString(tokenId),
                            ".json"
                        )
                    )
                    : string(
                        abi.encodePacked(
                            _hiddenURI(),
                            "/",
                            _toString(tokenId),
                            ".json"
                        )
                    );
        
    }


    /**
     * @dev change public mint price
     */
    function setPublicMintPrice(uint256 _new_price) external onlyOwner {
        PUBLIC_MINT_PRICE = _new_price;
    }

    /**
     * @dev change whitelist mint price
     */
    function setWLMintPrice(uint256 _new_price) external onlyOwner {
        WL_MINT_PRICE = _new_price;
    }

    /**
     * @dev setBaseURI for Big Bold Octopi
     */
    function setBaseURI(string memory _baseuri) external onlyOwner {
        baseURI = _baseuri;
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /**
     * @dev setHiddenURI for Big Bold Octopi
     */
    function setHiddenURI(string memory _hidden_uri) external onlyOwner {
        hiddenURI = _hidden_uri;
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /**
     * @dev pause/unpause mint status
     */
    function setMintStatus(bool _public_status, bool _wl_status) external onlyOwner {
        PUBLIC_MINT_STATUS = _public_status;
        WL_MINT_STATUS = _wl_status;
    }

    /**
     * @dev change royalty settings
     */
    function updateRoyalties(address _receiver, uint16 _basisPoint)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _basisPoint);
    }

    /**
     * @dev function to withdraw ether for owner
     */
    function withdraw() external payable onlyOwner {
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}