pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract SporeToken is ERC20("SporeFinance", "SPORE"), Ownable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    mapping(address => bool) public minters;
    address public initialLiquidityManager;

    bool internal _transfersEnabled;
    mapping(address => bool) internal _canTransferInitialLiquidity;

    /* ========== CONSTRUCTOR ========== */

    constructor(address initialLiquidityManager_) public {
        _transfersEnabled = false;
        minters[msg.sender] = true;
        initialLiquidityManager = initialLiquidityManager_;
        _canTransferInitialLiquidity[msg.sender] = true;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Transfer is enabled as normal except during an initial phase
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_transfersEnabled || _canTransferInitialLiquidity[msg.sender], "SporeToken: transfers not enabled");

        return super.transfer(recipient, amount);
    }

    /// @notice TransferFrom is enabled as normal except during an initial phase
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_transfersEnabled || _canTransferInitialLiquidity[msg.sender], "SporeToken: transfers not enabled");

        return super.transferFrom(sender, recipient, amount);
    }

    /// @notice Any account is entitled to burn their own tokens
    function burn(uint256 amount) public {
        require(amount > 0);
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function addInitialLiquidityTransferRights(address account) public onlyInitialLiquidityManager {
        require(!_transfersEnabled, "SporeToken: cannot add initial liquidity transfer rights after global transfers enabled");
        _canTransferInitialLiquidity[account] = true;
    }

    /// @notice One time acion to enable global transfers after the initial liquidity is supplied.
    function enableTransfers() public onlyInitialLiquidityManager {
        _transfersEnabled = true;
    }

    function addMinter(address account) public onlyOwner {
        minters[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Restricted to minters.");
        _;
    }

    modifier onlyInitialLiquidityManager() {
        require(initialLiquidityManager == msg.sender, "Restricted to initial liquidity manager.");
        _;
    }
}
