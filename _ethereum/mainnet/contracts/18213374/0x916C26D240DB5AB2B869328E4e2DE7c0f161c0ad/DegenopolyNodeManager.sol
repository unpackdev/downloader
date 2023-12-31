// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

import "./IAddressProvider.sol";
import "./IDegenopoly.sol";
import "./IDegenopolyNode.sol";
import "./IDegenopolyNodeFamily.sol";
import "./IDegenopolyNodeManager.sol";
import "./IDegenopolyPlayBoard.sol";

contract DegenopolyNodeManager is OwnableUpgradeable, IDegenopolyNodeManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice address provider
    IAddressProvider public addressProvider;

    /// @dev degenopoly nodes
    EnumerableSet.AddressSet private nodes;

    /// @dev mapping color => degenopoly nodes
    mapping(bytes32 => EnumerableSet.AddressSet) private nodesOfColor;

    /// @dev degenopoly node families
    EnumerableSet.AddressSet private families;

    /// @dev mapping color => degenopoly node family
    mapping(bytes32 => address) private familyOfColor;

    /// @dev mapping account => reward multiplier
    mapping(address => uint256) private multiplierOf;

    /* ======== ERRORS ======== */

    error ZERO_ADDRESS();
    error ZERO_AMOUNT();
    error NOT_MINTABLE_NODE();
    error INAVLID_NODE();
    error INVALID_FAMILY();
    error INVALID_LENGTH();
    error NOT_NODE_FAMILY();
    error NOT_PLAY_BOARD();
    error NOT_NODE_OWNER();

    /* ======== EVENTS ======== */

    event AddressProvider(address addressProvider);
    event PurchaseNode(address account, address node);
    event PurchaseNodeFamily(address account, address family);
    event ClaimReward(address account, uint256 reward);

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _addressProvider) external initializer {
        // address provider
        if (_addressProvider == address(0)) revert ZERO_ADDRESS();
        addressProvider = IAddressProvider(_addressProvider);

        // init
        __Ownable_init();
    }

    /* ======== MODIFIERS ======== */

    modifier onlyNodeFamily() {
        if (!families.contains(msg.sender)) revert NOT_NODE_FAMILY();
        _;
    }

    modifier onlyPlayBoard() {
        if (msg.sender != addressProvider.getDegenopolyPlayBoard())
            revert NOT_PLAY_BOARD();
        _;
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert ZERO_ADDRESS();

        addressProvider = IAddressProvider(_addressProvider);

        emit AddressProvider(_addressProvider);
    }

    function addNodes(address[] calldata _nodes) external onlyOwner {
        uint256 length = _nodes.length;

        for (uint256 i = 0; i < length; i++) {
            address node = _nodes[i];
            if (node == address(0)) revert ZERO_ADDRESS();

            nodes.add(node);
            nodesOfColor[getColorBytes32(IDegenopolyNode(node).color())].add(
                node
            );
        }
    }

    function removeNodes(address[] calldata _nodes) external onlyOwner {
        uint256 length = _nodes.length;

        for (uint256 i = 0; i < length; i++) {
            address node = _nodes[i];
            if (node == address(0)) revert ZERO_ADDRESS();

            nodes.remove(node);
            nodesOfColor[getColorBytes32(IDegenopolyNode(node).color())].remove(
                node
            );
        }
    }

    function addNodeFamilies(address[] calldata _families) external onlyOwner {
        uint256 length = _families.length;

        for (uint256 i = 0; i < length; i++) {
            address family = _families[i];
            if (family == address(0)) revert ZERO_ADDRESS();

            families.add(family);
            familyOfColor[
                getColorBytes32(IDegenopolyNodeFamily(family).color())
            ] = family;
        }
    }

    function removeNodeFamilies(
        address[] calldata _families
    ) external onlyOwner {
        uint256 length = _families.length;

        for (uint256 i = 0; i < length; i++) {
            address family = _families[i];
            if (family == address(0)) revert ZERO_ADDRESS();

            families.remove(family);
            familyOfColor[
                getColorBytes32(IDegenopolyNodeFamily(family).color())
            ] = address(0);
        }
    }

    /* ======== NODE FAMILY FUNCTIONS ======== */

    function mintNodeFamily(address _account) external onlyNodeFamily {
        _syncNodeReward(_account);

        // bonus
        uint256 multiplier = multiplierOf[_account] == 0
            ? MULTIPLIER
            : multiplierOf[_account];
        multiplierOf[_account] =
            (multiplier * IDegenopolyNodeFamily(msg.sender).rewardBoost()) /
            MULTIPLIER;
    }

    function burnNodeFamily(address _account) external onlyNodeFamily {
        _syncNodeReward(_account);

        // malus
        uint256 multiplier = multiplierOf[_account] == 0
            ? MULTIPLIER
            : multiplierOf[_account];
        multiplierOf[_account] =
            (multiplier * MULTIPLIER) /
            IDegenopolyNodeFamily(msg.sender).rewardBoost();
    }

    /* ======== PLAY BOARD FUNCTIONS ======== */

    function addMultiplier(
        address _account,
        uint256 _multiplier
    ) external onlyPlayBoard {
        _syncNodeReward(_account);

        uint256 multiplier = multiplierOf[_account] == 0
            ? MULTIPLIER
            : multiplierOf[_account];
        multiplierOf[_account] = (multiplier * _multiplier) / MULTIPLIER;
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function purchaseNode(address _node) external {
        if (!nodes.contains(_node)) revert INAVLID_NODE();

        // mintable
        IDegenopolyPlayBoard degenopolyPlayBoard = IDegenopolyPlayBoard(
            addressProvider.getDegenopolyPlayBoard()
        );
        if (degenopolyPlayBoard.mintableNode(msg.sender) != _node) {
            revert NOT_MINTABLE_NODE();
        }
        degenopolyPlayBoard.setNodeMinted(msg.sender);

        // pay
        uint256 price = IDegenopolyNode(_node).purchasePrice();
        IERC20(addressProvider.getDegenopoly()).safeTransferFrom(
            msg.sender,
            addressProvider.getTreasury(),
            price
        );

        // mint
        IDegenopolyNode(_node).mint(msg.sender);

        // event
        emit PurchaseNode(msg.sender, _node);
    }

    function purchaseNodeFamily(
        address _family,
        uint256[] calldata _nodeTokenIds
    ) external {
        if (!families.contains(_family)) revert INVALID_FAMILY();

        // nodes for family
        address[] memory nodesForFamily = nodesOfColor[
            getColorBytes32(IDegenopolyNodeFamily(_family).color())
        ].values();
        uint256 length = nodesForFamily.length;
        if (length != _nodeTokenIds.length) revert INVALID_LENGTH();

        // burn nodes
        for (uint256 i = 0; i < length; i++) {
            address node = nodesForFamily[i];
            uint256 tokenId = _nodeTokenIds[i];

            if (IDegenopolyNode(node).ownerOf(tokenId) != msg.sender)
                revert NOT_NODE_OWNER();

            IDegenopolyNode(node).burn(tokenId);
        }

        // mint
        IDegenopolyNodeFamily(_family).mint(msg.sender);

        // event
        emit PurchaseNodeFamily(msg.sender, _family);
    }

    function claimReward() external {
        uint256 reward;
        uint256 length = nodes.length();

        // total reward of nodes
        for (uint256 i = 0; i < length; i++) {
            reward += IDegenopolyNode(nodes.at(i)).claimReward(msg.sender);
        }

        // mint
        IDegenopoly(addressProvider.getDegenopoly()).mint(msg.sender, reward);

        // event
        emit ClaimReward(msg.sender, reward);
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getAllNodes() external view returns (address[] memory) {
        return nodes.values();
    }

    function getNodesOfColor(
        string memory _color
    ) external view returns (address[] memory) {
        return nodesOfColor[getColorBytes32(_color)].values();
    }

    function getAllNodeFamilies() external view returns (address[] memory) {
        return families.values();
    }

    function getNodeFamilyOfColor(
        string memory _color
    ) external view returns (address) {
        return familyOfColor[getColorBytes32(_color)];
    }

    function getMultiplierFor(
        address _account
    ) external view returns (uint256) {
        return
            multiplierOf[_account] == 0 ? MULTIPLIER : multiplierOf[_account];
    }

    function balanceOf(
        address _account
    ) external view returns (uint256 balance) {
        uint256 length = nodes.length();

        for (uint256 i = 0; i < length; i++) {
            balance += IDegenopolyNode(nodes.at(i)).balanceOf(_account);
        }

        return balance;
    }

    function claimableReward(
        address _account
    ) external view returns (uint256 pending) {
        uint256 length = nodes.length();

        for (uint256 i = 0; i < length; i++) {
            pending += IDegenopolyNode(nodes.at(i)).claimableReward(_account);
        }

        return pending;
    }

    function dailyRewardOf(
        address _account
    ) external view returns (uint256 dailyReward) {
        uint256 length = nodes.length();

        for (uint256 i = 0; i < length; i++) {
            IDegenopolyNode node = IDegenopolyNode(nodes.at(i));

            if (node.totalSupply() > 0) {
                dailyReward +=
                    (node.rewardPerSec() * node.balanceOf(_account) * 86400) /
                    node.totalSupply();
            }
        }

        dailyReward =
            (dailyReward *
                (
                    multiplierOf[_account] == 0
                        ? MULTIPLIER
                        : multiplierOf[_account]
                )) /
            MULTIPLIER;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function getColorBytes32(
        string memory _color
    ) internal pure returns (bytes32) {
        return keccak256(bytes(_color));
    }

    function _syncNodeReward(address _account) internal {
        uint256 length = nodes.length();

        for (uint256 i = 0; i < length; i++) {
            IDegenopolyNode(nodes.at(i)).syncReward(_account);
        }
    }
}
