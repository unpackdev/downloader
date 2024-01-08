//SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.7;

// import "./console.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AggregatorV3Interface.sol";

interface IVault {
    function token() external view returns (address);
}

interface IVaultSwapper {
    struct Swap {
        bool deposit;
        address pool;
        uint128 n;
    }

    function swap(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        Swap[] calldata instructions
    ) external;
}

contract WidoSwap is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 private constant SWAP_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Swap(address user,address from_vault,uint256 amount,address to_vault,uint32 nonce,uint32 expiration)"
            )
        );

    bytes32 public DOMAIN_SEPARATOR;

    uint256 private estGasPerTransfer;

    struct Swap {
        address user;
        address from_vault;
        uint256 amount;
        address to_vault;
        uint32 nonce;
        uint32 expiration;
    }

    struct SwapTx {
        Swap swap;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(address => mapping(address => mapping(address => uint256)))
        public nonces;

    mapping(address => AggregatorV3Interface) public priceOracles;
    mapping(address => bool) public approvedTransactors;

    modifier onlyApprovedTransactors() {
        require(
            approvedTransactors[_msgSender()],
            "Not an approved transactor"
        );
        _;
    }

    function initialize(uint256 _chainId) public initializer {
        __Ownable_init();

        addApprovedTransactor(_msgSender());

        priceOracles[ // USDC
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        ] = AggregatorV3Interface(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
        priceOracles[ // DAI
            0x6B175474E89094C44Da98b954EedeAC495271d0F
        ] = AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4);

        estGasPerTransfer = 30000;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("WidoSwap"),
                keccak256("1"),
                _chainId,
                address(this)
            )
        );
    }

    function setEstGasPerTransfer(uint256 _newValue) external onlyOwner {
        estGasPerTransfer = _newValue;
    }

    function addApprovedTransactor(address _transactor) public onlyOwner {
        approvedTransactors[_transactor] = true;
    }

    function removeApprovedTransactor(address _transactor) public onlyOwner {
        delete approvedTransactors[_transactor];
    }

    function addPriceOracle(address _token, address _priceAggregator)
        external
        onlyOwner
    {
        priceOracles[_token] = AggregatorV3Interface(_priceAggregator);
    }

    function _getSwapDigest(Swap memory swap) private view returns (bytes32) {
        bytes32 data = keccak256(abi.encode(SWAP_TYPEHASH, swap));
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, data));
    }

    /**
     * Returns the latest price
     */
    function _getLatestPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (int256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function verifySwapRequest(
        address signer,
        Swap memory swap,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        address recoveredAddress = ecrecover(_getSwapDigest(swap), v, r, s);
        require(
            recoveredAddress != address(0) && signer == recoveredAddress,
            "Invalid signature"
        );
        require(
            swap.nonce == nonces[signer][swap.from_vault][swap.to_vault]++,
            "Invalid nonce"
        );
        require(
            swap.expiration == 0 || block.timestamp <= swap.expiration,
            "Expired request"
        );
        require(swap.amount > 0, "Swap Amount should be greater than 0");
        return true;
    }

    function verifySwapBatchRequest(SwapTx[] memory swapTx)
        public
        returns (bool)
    {
        require(swapTx.length > 0, "SwapTx length should be greater than 0");
        address prevFromVault = swapTx[0].swap.from_vault;
        address prevToVault = swapTx[0].swap.to_vault;
        for (uint256 i = 0; i < swapTx.length; i++) {
            Swap memory swap = swapTx[i].swap;
            require(prevFromVault == swap.from_vault);
            require(prevToVault == swap.to_vault);
            require(
                verifySwapRequest(
                    swap.user,
                    swap,
                    swapTx[i].v,
                    swapTx[i].r,
                    swapTx[i].s
                ) == true
            );
        }
        return true;
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20Upgradeable _token = IERC20Upgradeable(token);
        if (_token.allowance(address(this), spender) >= amount) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    function _pullTokens(SwapTx[] memory swapTx) internal returns (uint256) {
        uint256 totalWithdraw = 0;
        for (uint256 i = 0; i < swapTx.length; i++) {
            Swap memory swap = swapTx[i].swap;
            IERC20Upgradeable(swap.from_vault).safeTransferFrom(
                swap.user,
                address(this),
                swap.amount
            );
            totalWithdraw = totalWithdraw.add(swap.amount);
        }
        return totalWithdraw;
    }

    function _distributeTokens(
        SwapTx[] memory swapTx,
        address tokenAddr,
        uint256 totalWithdraw,
        uint256 distributableTokens
    ) private {
        for (uint256 i = 0; i < swapTx.length; i++) {
            Swap memory swap = swapTx[i].swap;
            uint256 v = swap.amount.mul(distributableTokens).div(totalWithdraw);
            IERC20Upgradeable(tokenAddr).transfer(swap.user, v);
        }
    }

    function swapBatch(
        SwapTx[] memory swapTx,
        address vaultSwapper,
        uint256 minAmountOut,
        IVaultSwapper.Swap[] calldata instructions
    ) external onlyApprovedTransactors {
        uint256 initGas = gasleft();

        verifySwapBatchRequest(swapTx);

        uint256 totalWithdraw = _pullTokens(swapTx);

        address underlyingAddr = IVault(swapTx[0].swap.from_vault).token();
        address toVaultAddr = swapTx[0].swap.to_vault;

        _approveToken(swapTx[0].swap.from_vault, vaultSwapper, totalWithdraw);

        uint256 balanceBefore = IERC20Upgradeable(toVaultAddr).balanceOf(
            address(this)
        );
        IVaultSwapper(vaultSwapper).swap(
            swapTx[0].swap.from_vault,
            toVaultAddr,
            totalWithdraw,
            minAmountOut,
            instructions
        );
        uint256 balance = IERC20Upgradeable(toVaultAddr)
            .balanceOf(address(this))
            .sub(balanceBefore);

        // Calculate tx fees
        uint256 pETH = uint256(_getLatestPrice(priceOracles[underlyingAddr]));
        uint256 afterDepositGas = gasleft();
        uint256 estTotalGas = initGas.sub(afterDepositGas).add(
            estGasPerTransfer.mul(swapTx.length)
        );
        uint256 estTxFees = estTotalGas
            .mul(block.basefee + 5e9)
            .mul(
                10 **
                    uint256(
                        IERC20MetadataUpgradeable(underlyingAddr).decimals()
                    )
            )
            .div(pETH);

        // Distribute the output tokens to the users.
        _distributeTokens(
            swapTx,
            toVaultAddr,
            totalWithdraw,
            balance.sub(estTxFees)
        );
    }

    function withdrawEth() external onlyOwner {
        address payable to = payable(_msgSender());
        to.transfer(address(this).balance);
    }

    function withdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(_msgSender(), amount);
    }

    function withdrawTokenTo(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }
}
