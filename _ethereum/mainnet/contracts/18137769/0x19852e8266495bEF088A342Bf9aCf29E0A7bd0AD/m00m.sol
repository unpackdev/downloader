// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./ERC721AUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";
import {DefaultOperatorFiltererUpgradeable} from
    "@operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

error OutsidePhaseWindow();
error NotEligibleToMint();
error InsufficientValue();
error ExceedingMaxMint();
error MaxSupplyReached();
error FailedWithdrawal();

/// @title m00m
/// @author @emiliolanzalaco
/// @notice This is the ERC721 contract for m00m
contract m00m is UUPSUpgradeable, OwnableUpgradeable, ERC721AUpgradeable, DefaultOperatorFiltererUpgradeable {
    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    string public baseURI;
    string public suffixURI;
    uint256 public constant MAX_SUPPLY = 4200;
    string public contractURI;

    enum PHASE {
        CONTAINED,
        WHITELIST,
        PUBLIC
    }

    struct PhaseConfig {
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 maxMint;
        bytes32 merkleRoot;
    }

    mapping(PHASE => PhaseConfig) public phases;
    mapping(PHASE => mapping(address => uint256)) public numberMinted;

    /*///////////////////////////////////////////////////////////////
                                 INITS
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    function __m00m_init(string memory baseURI_) public initializerERC721A initializer {
        __ERC721A_init("m00m.world", "m00m");
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        baseURI = baseURI_;
    }

    /*///////////////////////////////////////////////////////////////
                                EXTERNALS
    //////////////////////////////////////////////////////////////*/

    function mint(PHASE phase, bytes32[] memory proof, uint256 quantity) public virtual payable {
        PhaseConfig memory phaseConfig = phases[phase];

        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyReached();
        if (msg.value * quantity < phaseConfig.price) revert InsufficientValue();
        if (
            phaseConfig.merkleRoot != bytes32(0)
                && !MerkleProof.verify(proof, phaseConfig.merkleRoot, keccak256(abi.encodePacked(msg.sender)))
        ) revert NotEligibleToMint();
        if (block.timestamp < phaseConfig.startTime || block.timestamp > phaseConfig.endTime) revert OutsidePhaseWindow();
        if (numberMinted[phase][msg.sender] + quantity > phaseConfig.maxMint) revert ExceedingMaxMint();

        numberMinted[phase][msg.sender] += quantity;

        _mint(msg.sender, quantity);
    }

    function burn(uint256 tokenId) external virtual {
        _burn(tokenId, true);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), suffixURI)) : "";
    }

    /*///////////////////////////////////////////////////////////////
                              OWNER ONLY
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setBaseURI(string memory newBaseURI) external virtual onlyOwner {
        baseURI = newBaseURI;
    }

    function setSuffixURI(string memory newSuffixURI) external virtual onlyOwner {
        suffixURI = newSuffixURI;
    }

    function setPhaseConfig(PHASE _phase, PhaseConfig memory newPhaseConfig) external virtual onlyOwner {
        phases[_phase] = newPhaseConfig;
    }

    function setContractURI(string memory newContractURI) external virtual onlyOwner {
        contractURI = newContractURI;
    }

    function adminMint(address to, uint256 quantity) external virtual onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyReached();
        _mint(to, quantity);
    }

    function withdraw(address to) external virtual onlyOwner {
        (bool success,) = to.call{value: address(this).balance}(bytes(""));
        if (!success) revert FailedWithdrawal();
    }

    /*///////////////////////////////////////////////////////////////
                              INTERNALS
    //////////////////////////////////////////////////////////////*/

    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    /*///////////////////////////////////////////////////////////////
                    OPENSEA ENFORCING ROYALTIES
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
