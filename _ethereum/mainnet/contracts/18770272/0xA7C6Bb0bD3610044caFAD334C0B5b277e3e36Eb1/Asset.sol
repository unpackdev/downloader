// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import "./Initializable.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IAsset.sol";

/**
 * @title Asset
 * @notice Contract presenting a merchandise asset in a master
 * @dev Expect to be owned by Timelock for management, and master links to master for coordination
 */
contract Asset is Ownable, ERC20, IAsset {
    using SafeERC20 for IERC20;

    /// @notice The underlying baseToken represented by this asset
    address public immutable baseToken;

    uint8 public immutable baseTokenDecimals;

    /// @notice The master
    address public master;

    /// @notice maxSupply the maximum amount of asset the master is allowed to mint.
    /// @dev if 0, means asset has no max
    uint256 public maxSupply;

    /// @notice virtualSupply the amount of asset the master has minted. Tracks buys and sells only.
    uint256 public virtualSupply;

    /// @notice An event thats emitted when max supply is updated
    event SetMaxSupply(uint256 previousMaxSupply, uint256 newMaxSupply);

    /// @notice An event thats emitted when master address is updated
    event SetMaster(address previousMasterAddr, address newMasterAddr);

    error MERCH_FORBIDDEN();
    error MERCH_TRANSFER_FORBIDDEN();

    /// @dev Modifier ensuring that certain function can only be called by master
    modifier onlyMaster() {
        if (msg.sender != master) revert MERCH_FORBIDDEN();
        _;
    }

    /**
     * @notice Constructor.
     * @param baseToken_ The token represented by the asset
     * @param name_ The name of the asset
     * @param symbol_ The symbol of the asset
     */
    constructor(
        address baseToken_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        baseToken = baseToken_;
        baseTokenDecimals = ERC20(baseToken_).decimals();
        virtualSupply = 0;
    }

    /**
     * @notice Changes the master. Can only be set by the contract owner.
     * @param master_ new master's address
     */
    function setMaster(address master_) external onlyOwner {
        require(master_ != address(0), 'Merch: master address cannot be zero');
        emit SetMaster(master, master_);
        master = master_;
    }

    /**
     * @notice Changes asset max supply. Can only be set by the contract owner. 18 decimals
     * @param maxSupply_ the new asset's max supply
     */
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        emit SetMaxSupply(maxSupply, maxSupply_);
        maxSupply = maxSupply_;
    }

    /**
     * @notice Adds asset virtual supply. Can only be called by Master.
     */
    function addVirtualSupply(uint256 amount) external onlyMaster {
        virtualSupply += amount;
    }

    /**
     * @notice Removes asset virtual supply. Can only be called by Master.
     */
    function removeVirtualSupply(uint256 amount) external onlyMaster {
        virtualSupply -= amount;
    }

    /**
     * @notice Returns the decimals of Asset, fixed to 18 decimals
     * @return decimals for asset
     */
    function decimals() public view virtual override(ERC20, IAsset) returns (uint8) {
        return 18;
    }

    /**
     * @notice Get Base Token Balance
     * @return Returns the actual balance of ERC20 WETH
     */
    function baseTokenBalance() external view returns (uint256) {
        return IERC20(baseToken).balanceOf(address(this));
    }

    /**
     * @notice Transfers ERC20 baseToken (WETH) from this contract to another account. Can only be called by Master.
     * @dev Not to be confused with transferring MERCH tokens.
     * @param to address to transfer the token to
     * @param amount amount to transfer
     */
    function transferBaseToken(address to, uint256 amount) external onlyMaster {
        IERC20(baseToken).safeTransfer(to, amount);
    }

    /**
     * @notice Mint ERC20 Asset LP Token, expect master coordinates other state updates. Can only be called by Master.
     * @param to address to transfer the token to
     * @param amount amount to transfer
     */
    function mint(address to, uint256 amount) external override onlyMaster {
        if (maxSupply != 0) {
            // if maxSupply == 0, asset is uncapped.
            require(amount + virtualSupply <= maxSupply, 'Merch: MAX_SUPPLY_REACHED');
        }
        return _mint(to, amount);
    }

    /**
     * @notice Burn ERC20 Asset LP Token, expect master coordinates other state updates. Can only be called by Master.
     * @param to address holding the tokens
     * @param amount amount to burn
     */
    function burn(address to, uint256 amount) external override onlyMaster {
        return _burn(to, amount);
    }

    /// @notice Override ERC20 transfer to only allow MERCH transfers to this contract
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (recipient != address(this)) revert MERCH_TRANSFER_FORBIDDEN();
        super._transfer(sender, recipient, amount);
    }
}
