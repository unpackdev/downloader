// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title CuddlyCubs Token
/// @author @MilkyTasteEth MilkyTaste:8662 https://milkytaste.xyz
/// https://www.hawaiianlions.world/

import "./IERC20.sol";
import "./ECDSA.sol";

import "./ERC721Ao.sol";
import "./IHawaiianLionsToken.sol";
import "./Payable.sol";

contract CuddlyCubsToken is ERC721Ao, Payable {
    using Strings for uint256;
    using ECDSA for bytes32;

    // Token values incremented for gas efficiency
    uint16 private constant MAX_SALE_PLUS_ONE = 1001;
    uint16 private constant MAX_FANG_CLAIMS_PLUS_ONE = 666;
    uint16 private constant MAX_FOSTER_CLAIMS = 333;
    uint16 private constant MAX_PER_TRANS_PLUS_ONE = 3;
    uint16 private constant MAX_PER_WALLET_PLUS_ONE = 7;

    uint16 public fangsToClaim = 150;
    uint16 public fangClaims = 0;
    uint16 public cubsToFoster = 5;
    uint16 public fostered = 0;

    address public signer;

    mapping(address => uint16) private claimed;

    enum ContractState {
        OFF,
        PUBLIC,
        UTILITY
    }
    ContractState public contractState = ContractState.OFF;

    IERC20 public immutable fangsToken;
    IHawaiianLionsToken public immutable lionsToken;

    string public baseURI;
    string public placeholderURI;

    constructor(address fangsAddress, address lionsAddress) ERC721Ao("CuddlyCubs", "HCUB") Payable() {
        fangsToken = IERC20(fangsAddress);
        lionsToken = IHawaiianLionsToken(lionsAddress);
    }

    //
    // Modifiers
    //

    /**
     * Do not allow calls from other contracts.
     */
    modifier noBots() {
        require(msg.sender == tx.origin, "CuddlyCubsToken: No bots");
        _;
    }

    /**
     * Ensure current state is correct for this method.
     */
    modifier isContractState(ContractState contractState_) {
        require(contractState == contractState_, "CuddlyCubsToken: Invalid state");
        _;
    }

    /**
     * Ensure amount of tokens to mint is within the limit.
     */
    modifier withinMintLimit(uint16 numTokens) {
        require((_totalMinted() + numTokens) < MAX_SALE_PLUS_ONE, "CuddlyCubsToken: Exceeds available tokens");
        _;
    }

    //
    // Minting
    //

    /**
     * Mint tokens during the public sale.
     * @param numTokens Number of tokens to mint
     */
    function mintPublic(uint16 numTokens)
        external
        payable
        noBots
        isContractState(ContractState.PUBLIC)
        withinMintLimit(numTokens)
    {
        require(numTokens < MAX_PER_TRANS_PLUS_ONE, "CuddlyCubsToken: Exceeds transaction limit");
        require(claimed[msg.sender] + numTokens < MAX_PER_WALLET_PLUS_ONE, "CuddlyCubsToken: Exceeds wallet limit");
        claimed[msg.sender] += numTokens;
        _safeMint(msg.sender, numTokens);
    }

    /**
     * Mints reserved tokens.
     * @param numTokens Number of tokens to mint
     * @param mintTo Address to mint tokens to
     */
    function mintReserved(uint16 numTokens, address mintTo) external onlyOwner withinMintLimit(numTokens) {
        _safeMint(mintTo, numTokens);
    }

    /**
     * Mint using $FANGS.
     * @dev User must have approved this contract to access FANGS.
     * @param numTokens Number of tokens to mint
     */
    function mintWithFangs(uint16 numTokens) external noBots isContractState(ContractState.UTILITY) {
        require(
            (fangClaims + numTokens) < MAX_FANG_CLAIMS_PLUS_ONE,
            "CuddlyCubsToken: Purchase exceeds available tokens"
        );
        require(numTokens < MAX_PER_TRANS_PLUS_ONE, "CuddlyCubsToken: Exceeds transaction limit");
        fangsToken.transferFrom(msg.sender, commyAddress, fangsToClaim * numTokens);
        fangClaims += numTokens;
        _safeMint(msg.sender, numTokens);
    }

    /**
     * Fostered cubs to create a genesis lion.
     * @param tokenIds Token Ids of cubs to foster
     * @param signature Server signature
     */
    function fosterCubs(uint16[] memory tokenIds, bytes memory signature)
        external
        noBots
        isContractState(ContractState.UTILITY)
    {
        require(tokenIds.length == cubsToFoster, "CuddlyCubsToken: Invalid number of cubs");
        require(fostered < MAX_FOSTER_CLAIMS, "CuddlyCubsToken: Foster limit exceeded");
        for (uint16 i = 0; i < cubsToFoster; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "CuddlyCubsToken: Must be cubs owner");
        }
        // Verify the first cub is signature verified
        require(
            _verify(abi.encodePacked(msg.sender, tokenIds[0]), signature, signer),
            "CuddlyCubsToken: Signature not valid"
        );
        for (uint16 i = 0; i < cubsToFoster; i++) {
            _burn(tokenIds[i]);
        }
        fostered++;
        lionsToken.mintUtility(1, msg.sender);
    }

    //
    // Admin
    //

    /**
     * Set contract state.
     * @param contractState_ The new state of the contract
     */
    function setContractState(ContractState contractState_) external onlyOwner {
        contractState = contractState_;
    }

    /**
     * Update the signer address.
     * @param signer_ The new signer address of the verifier
     */
    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /**
     * Set number of fangs per cub mint.
     * @param fangsToClaim_ The amount of FANGS required
     */
    function setFangsToClaim(uint16 fangsToClaim_) external onlyOwner {
        fangsToClaim = fangsToClaim_;
    }

    /**
     * Set number of cubs required to foster a lion.
     * @param cubsToFoster_ The amount of cubs required
     */
    function setCubsToFoster(uint16 cubsToFoster_) external onlyOwner {
        cubsToFoster = cubsToFoster_;
    }

    /**
     * Sets base URI.
     * @param _newBaseURI The base URI
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * Sets placeholder URI.
     * @param _newPlaceHolderURI The placeholder URI
     */
    function setPlaceholderURI(string memory _newPlaceHolderURI) external onlyOwner {
        placeholderURI = _newPlaceHolderURI;
    }

    //
    // Metadata
    //

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(uint16(tokenId)), "ERC721Metadata: URI query for nonexistent token");

        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : placeholderURI;
    }

    //
    // Views
    //

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Ao, ERC2981) returns (bool) {
        return ERC721Ao.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Verify a signature
     * @param data The signature data
     * @param signature The signature to verify
     * @param account The signer account
     */
    function _verify(
        bytes memory data,
        bytes memory signature,
        address account
    ) public pure returns (bool) {
        return keccak256(data).toEthSignedMessageHash().recover(signature) == account;
    }

    /**
     * @dev Returns mint details in one call
     * @param addr The address to check claims against
     * @return
     * contractState 0=OFF 1=PRESALE 2=PUBLIC 3=UTILTIY
     * maxSale (total available tokens)
     * totalSupply
     * claimed (by address provided)
     */
    function mintDetails(address addr) public view virtual returns (uint256[4] memory) {
        return [
            uint256(contractState),
            MAX_SALE_PLUS_ONE - 1,
            totalSupply(),
            claimed[addr]
        ];
    }
}
