// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC20MintableBurnable.sol";
import "./ERC1155.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IAddressProvider.sol";
import "./IGuardian.sol";

error INVALID_ADDRESS();
error INVALID_AMOUNT();
error INVALID_PARAM();
error SINGLE_BASALT();
error EXCEED_CAP();
error LOW_ETH();

contract Obelisk is ERC1155PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /* ======== STORAGE ======== */

    enum ObeliskType {
        Basalt,
        Limestone,
        Granite
    }

    struct Info {
        uint256 multiplier;
        uint256 hardCap;
        uint256 supply;
        uint256 ethAmount;
        uint256 shezmuAmount;
    }

    /// @dev BASE URI
    string private constant BASE_URI = 'https://metadata.shezmu.io/obelisk/';

    /// @notice name
    string public constant name = 'Shezmu Obelisk';

    /// @notice percent multiplier (100%)
    uint256 public constant PRECISION = 10000;

    /// @notice address provider
    IAddressProvider public addressProvider;

    /// @notice mapping type => info
    mapping(ObeliskType => Info) public infoOf;

    /// @notice multiplier threshold
    uint256 public threshold;

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _addressProvider) external initializer {
        if (_addressProvider == address(0)) revert INVALID_ADDRESS();

        // address provider
        addressProvider = IAddressProvider(_addressProvider);

        // obelisk info
        infoOf[ObeliskType.Basalt] = Info({
            multiplier: PRECISION / 2,
            hardCap: 200,
            supply: 0,
            ethAmount: 1 ether,
            shezmuAmount: 200 ether
        });
        infoOf[ObeliskType.Limestone] = Info({
            multiplier: PRECISION / 4,
            hardCap: 2600,
            supply: 0,
            ethAmount: 0.5 ether,
            shezmuAmount: 100 ether
        });
        infoOf[ObeliskType.Granite] = Info({
            multiplier: PRECISION / 8,
            hardCap: 2500,
            supply: 0,
            ethAmount: 0.25 ether,
            shezmuAmount: 50 ether
        });

        // multiplier threshold (reward per guardian up to 0.145)
        threshold = 14500;

        // init
        __ERC1155Pausable_init();
        __ERC1155_init(BASE_URI);
        __Ownable_init();
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert INVALID_ADDRESS();
        addressProvider = IAddressProvider(_addressProvider);
    }

    function setInfo(
        ObeliskType obeliskType,
        Info calldata info
    ) external onlyOwner {
        infoOf[obeliskType] = info;
    }

    function setThreshold(uint256 _threshold) external onlyOwner {
        if (_threshold < PRECISION) revert INVALID_AMOUNT();

        threshold = _threshold;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function mint(ObeliskType obeliskType) external payable {
        address account = _msgSender();

        // single basalt
        if (
            obeliskType == ObeliskType.Basalt &&
            balanceOf(account, uint256(ObeliskType.Basalt)) > 0
        ) revert SINGLE_BASALT();

        Info storage info = infoOf[obeliskType];

        // hard cap
        if (info.hardCap <= info.supply) revert EXCEED_CAP();

        // fee
        if (msg.value < info.ethAmount) revert LOW_ETH();
        (bool success, ) = payable(addressProvider.getTreasury()).call{
            value: msg.value
        }('');
        require(success);
        IERC20MintableBurnable(addressProvider.getShezmu()).burnFrom(
            account,
            info.shezmuAmount
        );

        // mint
        unchecked {
            ++info.supply;
        }
        _mint(account, uint256(obeliskType), 1, '');
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != address(0)) {
            IGuardian(addressProvider.getGuardian()).updateRewardForObelisk(
                from
            );
        }
        if (to != address(0)) {
            IGuardian(addressProvider.getGuardian()).updateRewardForObelisk(to);
        }
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);

        // single basalt
        if (balanceOf(to, uint256(ObeliskType.Basalt)) > 1)
            revert SINGLE_BASALT();
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getInfos() external view returns (Info[] memory infos) {
        infos = new Info[](3);

        for (uint256 i = 0; i < 3; i++) {
            infos[i] = infoOf[ObeliskType(i)];
        }
    }

    function getMultiplierOf(
        address account
    ) external view returns (uint256 multiplier, uint256 precision) {
        for (uint256 i = 0; i < 3; i++) {
            uint256 balance = balanceOf(account, i);

            if (balance > 0) {
                multiplier += infoOf[ObeliskType(i)].multiplier * balance;
            }
        }

        multiplier = _min(threshold, multiplier);
        precision = PRECISION;
    }
}
