// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./WadRayMath.sol";
import "./Errors.sol";
import "./IKyokoPool.sol";
import "./IKToken.sol";
import "./IKyokoPoolAddressesProvider.sol";
import "./BasicERC20.sol";

/**
 * @title Kyoko ERC20 KToken
 * @dev Implementation of the interest bearing token for the Kyoko protocol
 * @author Kyoko
 */
contract KToken is
    Initializable,
    BasicERC20("KTOKEN_IMPL", "KTOKEN_IMPL", 0),
    IKToken,
    ERC721HolderUpgradeable
{
    using WadRayMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IKyokoPoolAddressesProvider internal _addressesProvider;
    address internal _treasury;
    address internal _underlyingAsset;
    uint256 internal _reserveId;

    modifier onlyKyokoPool() {
        require(
            _msgSender() == address(_getKyokoPool()),
            Errors.CT_CALLER_MUST_BE_KYOKO_POOL
        );
        _;
    }

    constructor(
        IKyokoPoolAddressesProvider provider,
        uint256 reserveId,
        address treasury,
        address underlyingAsset,
        uint8 kTokenDecimals,
        string memory kTokenName,
        string memory kTokenSymbol
    ) initializer {
        _setName(kTokenName);
        _setSymbol(kTokenSymbol);
        _setDecimals(kTokenDecimals);

        _addressesProvider = provider;
        _reserveId = reserveId;
        _treasury = treasury;
        _underlyingAsset = underlyingAsset;

        emit Initialize(
            underlyingAsset,
            _addressesProvider.getKyokoPool()[0],
            reserveId,
            treasury,
            kTokenDecimals,
            kTokenName,
            kTokenSymbol
        );
    }

    /**
     * @dev Initializes the kToken
     * @param provider The address of the address provider where this kToken will be used
     * @param reserveId The id of the reserves
     * @param treasury The address of the Kyoko treasury, receiving the fees on this kToken
     * @param underlyingAsset The address of the underlying asset of this kToken (E.g. WETH for aWETH)
     * @param kTokenDecimals The decimals of the kToken, same as the underlying asset's
     * @param kTokenName The name of the kToken
     * @param kTokenSymbol The symbol of the kToken
     */
    function initialize(
        IKyokoPoolAddressesProvider provider,
        uint256 reserveId,
        address treasury,
        address underlyingAsset,
        uint8 kTokenDecimals,
        string calldata kTokenName,
        string calldata kTokenSymbol
    ) external override initializer {
        _setName(kTokenName);
        _setSymbol(kTokenSymbol);
        _setDecimals(kTokenDecimals);

        _addressesProvider = provider;
        _reserveId = reserveId;
        _treasury = treasury;
        _underlyingAsset = underlyingAsset;

        emit Initialize(
            underlyingAsset,
            _addressesProvider.getKyokoPool()[0],
            reserveId,
            treasury,
            kTokenDecimals,
            kTokenName,
            kTokenSymbol
        );
    }

    /**
     * @dev Burns kTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * - Only callable by the KyokoPool, as extra state updates there need to be managed
     * @param user The owner of the kTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external override onlyKyokoPool {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
        _burn(user, amountScaled);

        IERC20Upgradeable(_underlyingAsset).safeTransfer(
            receiverOfUnderlying,
            amount
        );

        emit Transfer(user, address(0), amount);
        emit Burn(user, receiverOfUnderlying, amount, index);
    }

    /**
     * @dev Burns kTokens from `user`
     * - Only callable by the KyokoPool, as extra state updates there need to be managed
     * @param user The owner of the kTokens, getting them burned
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        uint256 amount,
        uint256 index
    ) external override onlyKyokoPool {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
        _burn(user, amountScaled);

        emit Transfer(user, address(0), amount);
    }

    /**
     * @dev Mints `amount` kTokens to `user`
     * - Only callable by the KyokoPool, as extra state updates there need to be managed
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external override onlyKyokoPool returns (bool) {
        uint256 previousBalance = super.balanceOf(user);

        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
        _mint(user, amountScaled);

        emit Transfer(address(0), user, amount);
        emit Mint(user, amount, index);

        return previousBalance == 0;
    }

    /**
     * @dev Mints kTokens to the reserve treasury
     * - Only callable by the KyokoPool
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(
        uint256 amount,
        uint256 index
    ) external override onlyKyokoPool {
        if (amount == 0) {
            return;
        }

        address treasury = _treasury;

        // Compared to the normal mint, we don't check for rounding errors.
        // The amount to mint can easily be very small since it is a fraction of the interest ccrued.
        // In that case, the treasury will experience a (very small) loss, but it
        // wont cause potentially valid transactions to fail.
        _mint(treasury, amount.rayDiv(index));

        emit Transfer(address(0), treasury, amount);
        emit Mint(treasury, amount, index);
    }

    /**
     * @dev Transfers kTokens in the event of a borrow being liquidated, in case the liquidators reclaims the kToken
     * - Only callable by the KyokoPool
     * @param from The address getting liquidated, current owner of the kTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external override onlyKyokoPool {
        // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
        // so no need to emit a specific event here
        _transfer(from, to, value);

        emit Transfer(from, to, value);
    }

    /**
     * @dev Calculates the balance of the user: principal balance + interest generated by the principal
     * @param user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(
        address user
    ) public view override(BasicERC20, IERC20Upgradeable) returns (uint256) {
        IKyokoPool pool = _getKyokoPool();
        return
            super.balanceOf(user).rayMul(
                pool.getReserveNormalizedIncome(_reserveId)
            );
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(
        address user
    ) external view override returns (uint256) {
        return super.balanceOf(user);
    }

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(
        address user
    ) external view override returns (uint256, uint256) {
        return (super.balanceOf(user), super.totalSupply());
    }

    /**
     * @dev calculates the total supply of the specific kToken
     * since the balance of every single user increases over time, the total supply
     * does that too.
     * @return the current total supply
     **/
    function totalSupply()
        public
        view
        override(BasicERC20, IERC20Upgradeable)
        returns (uint256)
    {
        uint256 currentSupplyScaled = super.totalSupply();

        if (currentSupplyScaled == 0) {
            return 0;
        }

        IKyokoPool pool = _getKyokoPool();
        return
            currentSupplyScaled.rayMul(
                pool.getReserveNormalizedIncome(_reserveId)
            );
    }

    // TODO wrong Annotate
    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return the scaled total supply
     **/
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.totalSupply();
    }

    /**
     * @dev Returns the address of the Kyoko treasury, receiving the fees on this kToken
     **/
    function RESERVE_TREASURY_ADDRESS() public view returns (address) {
        return _treasury;
    }

    /**
     * @dev Returns the address of the underlying asset of this kToken (E.g. WETH for aWETH)
     **/
    function UNDERLYING_ASSET_ADDRESS() public view override returns (address) {
        return _underlyingAsset;
    }

    /**
     * @dev Returns the address of the lending pool where this kToken is used
     **/
    function POOL() public view returns (IKyokoPool) {
        return _getKyokoPool();
    }

    /**
     * @dev Transfers the underlying asset to `target`. Used by the KyokoPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param target The recipient of the kTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(
        address target,
        uint256 amount
    ) external override onlyKyokoPool returns (uint256) {
        IERC20Upgradeable(_underlyingAsset).safeTransfer(target, amount);
        return amount;
    }

    /**
     * @dev Transfers the underlying asset to `target`. Used by the KyokoPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param nft The nft address
     * @param target The recipient of the kTokens
     * @param nftId The token id of nft
     * @return The amount transferred
     **/
    function transferUnderlyingNFTTo(
        address nft,
        address target,
        uint256 nftId
    ) external override onlyKyokoPool returns (uint256) {
        IERC721Upgradeable(nft).safeTransferFrom(address(this), target, nftId);
        return nftId;
    }

    function _getKyokoPool() internal view returns (IKyokoPool) {
        return IKyokoPool(_addressesProvider.getKyokoPool()[0]);
    }

    /**
     * @dev Invoked to execute actions on the kToken side after a repayment.
     * @param user The user executing the repayment
     * @param amount The amount getting repaid
     **/
    function handleRepayment(
        address user,
        uint256 amount
    ) external override onlyKyokoPool {}

    /**
     * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        IKyokoPool pool = _getKyokoPool();

        uint256 index = pool.getReserveNormalizedIncome(_reserveId);

        super._transfer(from, to, amount.rayDiv(index));

        emit BalanceTransfer(from, to, amount, index);
    }

    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721HolderUpgradeable) returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
