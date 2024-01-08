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
    function deposit(uint256 _amount) external;
}

contract Wido is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 private constant DEPOSIT_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Deposit(address user,address token,address vault,uint256 amount,uint32 nonce,uint32 expiration)"
            )
        );

    bytes32 public DOMAIN_SEPARATOR;

    uint256 private estGasPerTransfer;
    uint256 public firstUserTakeRate;

    struct Deposit {
        address user;
        address token;
        address vault;
        uint256 amount;
        uint32 nonce;
        uint32 expiration;
    }

    struct DepositTx {
        Deposit deposit;
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
        firstUserTakeRate = 10000;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Wido"),
                keccak256("1"),
                _chainId,
                address(this)
            )
        );
    }

    function setEstGasPerTransfer(uint256 _newValue) external onlyOwner {
        estGasPerTransfer = _newValue;
    }

    function setFirstUserTakeRate(uint256 _newValue) external onlyOwner {
        require(_newValue >= 0 && _newValue <= 10000);
        firstUserTakeRate = _newValue;
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

    function _getDepositDigest(Deposit memory deposit)
        private
        view
        returns (bytes32)
    {
        bytes32 data = keccak256(abi.encode(DEPOSIT_TYPEHASH, deposit));
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

    function verifyDepositRequest(
        address signer,
        Deposit memory deposit,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        address recoveredAddress = ecrecover(
            _getDepositDigest(deposit),
            v,
            r,
            s
        );
        require(
            recoveredAddress != address(0) && signer == recoveredAddress,
            "Invalid signature"
        );
        require(
            deposit.nonce == nonces[signer][deposit.token][deposit.vault]++,
            "Invalid nonce"
        );
        require(
            deposit.expiration == 0 || block.timestamp <= deposit.expiration,
            "Expired request"
        );
        require(deposit.amount > 0, "Deposit Amount should be greater than 0");
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

    function _pullTokens(DepositTx[] memory depositTx)
        internal
        returns (uint256)
    {
        uint256 totalDeposit = 0;
        for (uint256 i = 0; i < depositTx.length; i++) {
            Deposit memory deposit = depositTx[i].deposit;
            IERC20Upgradeable(deposit.token).safeTransferFrom(
                deposit.user,
                address(this),
                deposit.amount
            );
            totalDeposit = totalDeposit.add(deposit.amount);
        }
        return totalDeposit;
    }

    function verifyDepositPoolRequest(DepositTx[] memory depositTx) public {
        require(
            depositTx.length > 0,
            "DepositTx length should be greater than 0"
        );
        address prevVault = depositTx[0].deposit.vault;
        address prevToken = depositTx[0].deposit.token;
        for (uint256 i = 0; i < depositTx.length; i++) {
            Deposit memory deposit = depositTx[i].deposit;
            require(prevVault == depositTx[i].deposit.vault);
            require(prevToken == depositTx[i].deposit.token);
            require(
                verifyDepositRequest(
                    deposit.user,
                    deposit,
                    depositTx[i].v,
                    depositTx[i].r,
                    depositTx[i].s
                ) == true
            );
        }
    }

    function _distributeTokens(
        DepositTx[] memory depositTx,
        address vaultAddr,
        uint256 totalDeposit,
        uint256 receivedYTokens,
        uint256 feeYToken
    ) private {
        receivedYTokens = receivedYTokens.sub(feeYToken);

        for (uint256 i = 0; i < depositTx.length; i++) {
            Deposit memory deposit = depositTx[i].deposit;
            uint256 v = deposit.amount.mul(receivedYTokens).div(totalDeposit);
            // Reimburse fees for first deposit user
            if (i == 0) {
                uint256 feeDeducted = feeYToken.div(depositTx.length);
                v = v.add(
                    feeDeducted.sub(
                        feeDeducted.mul(firstUserTakeRate).div(10000)
                    )
                );
            }
            IERC20Upgradeable(vaultAddr).transfer(deposit.user, v);
        }
    }

    function depositPool(
        DepositTx[] memory depositTx,
        address payable ZapContract,
        bytes calldata zapCallData
    ) external onlyApprovedTransactors {
        uint256 initGas = gasleft();

        verifyDepositPoolRequest(depositTx);

        uint256 totalDeposit = _pullTokens(depositTx);

        address tokenAddr = depositTx[0].deposit.token;
        address vaultAddr = depositTx[0].deposit.vault;

        // Approve contract to transfer from Wido.
        if (ZapContract != address(0)) {
            _approveToken(tokenAddr, ZapContract, totalDeposit);
        } else {
            _approveToken(tokenAddr, vaultAddr, totalDeposit);
        }

        uint256 initToken = IERC20Upgradeable(vaultAddr).balanceOf(
            address(this)
        );
        {
            // Deposit tokens in to the vault.
            if (ZapContract != address(0)) {
                (bool success, ) = ZapContract.call(zapCallData);
                require(success, "Zap In Failed");
            } else {
                Vault(vaultAddr).deposit(totalDeposit);
            }
        }
        uint256 newToken = IERC20Upgradeable(vaultAddr)
            .balanceOf(address(this))
            .sub(initToken);

        // Calculate fees in yTokens
        uint256 pETH = uint256(_getLatestPrice(priceOracles[tokenAddr]));
        uint256 afterDepositGas = gasleft();
        uint256 estTotalGas = initGas.sub(afterDepositGas).add(
            estGasPerTransfer.mul(depositTx.length)
        );
        uint256 estTxFees = estTotalGas.mul(block.basefee + 5e9).div(pETH).mul(
            10**uint256(IERC20MetadataUpgradeable(tokenAddr).decimals())
        );

        // Distribute the output tokens to the users.
        _distributeTokens(
            depositTx,
            vaultAddr,
            totalDeposit,
            newToken,
            estTxFees.mul(newToken).div(totalDeposit)
        );
    }

    function withdraw() external onlyOwner {
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
