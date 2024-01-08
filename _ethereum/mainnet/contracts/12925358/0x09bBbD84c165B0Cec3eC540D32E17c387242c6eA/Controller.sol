// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IController.sol";
import "./IGToken.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./ECDSA.sol";
import "./TimelockController.sol";
import "./TransparentUpgradeableProxy.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2ERC20.sol";

contract Controller is IController, OwnableUpgradeable {
    using SafeERC20 for IERC20Metadata;
    using ECDSA for bytes32;

    // ---------------------------------------------------------
    // STORAGE VAR DECLARATION BEGINS HERE
    // ---------------------------------------------------------

    // ---------------------------------------------------------
    // The following storage variables are inherited:
    // bool private _initialized;
    // bool private _initializing;
    // address private _owner;
    // uint256[49] private __gap;
    // ---------------------------------------------------------

    IUniswapV2Router02 Router;
    IUniswapV2Factory Factory;

    // Keeps track of authorized function callers (Geode)
    mapping(address => bool) public relayers;

    // Trusted token pair
    mapping(address => bool) public trustedPair;

    mapping(address => uint256) public nonces;

    // the receipient of the user's ERC20 payment
    address gasFeeHolder;

    // ---------------------------------------------------------
    // STORAGE VAR DECLARATION ENDS HERE
    // ---------------------------------------------------------

    // INIT_CODE_HASH = hex"d0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66"; - Pancake BSCTEST
    // INIT_CODE_HASH = hex"00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5"; - Pancake BSCMAIN
    // INIT_CODE_HASH = hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"; - Uniswap ETHMAIN/QUICKSWAP
    bytes32 public constant INIT_CODE_HASH = hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"; // does not take up storage

    // EIP 712 signature

    // bytes32 public ADDLIQUIDITY_TYPEHASH =
    //     keccak256("AddLiquidity(address tokenA,address tokenB,uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin,address user,uint256 nonce,uint256 deadline,uint256 feeAmount,address feeToken)");
    bytes32 public constant ADDLIQUIDITY_TYPEHASH = 0x4d214baa73121bf1fd881822ff725e82a5194849fe9f33fa2cf93d3a8bcc1528;
    // bytes32 public SWAP_TYPEHASH =
    //     keccak256("Swap(uint256 amount0,uint256 amount1,address[] path,address user,uint256 nonce,uint256 deadline,uint256 feeAmount,address feeToken)");
    bytes32 public constant SWAP_TYPEHASH = 0x7f9ea4937fd3ee4bc72c788ef9ed621218765f5b35f26092eec44a8aac0b8c5b;

    struct SIGNATURE_TYPE {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @param tokenA: address of the ERC20 token <A>
     * @param tokenB: address of the ERC20 token <B>
     * @param amountADesired: the amount of token A the sender is willing to provide
     * @param amountBDesired: the amount of token B the sender is willing to provide
     * @param amountAMin: the minimum amount of token A the sender must provide
     * @param amountBMin: the minimum amount of token B the sender must provide
     * @param user: sender and LP Token recipient address
     * @param deadline: Unix timestamp after which the transaction will revert
     * @param feeAmount: The fee amount to be paid
     * @param feeToken: the address of the ERC20 token to be paid for fee (non GTokens only)
     */
    struct ADDLIQUIDITY_TYPE {
        address tokenA;
        address tokenB;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        address user;
        uint256 deadline;
        uint256 feeAmount;
        address feeToken;
    }

    /**
     * @param amount0
     * @param amount1
     * @param path: the array of token addresses
     * @param user: user address
     * @param deadline: Unix timestamp after which the transaction will revert
     * @param feeAmount: The fee amount to be paid
     * @param feeToken: the address of the ERC20 token to be paid for fee (non GTokens only)
     */
    struct SWAP_TYPE {
        uint256 amount0;
        uint256 amount1;
        address[] path;
        address user;
        uint256 deadline;
        uint256 feeAmount;
        address feeToken;
    }

    /**
     * @param tokenA: address of the ERC20 token <A>
     * @param tokenB: address of the ERC20 token <B>
     * @param amountAMin: the minimum amount of token A the sender must provide
     * @param amountBMin: the minimum amount of token B the sender must provide
     * @param user: sender and LP Token recipient address
     * @param deadline: Unix timestamp after which the transaction will revert
     */
    struct REMOVELIQUIDITY_TYPE {
        address tokenA;
        address tokenB;
        uint256 liquidity;
        uint256 amountAMin;
        uint256 amountBMin;
        address user;
        uint256 deadline;
        bool approveMax;
    }

    // Event loggers
    event RelayerAssignment(address indexed _relayer, bool _assignment);
    event PairTrusted(address indexed _pair, bool _status);
    event Config(address indexed _factory, address indexed _router);
    event RouterReverted(address indexed _user, uint256 _fee);
    event RouterSucceeded(address indexed _user, uint256 _fee);
    event GasFeeHolderConfigured(address indexed _gasFeeHolder);

    // ---------------------------------------------------------
    // FUNCTION DEFINITION BEGINS HERE
    // ---------------------------------------------------------

    function verifySignature(
        bytes32 digest,
        address signer,
        SIGNATURE_TYPE memory sig
    ) public pure returns (bool) {
        address verifier = digest.recover(sig.v, sig.r, sig.s);
        return (signer == verifier) && (signer != address(0));
    }

    function _getChainId() private view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _getDomainSeparator() private view returns (bytes32) {
        uint256 chainId = _getChainId();
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes("GToken")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * Collects the payment
     */
    function _receivePayment(
        address _user,
        IGToken _token,
        uint256 _amount
    ) private {
        require(gasFeeHolder != address(0), "GTokenController: gasFeeHolder not configured!");
        // transfers the token to the relayer
        _token.transferFrom(_user, gasFeeHolder, _amount);
    }

    function initialize(
        address _relayer,
        address _router,
        address _factory
    ) public initializer() {
        relayers[_relayer] = true;
        Router = IUniswapV2Router02(_router);
        Factory = IUniswapV2Factory(_factory);
        __Ownable_init();
    }

    /**
     * Adds a new Geode address. Can only be called by the contract owner
     * @param _relayer: trusted address
     * @param _assignment: True: assigns relayer privilege, False: revokes relayer privilege
     */
    function setRelayer(address _relayer, bool _assignment) public onlyOwner() {
        relayers[_relayer] = _assignment;
        emit RelayerAssignment(_relayer, _assignment);
    }

    /**
     * Checks if input address is an authorized relayer
     * @param _relayer: input address
     * @return bool
     */
    function isRelayer(address _relayer) external view override returns (bool) {
        return relayers[_relayer];
    }

    /**
     * Same as isRelayer(), the modifier checks the caller if it is an authorized caller
     */
    modifier relayerOnly() {
        require(relayers[msg.sender], "GTOKENController: !relayer");
        _;
    }

    /**
     * Checks for authorized token pairs
     * @param pair: address to the pair
     * @return bool
     */
    function isTrustedPair(address pair) public view override returns (bool) {
        return trustedPair[pair];
    }

    /**
     * Grants authorization to a new token pair
     * @param pair: address to the pair
     */
    function addTrustedPair(address pair) public onlyOwner() {
        trustedPair[pair] = true;
        emit PairTrusted(pair, true);
    }

    /**
     * Revoke authorization from a token pair
     * @param pair: address to the pair
     */
    function removeTrustedPair(address pair) public onlyOwner() {
        trustedPair[pair] = false;
        emit PairTrusted(pair, false);
    }

    /**
     * Configures the gasFeeHolder address
     * @param _gasFeeHolder: the gasFeeHolder's address
     */
    function setGasFeeHolder(address _gasFeeHolder) public onlyOwner() {
        gasFeeHolder = _gasFeeHolder;
        emit GasFeeHolderConfigured(_gasFeeHolder);
    }

    /**
     * Supplies the token pair to the liquidity pool, requires it can only be called by a relayer and tokens must be wrapped
     * The sender will be refunded by the controller if some of the tokens left are not sent to the pool
     * Adds the pair as trusted pair
     */
    function addLiquidity(ADDLIQUIDITY_TYPE memory al, SIGNATURE_TYPE memory signature) public relayerOnly() {
        {
            require(
                isTrustedPair(pairFor(address(Factory), al.tokenA, al.tokenB)),
                "GTokenController: Not a trusted pair!"
            );
            require(al.deadline >= block.timestamp, "GTOKENController: signature expired!");
            // Generate digest
            bytes32 message = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            ADDLIQUIDITY_TYPEHASH,
                            al.tokenA,
                            al.tokenB,
                            al.amountADesired,
                            al.amountBDesired,
                            al.amountAMin,
                            al.amountBMin,
                            al.user,
                            nonces[al.user]++,
                            al.deadline,
                            al.feeAmount,
                            al.feeToken
                        )
                    )
                )
            );
            require(verifySignature(message, al.user, signature), "GTOKENController: Invalid signature!");
        }

        bool feeIsTokenA = address(IGToken(al.tokenA)) == al.feeToken;
        IGToken token = feeIsTokenA ? IGToken(al.tokenA) : IGToken(al.tokenB);
        if (feeIsTokenA) {
            _wrapTokens(al.tokenA, al.user, al.amountADesired + al.feeAmount);
            _wrapTokens(al.tokenB, al.user, al.amountBDesired);
        } else {
            _wrapTokens(al.tokenA, al.user, al.amountADesired);
            _wrapTokens(al.tokenB, al.user, al.amountBDesired + al.feeAmount);
        }

        {
            // collect the fee
            _receivePayment(al.user, token, al.feeAmount);
        }

        {
            // avoid stack too deep

            IGToken(al.tokenA).transferFrom(al.user, address(this), al.amountADesired);
            IGToken(al.tokenB).transferFrom(al.user, address(this), al.amountBDesired);

            try
                Router.addLiquidity(
                    al.tokenA,
                    al.tokenB,
                    al.amountADesired,
                    al.amountBDesired,
                    al.amountAMin,
                    al.amountBMin,
                    al.user,
                    al.deadline
                )
            returns (uint256 amountA, uint256 amountB, uint256) {
                uint256 diffA = al.amountADesired - (amountA);
                uint256 diffB = al.amountBDesired - (amountB);

                if (diffA > 0) {
                    IGToken(al.tokenA).transferFrom(address(this), al.user, diffA);
                    _unwrapTokens(al.tokenA, al.user, diffA);
                }

                if (diffB > 0) {
                    IGToken(al.tokenB).transferFrom(address(this), al.user, diffB);
                    _unwrapTokens(al.tokenB, al.user, diffB);
                }
                emit RouterSucceeded(al.user, al.feeAmount);
            } catch {
                // refund the user
                IGToken(al.tokenA).transferFrom(al.user, address(this), al.amountADesired);
                IGToken(al.tokenB).transferFrom(al.user, address(this), al.amountBDesired);

                _unwrapTokens(al.tokenA, al.user, al.amountADesired);
                _unwrapTokens(al.tokenA, al.user, al.amountBDesired);

                emit RouterReverted(al.user, al.feeAmount);
            }
        }
    }

    function swapExactTokensForTokens(SWAP_TYPE memory swap, SIGNATURE_TYPE memory signature) public relayerOnly() {
        uint256 end = swap.path.length - 1;
        for (uint256 i = 1; i <= end; i++) {
            require(
                isTrustedPair(pairFor(address(Factory), swap.path[i - 1], swap.path[i])),
                "GTokenController: Not a trusted pair!"
            );
        }

        {
            require(swap.deadline >= block.timestamp, "GTOKENController: signature expired!");

            // NOTE: It is necessary to hash a non-atomic type, such as type[] or struct.
            // See https://stackoverflow.com/questions/58257459/solidity-web3js-eip712-signing-uint256-works-signing-uint256-does-not
            // Also https://eips.ethereum.org/EIPS/eip-712#specification
            bytes32 message = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            SWAP_TYPEHASH,
                            swap.amount0,
                            swap.amount1,
                            keccak256(abi.encodePacked(swap.path)),
                            swap.user,
                            nonces[swap.user]++,
                            swap.deadline,
                            swap.feeAmount,
                            swap.feeToken
                        )
                    )
                )
            );
            require(verifySignature(message, swap.user, signature), "GTOKENController: Invalid signature!");
        }

        _wrapTokens(swap.path[0], swap.user, swap.amount0 + swap.feeAmount);

        {
            // collect the fee
            _receivePayment(swap.user, IGToken(swap.path[0]), swap.feeAmount);
        }

        IGToken(swap.path[0]).transferFrom(swap.user, address(this), swap.amount0);

        try Router.swapExactTokensForTokens(swap.amount0, swap.amount1, swap.path, swap.user, swap.deadline) returns (
            uint256[] memory amounts
        ) {
            // unwrap output tokens only. there will be no input amounts remaining (given that they are being transferred in exact amount)
            _unwrapTokens(swap.path[end], swap.user, amounts[end]);
            emit RouterSucceeded(swap.user, swap.feeAmount);
        } catch {
            IGToken(swap.path[0]).transferFrom(address(this), swap.user, swap.amount0);
            _unwrapTokens(swap.path[0], swap.user, swap.amount0);
            emit RouterReverted(swap.user, swap.feeAmount);
        }
    }

    /**
     * Swaps an exact amount input of token for as much of output tokens as possible, requires it can only be called by a relayer and tokens must be wrapped
     */
    function swapTokensForExactTokens(SWAP_TYPE memory swap, SIGNATURE_TYPE memory signature) public relayerOnly() {
        uint256 end = swap.path.length - 1;
        for (uint256 i = 1; i <= end; i++) {
            require(
                isTrustedPair(pairFor(address(Factory), swap.path[i - 1], swap.path[i])),
                "GTokenController: Not a trusted pair!"
            );
        }

        {
            require(swap.deadline >= block.timestamp, "GTOKENController: signature expired!");

            // NOTE: It is necessary to hash a non-atomic type, such as type[] or struct.
            // See https://stackoverflow.com/questions/58257459/solidity-web3js-eip712-signing-uint256-works-signing-uint256-does-not
            // Also https://eips.ethereum.org/EIPS/eip-712#specification
            bytes32 message = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            SWAP_TYPEHASH,
                            swap.amount0,
                            swap.amount1,
                            keccak256(abi.encodePacked(swap.path)),
                            swap.user,
                            nonces[swap.user]++,
                            swap.deadline,
                            swap.feeAmount,
                            swap.feeToken
                        )
                    )
                )
            );
            require(verifySignature(message, swap.user, signature), "GTOKENController: Invalid signature!");
        }

        _wrapTokens(swap.path[0], swap.user, swap.amount1 + swap.feeAmount);

        {
            // collect the fee
            _receivePayment(swap.user, IGToken(swap.path[0]), swap.feeAmount);
        }

        IGToken(swap.path[0]).transferFrom(swap.user, address(this), swap.amount1);

        try Router.swapTokensForExactTokens(swap.amount0, swap.amount1, swap.path, swap.user, swap.deadline) returns (
            uint256[] memory amounts
        ) {
            uint256 diff = swap.amount1 - amounts[0];
            if (diff > 0) {
                IGToken(swap.path[0]).transferFrom(address(this), swap.user, diff);
                _unwrapTokens(swap.path[0], swap.user, diff);
            }

            // unwrap tokens
            _unwrapTokens(swap.path[end], swap.user, amounts[end]);
            emit RouterSucceeded(swap.user, swap.feeAmount);
        } catch {
            IGToken(swap.path[0]).transferFrom(address(this), swap.user, swap.amount1);
            _unwrapTokens(swap.path[0], swap.user, swap.amount1);
            emit RouterReverted(swap.user, swap.feeAmount);
        }
    }

    function _wrapTokens(
        address _gtoken,
        address _user,
        uint256 _amount
    ) private {
        IGToken(_gtoken)._wrap(_amount, _user);
    }

    function _unwrapTokens(
        address _gtoken,
        address _user,
        uint256 _amount
    ) private {
        IGToken(_gtoken)._unwrap(_amount, _user);
    }

    /**
     * Configure the Factory and Router Interface
     */
    function config(address _factory, address _router) public onlyOwner() {
        Factory = IUniswapV2Factory(_factory);
        Router = IUniswapV2Router02(_router);
        emit Config(_factory, _router);
    }

    function router() external view override returns (address) {
        return address(Router);
    }

    /**
     * Removes liquidity. Users send their LP tokens and get their tokens unwrapped to native tokens
     */
    function removeLiquidityWithPermit(REMOVELIQUIDITY_TYPE memory rl, SIGNATURE_TYPE memory sig) public {
        address pair = pairFor(address(Factory), rl.tokenA, rl.tokenB);
        require(isTrustedPair(pair), "GTokenController: Not a trusted pair!");
        uint256 value = rl.liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, rl.deadline, sig.v, sig.r, sig.s);

        (bool success, bytes memory result) = address(Router).delegatecall(
            abi.encodeWithSelector(
                bytes4(Router.removeLiquidity.selector),
                rl.tokenA,
                rl.tokenB,
                rl.liquidity,
                rl.amountAMin,
                rl.amountBMin,
                rl.user,
                rl.deadline
            )
        );

        require(success, string(result));

        (uint256 amountA, uint256 amountB) = abi.decode(result, (uint256, uint256));

        _unwrapTokens(rl.tokenA, rl.user, amountA);
        _unwrapTokens(rl.tokenB, rl.user, amountB);
    }

    // Code obtained from Library -- Not compatible with Solc0.8

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "GTokenController: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "GTokenController: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}
