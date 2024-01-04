// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.7.0;
pragma experimental ABIEncoderV2;

import "./PollenParams.sol";
import "./PollenToken.sol";
import "./IStemVesting.sol";
import "./SafeMath.sol";


/**
 * @title Stem_v1
 * @dev STEM token contract
 */
contract Stem_v1 is PollenToken, PollenParams, IStemVesting {
    using SafeMath for uint256;

    /**
    * @dev PollenDAO vests STEM tokens to a few "pools".
    *
    * STEM tokens are vested to a pool at a constant rate, starting from the `startBlock`
    * until the `endBlock` - parameters are defined for every pool on deployment.
    *
    * STEM amount to be vested to a "pool" is calculated as:
    *   stemAmountToVest = numOfBlocksToVestFor * pool.perBlockStemScaled/1e6
    *   numOfBlocksToVestFor = min(block.number, pool.startBlock) - pool.lastVestedBlock
    *   (when vested, the `pool.lastVestedBlock` is updated with the `block.number`)
    */

    uint256 private constant targetSupply = 100e24; // 100 millions

    // STEM minting params (see more in `PollenParams.sol`)
    uint32 internal constant mintEndBlock = mintStartBlock + mintBlocks;
    uint32 internal constant extraMintEndBlock = mintStartBlock + extraMintBlocks;
    uint256 internal constant unlockBlock = extraMintEndBlock;

    // STEM amount to vest every block, scaled (multiplied) by 1e6:
    uint96 internal constant scaledPerBlockFoundationStem = 8 * 1e18 * 1e6 / extraMintBlocks;
    uint96 internal constant scaledPerBlockReserveStem =    4 * 1e18 * 1e6 / extraMintBlocks;
    uint96 internal constant scaledPerBlockFoundersStem =  20 * 1e18 * 1e6 / mintBlocks;
    uint96 internal constant scaledPerBlockMarketingStem =  5 * 1e18 * 1e6 / mintBlocks;
    uint96 internal constant scaledPerBlockRewardStem =    63 * 1e18 * 1e6 / mintBlocks;

    // Mapping from a pool wallet address to pool' vesting data
    mapping(address => StemVestingPool) internal _vestingPools;

    constructor(bool doPreventUseWithoutProxy) public {
        if (doPreventUseWithoutProxy) {
            // Prevent using the contract w/o the proxy (potentially abusing)
            __Ownable_init();
        }
    }

    /// @inheritdoc IStemVesting
    /// @dev `pollenDAO` becomes the contract `owner`
    function initialize(
        address foundationWallet,
        address reserveWallet,
        address foundersWallet,
        address marketWallet
    ) external override initializer {
        _initialize("STEM token", "STEM");

        address pollenDAO = _pollenDAO();
        transferOwnership(pollenDAO);

        _initVestingPool( // Reward Pool
            StemVestingPool(
                true, // 'pollenDAO' only may trigger withdrawals
                _mintStartBlock(),
                _mintEndBlock(),
                _mintStartBlock(),
                scaledPerBlockRewardStem
            ),
            pollenDAO
        );
        _initVestingPool( // Foundation Pool
            StemVestingPool(
                false, // anyone may trigger withdrawals
                _mintStartBlock(),
                _extraMintEndBlock(),
                _mintStartBlock(),
                scaledPerBlockFoundationStem
            ),
            foundationWallet
        );
        _initVestingPool( // Reserve Pool
            StemVestingPool(
                true, // 'reserveWallet' only may trigger withdrawals
                _mintStartBlock(),
                _extraMintEndBlock(),
                _mintStartBlock(),
                scaledPerBlockReserveStem
            ),
            reserveWallet
        );
        _initVestingPool( // Founders&Team Pool
            StemVestingPool(
                false, // anyone may trigger withdrawals
                _mintStartBlock(),
                _mintEndBlock(),
                _mintStartBlock(),
                scaledPerBlockFoundersStem
            ),
            foundersWallet
        );
        _initVestingPool( // Marketing&Advisors Pool
            StemVestingPool(
                false, // anyone may trigger withdrawals
                _mintStartBlock(),
                _mintEndBlock(),
                _mintStartBlock(),
                scaledPerBlockMarketingStem
            ),
            marketWallet
        );
    }

    /// @inheritdoc IStemVesting
    function getVestingPoolParams(
        address wallet
    ) external view override returns(StemVestingPool memory) {
        return _vestingPools[wallet];
    }

    /// @inheritdoc IStemVesting
    function getPoolPendingStem(
        address wallet
    ) external view override returns(uint256 amount) {
        StemVestingPool memory pool = _vestingPools[wallet];
        amount = _computeVestingToPool(pool, block.number);
    }

    /// @inheritdoc IStemVesting
    function withdrawPoolStem(
        address wallet
    ) external override returns (uint256 amount) {
        StemVestingPool memory pool = _vestingPools[wallet];
        require(!pool.isRestricted || msg.sender == wallet, "STEM: unauthorized");
        amount = _computeVestingToPool(pool, block.number);
        if (amount != 0) {
            _vestingPools[wallet] = pool;
            _mintTo(wallet, amount);
        }

        emit StemWithdrawal(wallet, amount);
    }

    /***************************************
    ** INTERNAL and PRIVATE functions follow
    ***************************************/

    function _mintTo(address account, uint256 amount) internal {
        require(
            totalSupply().add(amount) <= targetSupply,
            "STEM: Total supply exceeds 100 millions"
        );
        _mint(account, amount);
    }

    // It disables transfers before `unlockBlock()`
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(
            block.number > _unlockBlock() || from == address(0) || from == _pollenDAO(),
            "STEM: token locked"
        );
        super._beforeTokenTransfer(from, to, amount);
    }

    function _initVestingPool(StemVestingPool memory pool, address wallet) internal {
        require(wallet != address(0), "zero wallet address");
        require(
            pool.startBlock != 0 && pool.perBlockStemScaled != 0,
            "STEM: invalid pool params"
        );
        _vestingPools[wallet] = pool;
        emit VestingPool(wallet);
    }

    function _computeVestingToPool(
        StemVestingPool memory pool,
        uint256 blockNow
    ) internal pure returns (uint256 stemToVest) {
        require(pool.perBlockStemScaled != 0, "STEM: unknown pool");
        stemToVest = 0;

        if (
            pool.lastVestedBlock < pool.endBlock &&
            blockNow > pool.startBlock &&
            blockNow > pool.lastVestedBlock
        ) {
            uint256 fromBlock = pool.lastVestedBlock > pool.startBlock
            ? pool.lastVestedBlock
            : pool.startBlock;
            uint256 toBlock = blockNow > pool.endBlock
            ? pool.endBlock
            : blockNow;

            if (toBlock > fromBlock) {
                stemToVest = toBlock.sub(fromBlock).mul(pool.perBlockStemScaled)/1e6;
                pool.lastVestedBlock = uint32(blockNow);
            }
        }
    }

    // @dev Functions declared "internal virtual" to facilitate tests
    function _pollenDAO() internal pure virtual returns(address) { return pollenDaoAddress; }
    function _mintStartBlock() internal pure virtual returns(uint32) { return mintStartBlock; }
    function _mintEndBlock() internal pure virtual returns(uint32) { return mintEndBlock; }
    function _extraMintEndBlock() internal pure virtual returns(uint32) { return extraMintEndBlock; }
    function _unlockBlock() internal pure virtual returns(uint256) { return unlockBlock; }
}
