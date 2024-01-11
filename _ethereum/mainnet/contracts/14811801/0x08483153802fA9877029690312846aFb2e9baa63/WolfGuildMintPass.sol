//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./ECDSA.sol";

error ExceedsMaxSupply();
error FunctionLocked();
error InvalidSignature();
error SignatureAlreadyUsed();
error TokenIdOutOfRange();

/**
 * @title Wolf Guild Mint Passes
 * @author bagelface.eth
 * @notice For more details visit https://wolfguild.io/
 */
contract WolfGuildMintPass is ERC1155, AccessControl, Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256[3] public MAX_SUPPLY = [7, 25, 463];

    address public signer;
    uint256[3] public supply;
    mapping(bytes => bool) public signatureUsed;
    mapping(bytes4 => bool) public functionLocked;

    constructor(string memory uri) ERC1155(uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert FunctionLocked();
        _;
    }

    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lock(bytes4 id) public onlyRole(DEFAULT_ADMIN_ROLE) {
        functionLocked[id] = true;
    }

    /**
     * @notice The total supply of all tokens minted
     * @return The sum of each individual token supply
     */
    function totalSupply() public view returns (uint256) {
        return supply[0] + supply[1] + supply[2];
    }

    /**
     * @notice Set signature signing address
     * @param _signer address of account used to create mint signatures
     */
    function setSigner(address _signer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    /**
     * @notice Set token URI for all tokens
     * @dev More details in ERC1155 contract
     * @param uri base metadata URI applied to token IDs
     */
    function setURI(string memory uri) public lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(uri);
    }

    /**
     * @notice Flip paused state to temporarily disable minting
     */
    function flipPaused() public lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        paused() ? _unpause() : _pause();
    }

    /**
     * @notice Airdrop a mint pass
     * @param receivers of the corresponding token
     * @param tokenId to airdrop
     */
    function airdrop(
        address[] calldata receivers,
        uint256 tokenId
    )
        public
        lockable
        onlyRole(AIRDROPPER_ROLE)
    {
        if (tokenId >= MAX_SUPPLY.length) revert TokenIdOutOfRange();
        if (supply[tokenId] + receivers.length > MAX_SUPPLY[tokenId]) revert ExceedsMaxSupply();

        for (uint256 i; i < receivers.length; ++i) {
            _mint(receivers[i], tokenId, 1, "");
        }

        supply[tokenId] += receivers.length;
    }

    /**
     * @notice Whitelisted mint
     * @dev One token is minted per signature and each signature can only be used once
     * @param tokenId to mint
     * @param signature created by signer account
     */
    function mint(
        uint256 tokenId,
        bytes memory signature
    )
        public
        whenNotPaused
        nonReentrant
    {
        if (signatureUsed[signature]) revert SignatureAlreadyUsed();
        if (tokenId >= MAX_SUPPLY.length) revert TokenIdOutOfRange();
        if (supply[tokenId] == MAX_SUPPLY[tokenId]) revert ExceedsMaxSupply();

        bytes memory digest = abi.encodePacked(_msgSender(), tokenId);
        if (signer != ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(digest)), signature))
            revert InvalidSignature();

        _mint(_msgSender(), tokenId, 1, "");

        signatureUsed[signature] = true;
        supply[tokenId] += 1;
    }

    /**
     * @notice Burn a specified token from a specified owner
     * @param from Owner to burn from
     * @param id Token to burn
     */
    function burn(
        address from,
        uint256 id
    )
        public
        lockable
        onlyRole(BURNER_ROLE)
    {
        _burn(from, id, 1);
    }

    /**
     * @inheritdoc ERC1155
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}