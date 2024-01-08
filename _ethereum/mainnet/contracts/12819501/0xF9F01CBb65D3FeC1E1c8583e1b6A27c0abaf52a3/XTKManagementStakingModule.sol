pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";

/**
 * @title XTKManagementStakingModule
 * @author xToken
 *
 */
contract XTKManagementStakingModule is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    // Address of xtk token
    address public constant xtk = 0x7F3EDcdD180Dbe4819Bd98FeE8929b5cEdB3AdEB;

    // Unstake penalty percentage between 0 and 10%
    uint256 public unstakePenalty;

    bool public transferable;

    uint256 private constant DEC_18 = 1e18;
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 10;

    /* ============ Events ============ */

    event SetUnstakePenalty(uint256 indexed timestamp, uint256 unstakePenalty);
    event Stake(address indexed sender, uint256 xtkAmount, uint256 xxtkAmount);
    event UnStake(address indexed receiver, uint256 xxtkAmount, uint256 xtkAmount);

    /* ============ Functions ============ */

    function initialize() external initializer {
        __Ownable_init();
        __ERC20_init_unchained("xXTK-Mgmt", "xXTKa");

        transferable = true;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     * Check if transferable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(transferable, "token not transferable");
    }

    /**
     * Governance function that allow/disallow xXTK token transfer
     */
    function setTransferable(bool _transferable) external onlyOwner {
        require(transferable != _transferable, "Same value");
        transferable = _transferable;
    }

    /**
     * Governance function that updates the unstake penalty percentage
     * @notice penalty == 1e18 means penalty is 0
     * @notice penalty to be between 0 and 10%
     *
     * @param _unstakePenalty   Unstake penalty percentage
     */
    function setUnstakePenalty(uint256 _unstakePenalty) external onlyOwner {
        require(_unstakePenalty < DEC_18 && _unstakePenalty >= 9e17, "Penalty outside range");
        unstakePenalty = _unstakePenalty;

        emit SetUnstakePenalty(block.timestamp, _unstakePenalty);
    }

    /**
     * Receive xtk token from user and mint propertional Xxtk to the user
     * @param _xtkAmount    xtk token amount to stake
     */
    function stake(uint256 _xtkAmount) external {
        require(_xtkAmount > 0, "Cannot stake 0");

        uint256 mintAmount = calculateXxtkAmountToMint(_xtkAmount);

        IERC20(xtk).safeTransferFrom(msg.sender, address(this), _xtkAmount);

        _mint(msg.sender, mintAmount);

        emit Stake(msg.sender, _xtkAmount, mintAmount);
    }

    /**
     * Burn Xxtk token from user and send propertional xtk token
     * @dev possible reentrance?
     * @param _xxtkAmount   Xxtk token amount to burn
     */
    function unstake(uint256 _xxtkAmount) external {
        uint256 xtkWithoutPenalty = calculateProRataXtk(_xxtkAmount);
        uint256 xtkToDistribute = calculateXtkToDistributeOnUnstake(xtkWithoutPenalty);

        _burn(msg.sender, _xxtkAmount);

        IERC20(xtk).safeTransfer(msg.sender, xtkToDistribute);

        emit UnStake(msg.sender, _xxtkAmount, xtkToDistribute);
    }

    function calculateXxtkAmountToMint(uint256 xtkAmount) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) return xtkAmount * INITIAL_SUPPLY_MULTIPLIER;

        uint256 xtkBalance = IERC20(xtk).balanceOf(address(this));
        return (xtkAmount * totalSupply) / xtkBalance;
    }

    function calculateProRataXtk(uint256 xxtkAmount) public view returns (uint256) {
        uint256 xtkBalance = IERC20(xtk).balanceOf(address(this));
        return (xxtkAmount * xtkBalance) / totalSupply();
    }

    function calculateXtkToDistributeOnUnstake(uint256 proRataXtk) public view returns (uint256) {
        return (proRataXtk * unstakePenalty) / DEC_18;
    }
}
