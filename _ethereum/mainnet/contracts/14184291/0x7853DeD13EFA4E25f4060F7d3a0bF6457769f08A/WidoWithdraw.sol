//SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.7;

// import "./console.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AggregatorV3Interface.sol";

interface Vault {
    function withdraw(uint256 _shares) external;
}

contract WidoWithdraw is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 private constant WITHDRAW_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Withdraw(address user,address vault,uint256 amount,address token,uint32 nonce,uint32 expiration)"
            )
        );

    bytes32 public DOMAIN_SEPARATOR;

    uint256 private estGasPerTransfer;

    struct Withdraw {
        address user;
        address vault;
        uint256 amount;
        address token;
        uint32 nonce;
        uint32 expiration;
    }

    struct WithdrawTx {
        Withdraw withdraw;
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
                keccak256("WidoWithdraw"),
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

    function _getWithdrawDigest(Withdraw memory withdraw)
        private
        view
        returns (bytes32)
    {
        bytes32 data = keccak256(abi.encode(WITHDRAW_TYPEHASH, withdraw));
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

    function verifyWithdrawRequest(
        address signer,
        Withdraw memory withdraw,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        address recoveredAddress = ecrecover(
            _getWithdrawDigest(withdraw),
            v,
            r,
            s
        );
        require(
            recoveredAddress != address(0) && signer == recoveredAddress,
            "Invalid signature"
        );
        require(
            withdraw.nonce == nonces[signer][withdraw.token][withdraw.vault]++,
            "Invalid nonce"
        );
        require(
            withdraw.expiration == 0 || block.timestamp <= withdraw.expiration,
            "Expired request"
        );
        require(
            withdraw.amount > 0,
            "Withdraw Amount should be greater than 0"
        );
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

    function _pullTokens(WithdrawTx[] memory withdrawTx)
        internal
        returns (uint256)
    {
        uint256 totalWithdraw = 0;
        for (uint256 i = 0; i < withdrawTx.length; i++) {
            Withdraw memory withdraw = withdrawTx[i].withdraw;
            IERC20Upgradeable(withdraw.vault).safeTransferFrom(
                withdraw.user,
                address(this),
                withdraw.amount
            );
            totalWithdraw = totalWithdraw.add(withdraw.amount);
        }
        return totalWithdraw;
    }

    function verifyWithdrawBatchRequest(WithdrawTx[] memory withdrawTx)
        public
        returns (bool)
    {
        require(
            withdrawTx.length > 0,
            "WithdrawTx length should be greater than 0"
        );
        address prevVault = withdrawTx[0].withdraw.vault;
        address prevToken = withdrawTx[0].withdraw.token;
        for (uint256 i = 0; i < withdrawTx.length; i++) {
            Withdraw memory withdraw = withdrawTx[i].withdraw;
            require(prevVault == withdraw.vault);
            require(prevToken == withdraw.token);
            require(
                verifyWithdrawRequest(
                    withdraw.user,
                    withdraw,
                    withdrawTx[i].v,
                    withdrawTx[i].r,
                    withdrawTx[i].s
                ) == true
            );
        }
        return true;
    }

    function _distributeTokens(
        WithdrawTx[] memory withdrawTx,
        address tokenAddr,
        uint256 totalWithdraw,
        uint256 distributableTokens
    ) private {
        for (uint256 i = 0; i < withdrawTx.length; i++) {
            Withdraw memory withdraw = withdrawTx[i].withdraw;
            uint256 v = withdraw.amount.mul(distributableTokens).div(
                totalWithdraw
            );
            IERC20Upgradeable(tokenAddr).transfer(withdraw.user, v);
        }
    }

    function withdrawBatch(
        WithdrawTx[] memory withdrawTx,
        address payable ZapContract,
        bytes calldata zapCallData
    ) external onlyApprovedTransactors {
        uint256 initGas = gasleft();

        verifyWithdrawBatchRequest(withdrawTx);

        uint256 totalWithdraw = _pullTokens(withdrawTx);

        address tokenAddr = withdrawTx[0].withdraw.token;
        address vaultAddr = withdrawTx[0].withdraw.vault;

        // Approve contract to transfer from Wido.
        if (ZapContract != address(0)) {
            _approveToken(vaultAddr, ZapContract, totalWithdraw);
        } else {
            // _approveToken(vaultAddr, vaultAddr, totalDeposit);
        }

        uint256 initToken = IERC20Upgradeable(tokenAddr).balanceOf(
            address(this)
        );
        {
            // Withdraw tokens from the vault.
            if (ZapContract != address(0)) {
                (bool success, ) = ZapContract.call(zapCallData);
                require(success, "Zap Out Failed");
            } else {
                Vault(vaultAddr).withdraw(totalWithdraw);
            }
        }
        uint256 newToken = IERC20Upgradeable(tokenAddr)
            .balanceOf(address(this))
            .sub(initToken);

        // Calculate fees in yTokens
        uint256 pETH;
        if (tokenAddr == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            pETH = 1e18;
        } else {
            pETH = uint256(_getLatestPrice(priceOracles[tokenAddr]));
        }
        uint256 afterDepositGas = gasleft();
        uint256 estTotalGas = initGas.sub(afterDepositGas).add(
            estGasPerTransfer.mul(withdrawTx.length)
        );
        uint256 estTxFees = estTotalGas
            .mul(block.basefee + 3e9)
            .mul(10**uint256(IERC20MetadataUpgradeable(tokenAddr).decimals()))
            .div(pETH);

        // Distribute the output tokens to the users.
        _distributeTokens(
            withdrawTx,
            tokenAddr,
            totalWithdraw,
            newToken.sub(estTxFees)
        );
    }

    function collectGasReimbursementToken(address token, uint256 amount)
        external
        onlyOwner
    {
        IERC20Upgradeable(token).safeTransfer(_msgSender(), amount);
    }

    function collectGasReimbursementTokenTo(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }
}
