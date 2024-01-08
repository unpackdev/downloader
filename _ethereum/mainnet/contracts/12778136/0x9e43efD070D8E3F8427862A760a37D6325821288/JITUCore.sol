// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./IERC721.sol";

/**
 * @title Core of JITU (Just-In-Time-Underwriter)
 * @author KeeperDAO
 * @notice This contract allows whitelisted keepers to add buffer to compound positions that 
 * are slightly above water, so that in the case they go underwater the keepers can
 * preempt a liquidation.
 */
contract JITUCore is Ownable {
    /** State */
    IERC721 public immutable nft;
    LiquidityPoolLike public liquidityPool;
    mapping (address=>bool) keeperWhitelist;
    mapping (address=>bool) underwriterWhitelist;

    /** Events */
    event KeeperWhitelistUpdated(address indexed _keeper, bool _updatedValue);
    event UnderwriterWhitelistUpdated(address indexed _underwriter, bool _updatedValue);
    event LiquidityPoolUpdated(address indexed _oldValue, address indexed _newValue);

    /**
     * @notice initialize the contract state
     */
    constructor (LiquidityPoolLike _liquidityPool, IERC721 _nft) {
        liquidityPool = _liquidityPool;
        nft = _nft;
    }

    /** Modifiers */
    /**
     * @notice reverts if the caller is not a whitelisted keeper
     */
    modifier onlyWhitelistedKeeper() {
        require(
            keeperWhitelist[msg.sender], 
            "JITU: caller is not a whitelisted keeper"
        );
        _;
    }

    /**
     * @notice reverts if the caller is not a whitelisted underwriter
     */
    modifier onlyWhitelistedUnderwriter() {
        require(
            underwriterWhitelist[msg.sender], 
            "JITU: caller is not a whitelisted underwriter"
        );
        _;
    } 

    /**
     * @notice reverts if the caller is not the vault owner
     */
    modifier onlyVaultOwner(address _vault) {
        require(
            nft.ownerOf(uint256(uint160(_vault))) == msg.sender,
            "JITU: not the owner"
        );
        _;
    }

    /**
     * @notice reverts if the wallet is invalid
     */
    modifier valid(address _vault) {
        require(
            nft.ownerOf(uint256(uint160(_vault))) != address(0),
            "JITU: invalid vault address"
        );
        _;
    }

    /** External Functions */

    /**
     * @notice this contract can accept ethereum transfers
     */
    receive() external payable {}

    /**
     * @notice whitelist the given keeper, add to the keeper
     *         whitelist.
     * @param _keeper the address of the keeper
     */
    function updateKeeperWhitelist(address _keeper, bool _val) external onlyOwner {
        keeperWhitelist[_keeper] = _val;
        emit KeeperWhitelistUpdated(_keeper, _val);
    }

    /**
     * @notice update the liquidity provider.
     * @param _liquidityPool the address of the liquidityPool
     */
    function updateLiquidityPool(LiquidityPoolLike _liquidityPool) external onlyOwner {
        require(_liquidityPool != LiquidityPoolLike(address(0)), "JITU: liquidity pool cannot be 0x0");
        emit LiquidityPoolUpdated(address(liquidityPool), address(_liquidityPool));
        liquidityPool = _liquidityPool;
    }

    /**
     * @notice whitelist the given underwriter, add to the underwriter
     *         whitelist.
     * @param _underwriter the address of the underwriter
     */
    function updateUnderwriterWhitelist(address _underwriter, bool _val) external onlyOwner {
        underwriterWhitelist[_underwriter] = _val;
        emit UnderwriterWhitelistUpdated(_underwriter, _val);
    }
}

interface LiquidityPoolLike {
    function adapterBorrow(address _token, uint256 _amount, bytes calldata _data) external;
    function adapterRepay(address _adapter, address _token, uint256 _amount) external payable;
    function borrower() external view returns (address);
}