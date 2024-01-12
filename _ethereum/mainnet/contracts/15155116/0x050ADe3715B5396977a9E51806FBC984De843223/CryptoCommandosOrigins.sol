//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./MerkleProof.sol";
import "./ONFT721.sol";

/**
 * @title Crypto Commandos: Origins Collection
 * @dev Omni chain item mint. Source chain ETH, approved chain polygon
 * @author @ScottMitchell18
 */
contract CryptoCommandosOrigins is ONFT721, AccessControl {
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @dev token Id counter
    uint256 public nextTokenId = 0;

    /// @dev The total supply of the source collection mint
    uint256 public endMintId;

    // @dev Base uri for the nft
    string private baseURI;

    /// @dev The merkle root bytes
    bytes32 public merkleRoot;

    /// @dev An address mapping to add max mints per wallet
    mapping(address => bool) public addressToMinted;

    /// @notice Constructor for the ONFT
    /// @param _layerZeroEndpoint handles message transmission across chains
    constructor(address _layerZeroEndpoint)
        ONFT721(
            "Crypto Commandos: Origins Collection",
            "CCO",
            _layerZeroEndpoint
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
    }

    /**
     * @notice Whitelisted minting function which requires a merkle proof
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function whitelistMint(bytes32[] calldata _proof) external {
        require(!addressToMinted[msg.sender], "3");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "4");
        addressToMinted[msg.sender] = true;
        _safeMint(msg.sender, ++nextTokenId);
    }

    /// @notice Mints one new token
    function mint() external {
        require(!addressToMinted[msg.sender], "1");
        require(nextTokenId + 1 < endMintId, "2");
        addressToMinted[msg.sender] = true;
        _safeMint(msg.sender, ++nextTokenId);
    }

    /**
     * @notice A toggle switch for public sale
     * @param _endMintId The max nft collection size
     */
    function triggerPublicSale(uint256 _endMintId)
        external
        onlyRole(OWNER_ROLE)
    {
        delete merkleRoot;
        endMintId = _endMintId;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI)
        external
        onlyRole(OWNER_ROLE)
    {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(OWNER_ROLE) {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the collection start id
     * @param _nextTokenId The max supply of the collection
     */
    function setNextTokenId(uint256 _nextTokenId)
        external
        onlyRole(OWNER_ROLE)
    {
        nextTokenId = _nextTokenId;
    }

    /**
     * @notice Sets the collection max supply
     * @param _endMintId The max supply of the collection
     */
    function setEndMintId(uint256 _endMintId) external onlyRole(OWNER_ROLE) {
        endMintId = _endMintId;
    }

    function donate() external payable {
        // Thanks
    }

    /// @notice Withdraws funds from contract
    function withdraw() public onlyRole(OWNER_ROLE) {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send to treasury.");
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "-1");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ONFT721, AccessControl)
        returns (bool)
    {
        return
            ONFT721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}
