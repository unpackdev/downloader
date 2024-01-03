// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "./Ownable.sol";
import "./Initializable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IAssetAllocation.sol";
import "./IAddressRegistry.sol";

contract APYManager is Initializable, OwnableUpgradeSafe, IAssetAllocation {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    address public proxyAdmin;
    IAddressRegistry public addressRegistry;
    address public mApt; // placeholder for future-proofing storage

    bytes32[] internal _poolIds;
    address[] internal _tokenAddresses;

    /* ------------------------------- */

    event AdminChanged(address);

    function initialize(address adminAddress) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
    }

    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    /// @dev Allow contract to receive Ether.
    receive() external payable {} // solhint-disable-line no-empty-blocks

    function setAddressRegistry(address _addressRegistry) public onlyOwner {
        require(_addressRegistry != address(0), "Invalid address");
        addressRegistry = IAddressRegistry(_addressRegistry);
    }

    function setPoolIds(bytes32[] memory poolIds) public onlyOwner {
        _poolIds = poolIds;
    }

    function getPoolIds() public view returns (bytes32[] memory) {
        return _poolIds;
    }

    /** @notice Returns the list of asset addresses.
     *  @dev Address list will be populated automatically from the set
     *       of input and output assets for each strategy.
     */
    function getTokenAddresses()
        external
        override
        view
        returns (address[] memory)
    {
        return _tokenAddresses;
    }

    /// @dev part of temporary implementation for Chainlink integration
    function setTokenAddresses(address[] calldata tokenAddresses)
        external
        onlyOwner
    {
        _tokenAddresses = tokenAddresses;
    }

    /// @dev part of temporary implementation for Chainlink integration;
    ///      likely need this to clear out storage prior to real upgrade.
    function deleteTokenAddresses() external onlyOwner {
        delete _tokenAddresses;
    }

    /// @dev part of temporary implementation for Chainlink integration;
    ///      likely need this to clear out storage prior to real upgrade.
    function deletePoolIds() external onlyOwner {
        delete _poolIds;
    }

    /** @notice Returns the total balance in the system for given token.
     *  @dev The balance is possibly aggregated from multiple contracts
     *       holding the token.
     *
     *       This is a temporary implementation until there are deployed funds.
     *       In actuality, we will not be computing the TVL from the pools,
     *       as their funds will not be tokenized into mAPT.
     */
    function balanceOf(address token) external override view returns (uint256) {
        IERC20 erc20 = IERC20(token);
        uint256 balance = 0;
        for (uint256 i = 0; i < _poolIds.length; i++) {
            address pool = addressRegistry.getAddress(_poolIds[i]);
            uint256 poolBalance = erc20.balanceOf(pool);
            balance = balance.add(poolBalance);
        }
        return balance;
    }

    /// @notice Returns the symbol of the given token.
    function symbolOf(address token)
        external
        override
        view
        returns (string memory)
    {
        return ERC20UpgradeSafe(token).symbol();
    }
}
