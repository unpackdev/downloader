// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC721A.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";
import "./UpdatableOperatorFilterer.sol";
import "./RevokableDefaultOperatorFilterer.sol";

contract danglydoodads is
    ERC721A,
    Ownable,
    ERC2981,
    RevokableDefaultOperatorFilterer
{
    uint256 constant MAX_SUPPLY = 10_000;
    bool public PUBLIC_MINT_STATUS = false;
    string public baseURI = "https://qktmc6savx5qakk53nxddibz7xouzjegruarmmz2ajberf5yp47a.arweave.net/gqbBekCt-wApXdtuMaA5_d1MpIaNARYzOgJCSJe4fz4";

    mapping(address => bool) public Minted;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor() ERC721A("danglydoodads", "DDDD") {
        _setDefaultRoyalty(0xCf9ce0781BEf2a208FC7Ef1F5913bD6f9eC41eE4, 500);
    }

    /**
     * @dev 1 free DDDD mint per wallet
     */
    function mint() external {
        require(
            PUBLIC_MINT_STATUS,
            "DDDD: Minting services are paused at the moment."
        );
        require(
            totalSupply() + 1 <= MAX_SUPPLY,
            "DDDD: all danglydoodads have been minted."
        );
        require(
            !Minted[msg.sender],
            "DDDD: You have already minted your free danglydoodads."
        );
        Minted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    /**
     * @dev treasury mint
     */
    function treasury(address buyer, uint256 _amount) external onlyOwner {
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "DDDD: all danglydoodads have been minted."
        );
        _safeMint(buyer, _amount);
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
                : "";
    }
    
    /**
     * @dev setBaseURI for danglydoodads
     */
    function setBaseURI(string memory _baseuri) external onlyOwner {
        baseURI = _baseuri;
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /**
     * @dev pause/unpause mint status
     */
    function toggleMintStatus(bool _status) external onlyOwner {
        PUBLIC_MINT_STATUS = _status;
    }

    /**
     * @dev change royalty settings
     */
    function updateRoyalties(address _receiver, uint16 _basisPoint) external onlyOwner {
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