// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./MerkleProof.sol";
import "./AccessControl.sol";
import "./ERC2771Context.sol";
import "./IERC165.sol";
import "./ERC1155C.sol";
import "./BasicRoyalties.sol";
import "./IValeriaBoosterCases.sol";
import "./IDelegationRegistry.sol";

/**
 __     __    _           _
 \ \   / /_ _| | ___ _ __(_) __ _
  \ \ / / _` | |/ _ \ '__| |/ _` |
   \ V / (_| | |  __/ |  | | (_| |
    \_/ \__,_|_|\___|_|  |_|\__,_|
*/

/// @title ValeriaBoosterCases
/// @notice Booster cases for Valeria games that come in cases (12 boxes) or individual boxes.
/// @author @ValeriaStudios
contract ValeriaBoosterCases is
    AccessControl,
    ERC2771Context,
    ERC1155C,
    BasicRoyalties,
    IValeriaBoosterCases
{
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    bytes32 public constant EXTERNAL_CONTRACT_ROLE =
        keccak256("EXTERNAL_CONTRACT_ROLE");

    /// @notice The token id for a box item
    uint256 public constant BOX_ITEM_ID = 1;

    /// @notice The token id for a case item
    uint256 public constant CASE_ITEM_ID = 2;

    /// @notice The merkle root for whitelist snapshot
    bytes32 public merkleRoot;

    /// @notice The total supply of boxes (1 case represents 12 boxes)
    uint256 public maxSupply = 3996; /// ~333 boxes

    /// @notice The total supply minted
    uint256 public mintedSupply = 0;

    /// @notice An individual box price
    uint256 public boxPrice = 0.036 ether;

    /// @notice A discounted case price
    uint256 public casePrice = 0.27 ether;

    /// @notice The mint start time
    uint256 public liveAt = 1702321200;

    /// @notice The mint end time
    uint256 public endsAt = 1702407600;

    /// @notice Public mint status
    bool public isPublicLive = false;

    /// @notice Delegation registry
    address public delegationRegistryAddress;

    error InvalidMerkle();
    error MaxSupplyReached();
    error InsufficientFunds();
    error PhaseNotLive();
    error InvalidDelegate();
    error FailedToWithdraw();

    modifier isDelegate(address vault) {
        bool isDelegateValid = IDelegationRegistry(delegationRegistryAddress)
            .checkDelegateForContract(_msgSender(), vault, address(this));
        if (!isDelegateValid) revert InvalidDelegate();
        _;
    }

    constructor(
        address _trustedForwarder,
        string memory _uri,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_,
        address delegationRegistryAddress_
    )
        ERC2771Context(_trustedForwarder)
        ERC1155OpenZeppelin(_uri)
        BasicRoyalties(royaltyReceiver_, royaltyFeeNumerator_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MODERATOR_ROLE, _msgSender());
        delegationRegistryAddress = delegationRegistryAddress_;
    }

    function name() external pure returns (string memory) {
        return "Valeria Booster Cases";
    }

    function symbol() external pure returns (string memory) {
        return "VALBOX";
    }

    /**
     * MINTING
     */

    function whitelistMint(
        bytes32[] calldata proof,
        bool isCase
    ) external payable {
        _whitelistMint(proof, isCase, _msgSender());
    }

    function whitelistMintDelegate(
        bytes32[] calldata proof,
        bool isCase,
        address vault
    ) external payable isDelegate(vault) {
        _whitelistMint(proof, isCase, vault);
    }

    function _whitelistMint(
        bytes32[] calldata proof,
        bool isCase,
        address vault
    ) internal {
        if (
            isPublicLive || block.timestamp < liveAt || block.timestamp > endsAt
        ) revert PhaseNotLive();

        if (
            !MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(vault))
            )
        ) revert InvalidMerkle();

        internalMint(isCase, vault);
    }

    function mint(bool isCase) external payable {
        if (!isPublicLive) revert PhaseNotLive();
        internalMint(isCase, _msgSender());
    }

    function mintDelegate(
        bool isCase,
        address vault
    ) external payable isDelegate(vault) {
        if (!isPublicLive) revert PhaseNotLive();
        internalMint(isCase, vault);
    }

    /**
     * @dev Internal impl mint. Cases add +12 supply.
     * @param isCase Boolean of whether the mint is a case or a box
     * @param vault The address to mint to
     */
    function internalMint(bool isCase, address vault) internal {
        if (isCase) {
            if (casePrice != msg.value) revert InsufficientFunds();
            if (mintedSupply + 12 > maxSupply) revert MaxSupplyReached();
            mintedSupply += 12;
            _mint(vault, CASE_ITEM_ID, 1, "");
        } else {
            if (boxPrice != msg.value) revert InsufficientFunds();
            if (mintedSupply + 1 > maxSupply) revert MaxSupplyReached();
            mintedSupply += 1;
            _mint(vault, BOX_ITEM_ID, 1, "");
        }
    }

    /**
     * EXTERNAL CONTRACT INTEGRATION
     */

    /// @dev Allows an external contract w/ role to burn an item
    function burnItem(
        address owner,
        uint256 typeId,
        uint256 amount
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _burn(owner, typeId, amount);
    }

    /// @dev Allows an external contract w/ role to burn in batch
    function burnItems(
        address owner,
        uint256[] calldata typeIds,
        uint256[] calldata amounts
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _burnBatch(owner, typeIds, amounts);
    }

    /// @dev Allows a bulk transfer
    function bulkSafeTransfer(
        uint256 typeId,
        uint256 amount,
        address[] calldata recipients
    ) external {
        for (uint256 i; i < recipients.length; i++) {
            safeTransferFrom(_msgSender(), recipients[i], typeId, amount, "");
        }
    }

    /**
     * MODERATOR
     */

    /// @dev Permissions check
    function _requireCallerIsContractOwner() internal view virtual override {
        _checkRole(MODERATOR_ROLE);
    }

    /**
     * @notice Sets the delegation registry address
     * @param _delegationRegistryAddress The delegation registry address to use
     */
    function setDelegationRegistryAddress(
        address _delegationRegistryAddress
    ) external onlyRole(MODERATOR_ROLE) {
        delegationRegistryAddress = _delegationRegistryAddress;
    }

    /// @dev Allows a moderator to change the public mint state
    function setPublicLive(bool _isPublicLive) public onlyRole(MODERATOR_ROLE) {
        isPublicLive = _isPublicLive;
    }

    /// @dev Allows a moderator to change the merkle root
    function setMerkleRoot(
        bytes32 _merkleRoot
    ) public onlyRole(MODERATOR_ROLE) {
        merkleRoot = _merkleRoot;
    }

    /// @dev Allows a moderator to change the mint window
    function setMintWindow(
        uint256 _liveAt,
        uint256 _endsAt
    ) public onlyRole(MODERATOR_ROLE) {
        liveAt = _liveAt;
        endsAt = _endsAt;
    }

    /// @dev Allows a moderator to change the prices for box and case
    function setPrices(
        uint256 _boxPrice,
        uint256 _casePrice
    ) public onlyRole(MODERATOR_ROLE) {
        boxPrice = _boxPrice;
        casePrice = _casePrice;
    }

    /// @dev Allows a moderator to change the base uri
    function setURI(string memory _uri) public onlyRole(MODERATOR_ROLE) {
        _setURI(_uri);
    }

    /// @dev Configure default royalty
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MODERATOR_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev Configure ongoing royalties
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MODERATOR_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @dev Allows a moderator to mint a single item
    function moderatorBoxMint(
        address to,
        uint256 amount
    ) external onlyRole(MODERATOR_ROLE) {
        mintedSupply += amount;
        _mint(to, BOX_ITEM_ID, amount, "");
    }

    /// @dev Allows a moderator to mint a single item
    function moderatorCaseMint(
        address to,
        uint256 amount
    ) external onlyRole(MODERATOR_ROLE) {
        mintedSupply += amount * 12;
        _mint(to, CASE_ITEM_ID, amount, "");
    }

    /// @notice Withdraw any eth
    function withdraw() external onlyRole(MODERATOR_ROLE) {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        if (!success) revert FailedToWithdraw();
    }

    // ========================================
    // Native meta transactions
    // ========================================

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155C, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
