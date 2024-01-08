// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;
import "./IAMB.sol";
import "./IMultiTokenMediator.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC2771ContextUpgradeable.sol";

/// @title UniswapV2Router02 Interface
interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// @title LemmaXDAI interface. LemmaXDAI exists on XDAI network.
interface ILemmaxDAI {
    function setDepositInfo(
        address account,
        uint256 amount,
        uint256 minLUSDCAmountOut
    ) external;
}

/// @title LemmaContract for Mainnet.
/// @author yashnaman
/// @dev All function calls are currently implemented.
contract LemmaMainnet is OwnableUpgradeable, ERC2771ContextUpgradeable {
    using SafeERC20 for IERC20;
    /// @notice mainnet AMB bridge contract
    IAMB public ambBridge;
    /// @notice mainnet multi-tokens mediator
    IMultiTokenMediator public multiTokenMediator;

    ILemmaxDAI public lemmaXDAI;
    uint256 public gasLimit;

    IERC20 public USDC;
    IERC20 public WETH;
    IUniswapV2Router02 public uniswapV2Router02;
    uint256 public totalETHDeposited;
    uint256 public cap;

    mapping(address => uint256) public withdrawalInfo;
    mapping(address => uint256) public minimumETHToBeWithdrawn;

    event ETHDeposited(address indexed account, uint256 indexed amount);
    event ETHWithdrawn(address indexed account, uint256 indexed amount);
    event WithdrawalInfoAdded(address indexed account, uint256 indexed amount);

    /// @notice Initialize proxy.
    /// @param _lemmaXDAI Lemma token deployed on xdai network.
    /// @param _ambBridge Bridge contract address on mainnet
    function initialize(
        IERC20 _USDC,
        IERC20 _WETH,
        ILemmaxDAI _lemmaXDAI,
        IUniswapV2Router02 _uniswapV2Router02,
        IAMB _ambBridge,
        IMultiTokenMediator _multiTokenMediator,
        address trustedForwarder,
        uint256 _cap
    ) public initializer {
        __Ownable_init();
        __ERC2771Context_init(trustedForwarder);
        USDC = _USDC;
        WETH = _WETH;
        lemmaXDAI = _lemmaXDAI;
        uniswapV2Router02 = _uniswapV2Router02;
        ambBridge = _ambBridge;
        require(
            _ambBridge.sourceChainId() == block.chainid,
            'ambBridge chainId not valid'
        );
        multiTokenMediator = _multiTokenMediator;
        require(
            _multiTokenMediator.bridgeContract() == address(_ambBridge),
            'Invalid ambBridge/multiTokenMediator'
        );
        setGasLimit(1000000);
        setCap(_cap);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        //this is same as ERC2771ContextUpgradeable._msgSender();
        //We want to use the _msgSender() implementation of ERC2771ContextUpgradeable
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        //this is same as ERC2771ContextUpgradeable._msgData();
        //We want to use the _msgData() implementation of ERC2771ContextUpgradeable
        return super._msgData();
    }

    /// @notice Set gas limit that is used to call bridge.
    /// @dev Only owner can set gas limit.
    function setGasLimit(uint256 _gasLimit) public onlyOwner {
        gasLimit = _gasLimit;
    }

    /// @notice Set cap
    /// @dev Only owner can set cap.
    function setCap(uint256 _cap) public onlyOwner {
        cap = _cap;
    }

    /// @notice Pay ethereum to deposit USDC.
    /// @dev Paid eth is converted to USDC on Uniswap and then deposited to lemmaXDAI.
    /// @param _minimumUSDCAmountOut is the minumum amount to get from Paid Eth.
    /// @param _minLUSDCAmountOut minimum LUSDC user should get on XDAI
    function deposit(uint256 _minimumUSDCAmountOut, uint256 _minLUSDCAmountOut)
        external
        payable
    {
        totalETHDeposited += msg.value;
        require(totalETHDeposited <= cap, 'Lemma: cap reached');
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(USDC);

        uint256[] memory amounts =
            uniswapV2Router02.swapExactETHForTokens{value: msg.value}(
                _minimumUSDCAmountOut,
                path,
                address(this),
                type(uint256).max
            );

        multiTokenTransfer(USDC, address(lemmaXDAI), amounts[1]);

        //now relay the depositInfo to lemmaXDAI
        bytes4 functionSelector = ILemmaxDAI.setDepositInfo.selector;
        bytes memory data =
            abi.encodeWithSelector(
                functionSelector,
                _msgSender(),
                amounts[1],
                _minLUSDCAmountOut
            );
        callBridge(address(lemmaXDAI), data, gasLimit);
        emit ETHDeposited(_msgSender(), msg.value);
    }

    /// @notice Set Withdraw Info
    /// @dev This function can be called by only lemmaXDAI contract via ambBridge contract.
    /// @param _account account is withdrawing
    /// @param  _amount USDC amount
    /// @param _minETHOut minimum Eth amount user is willing to get out
    function setWithdrawalInfo(
        address _account,
        uint256 _amount,
        uint256 _minETHOut
    ) external {
        require(_msgSender() == address(ambBridge), 'not ambBridge');
        require(
            ambBridge.messageSender() == address(lemmaXDAI),
            "ambBridge's messageSender is not lemmaXDAI"
        );
        withdrawalInfo[_account] += _amount;
        minimumETHToBeWithdrawn[_account] = _minETHOut;
        emit WithdrawalInfoAdded(_account, _amount);
    }

    /// @notice update the minimum ETH amount to get out after withdrawing
    /// @param _minETHOut minimum ETH amount
    function setMinimuETHToBeWithdrawn(uint256 _minETHOut) external {
        minimumETHToBeWithdrawn[_msgSender()] = _minETHOut;
    }

    /// @notice Withdraw eth based on the USDC amount set by WithdrawInfo.
    /// @dev The USDC set by withdrawInfo is converted to ETH on sushiswap and the ETH is transferred to _account.
    /// @param _account is an account withdrawn to.
    function withdraw(address _account) public {
        uint256 amount = withdrawalInfo[_account];
        uint256 minETHOut = minimumETHToBeWithdrawn[_account];
        delete withdrawalInfo[_account];
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(WETH);
        // uint256[] memory amounts =
        USDC.safeApprove(address(uniswapV2Router02), amount);
        uint256[] memory amounts =
            uniswapV2Router02.swapExactTokensForETH(
                amount,
                minETHOut,
                path,
                _account,
                type(uint256).max
            );
        emit ETHWithdrawn(_account, amounts[1]);
    }

    /// @dev This function is used for sending USDC to multiTokenMediator
    function multiTokenTransfer(
        IERC20 _token,
        address _receiver,
        uint256 _amount
    ) internal {
        require(_receiver != address(0), 'receiver is empty');
        // approve to multi token mediator and call 'relayTokens'
        _token.safeApprove(address(multiTokenMediator), _amount);
        multiTokenMediator.relayTokens(address(_token), _receiver, _amount);
    }

    /// @param _contractOnOtherSide is lemmaXDAI address deployed on xdai network in our case
    /// @param _data is ABI-encoded function data
    function callBridge(
        address _contractOnOtherSide,
        bytes memory _data,
        uint256 _gasLimit
    ) internal returns (bytes32 messageId) {
        // server can check event, `UserRequestForAffirmation(bytes32 indexed messageId, bytes encodedData)`,
        // emitted by amb bridge contract
        messageId = ambBridge.requireToPassMessage(
            _contractOnOtherSide,
            _data,
            _gasLimit
        );
    }
}
