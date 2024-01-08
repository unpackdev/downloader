// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./IAddressList.sol";
import "./IAddressListFactory.sol";
import "./ISwapManager.sol";
import "./ICompound.sol";
import "./IVUSD.sol";
import "./ITreasury.sol";

/// @title VUSD Treasury, It stores cTokens and redeem those from Compound as needed.
contract Treasury is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string public constant NAME = "VUSD-Treasury";
    string public constant VERSION = "1.1.0";

    IAddressList public immutable whitelistedTokens;
    IAddressList public immutable cTokenList;
    IVUSD public immutable vusd;
    address public redeemer;
    address public keeper;

    ISwapManager public swapManager = ISwapManager(0xC48ea9A2daA4d816e4c9333D6689C70070010174);
    mapping(address => address) public cTokens;

    address internal constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    Comptroller internal constant COMPTROLLER = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // solhint-disable const-name-snakecase
    address internal constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address internal constant cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address internal constant cUSDT = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;
    // solhint-enable

    event UpdatedRedeemer(address indexed previousRedeemer, address indexed newRedeemer);
    event UpdatedKeeper(address indexed previousKeeper, address indexed newKeeper);
    event UpdatedSwapManager(address indexed previousSwapManager, address indexed newSwapManager);

    constructor(address _vusd) {
        require(_vusd != address(0), "vusd-address-is-zero");
        vusd = IVUSD(_vusd);

        IAddressListFactory _factory = IAddressListFactory(0xded8217De022706A191eE7Ee0Dc9df1185Fb5dA3);
        IAddressList _whitelistedTokens = IAddressList(_factory.createList());
        IAddressList _cTokenList = IAddressList(_factory.createList());
        // Add token into the list, add cToken into the mapping
        _addToken(_whitelistedTokens, DAI, _cTokenList, cDAI);
        _addToken(_whitelistedTokens, USDC, _cTokenList, cUSDC);
        _addToken(_whitelistedTokens, USDT, _cTokenList, cUSDT);

        whitelistedTokens = _whitelistedTokens;
        cTokenList = _cTokenList;
        _approveRouters(swapManager, type(uint256).max);
    }

    modifier onlyGovernor() {
        require(_msgSender() == governor(), "caller-is-not-the-governor");
        _;
    }

    modifier onlyAuthorized() {
        require(_msgSender() == governor() || _msgSender() == redeemer, "caller-is-not-authorized");
        _;
    }

    modifier onlyKeeperOrGovernor() {
        require(_msgSender() == governor() || _msgSender() == keeper, "caller-is-not-authorized");
        _;
    }

    ////////////////////////////// Only Governor //////////////////////////////
    /**
     * @notice Add token into treasury management system
     * @dev Add token address in whitelistedTokens list and add cToken in mapping
     * @param _token address which we want to add in token list.
     * @param _cToken CToken address correspond to _token
     */
    function addWhitelistedToken(address _token, address _cToken) external onlyGovernor {
        require(_token != address(0), "token-address-is-zero");
        require(_cToken != address(0), "cToken-address-is-zero");
        _addToken(whitelistedTokens, _token, cTokenList, _cToken);
    }

    /**
     * @notice Remove token from treasury management system
     * @dev Removing token even if treasury has some balance of that token is intended behavior.
     * @param _token address which we want to remove from token list.
     */
    function removeWhitelistedToken(address _token) external onlyGovernor {
        require(whitelistedTokens.remove(_token), "remove-from-list-failed");
        require(cTokenList.remove(cTokens[_token]), "remove-from-list-failed");
        IERC20(_token).approve(cTokens[_token], 0);
        delete cTokens[_token];
    }

    /**
     * @notice Update redeemer address
     * @param _newRedeemer new redeemer address
     */
    function updateRedeemer(address _newRedeemer) external onlyGovernor {
        require(_newRedeemer != address(0), "redeemer-address-is-zero");
        require(redeemer != _newRedeemer, "same-redeemer");
        emit UpdatedRedeemer(redeemer, _newRedeemer);
        redeemer = _newRedeemer;
    }

    /**
     * @notice Update keeper address
     * @param _newKeeper new keeper address
     */
    function updateKeeper(address _newKeeper) external onlyGovernor {
        require(_newKeeper != address(0), "keeper-address-is-zero");
        require(keeper != _newKeeper, "same-keeper");
        emit UpdatedKeeper(keeper, _newKeeper);
        keeper = _newKeeper;
    }

    /**
     * @notice Update swap manager address
     * @param _newSwapManager new swap manager address
     */
    function updateSwapManager(address _newSwapManager) external onlyGovernor {
        require(_newSwapManager != address(0), "swap-manager-address-is-zero");
        emit UpdatedSwapManager(address(swapManager), _newSwapManager);
        _approveRouters(swapManager, 0);
        _approveRouters(ISwapManager(_newSwapManager), type(uint256).max);
        swapManager = ISwapManager(_newSwapManager);
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Claim comp from all markets and convert to given token.
     * Also deposit those tokens to Compound
     * @param _toToken COMP will be swapped to _toToken
     * @param _minOut Minimum _toToken expected after conversion
     */
    function claimCompAndConvertTo(address _toToken, uint256 _minOut) external onlyKeeperOrGovernor {
        require(whitelistedTokens.contains(_toToken), "token-is-not-supported");
        uint256 _len = cTokenList.length();
        address[] memory _market = new address[](_len);
        for (uint8 i = 0; i < _len; i++) {
            (_market[i], ) = cTokenList.at(i);
        }
        COMPTROLLER.claimComp(address(this), _market);
        uint256 _compAmount = IERC20(COMP).balanceOf(address(this));
        (address[] memory path, uint256 amountOut, uint256 rIdx) =
            swapManager.bestOutputFixedInput(COMP, _toToken, _compAmount);
        if (amountOut != 0) {
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                _compAmount,
                _minOut,
                path,
                address(this),
                block.timestamp
            );
        }
        require(CToken(cTokens[_toToken]).mint(IERC20(_toToken).balanceOf(address(this))) == 0, "cToken-mint-failed");
    }

    /**
     * @notice Migrate assets to new treasury
     * @param _newTreasury Address of new treasury of VUSD system
     */
    function migrate(address _newTreasury) external onlyGovernor {
        require(_newTreasury != address(0), "new-treasury-address-is-zero");
        require(address(vusd) == ITreasury(_newTreasury).vusd(), "vusd-mismatch");
        uint256 _len = cTokenList.length();
        for (uint256 i = 0; i < _len; i++) {
            (address _cToken, ) = cTokenList.at(i);
            IERC20(_cToken).safeTransfer(_newTreasury, IERC20(_cToken).balanceOf(address(this)));
        }
    }

    /**
     * @notice Withdraw given amount of token.
     * @dev Only Redeemer and Governor are allowed to call
     * @param _token Token to withdraw, it should be 1 of the supported tokens.
     * @param _amount token amount to withdraw
     */
    function withdraw(address _token, uint256 _amount) external nonReentrant onlyAuthorized {
        _withdraw(_token, _amount, _msgSender());
    }

    /**
     * @notice Withdraw given amount of token.
     * @dev Only Redeemer and Governor are allowed to call
     * @param _token Token to withdraw, it should be 1 of the supported tokens.
     * @param _amount token amount to withdraw
     * @param _tokenReceiver Address of token receiver
     */
    function withdraw(
        address _token,
        uint256 _amount,
        address _tokenReceiver
    ) external nonReentrant onlyAuthorized {
        _withdraw(_token, _amount, _tokenReceiver);
    }

    /**
     * @notice Withdraw multiple tokens.
     * @dev Only Governor is allowed to call.
     * @dev _tokens and _amounts array are 1:1 and should have same length
     * @param _tokens Array of token addresses, tokens should be supported tokens.
     * @param _amounts Array of token amount to withdraw
     */
    function withdrawMulti(address[] memory _tokens, uint256[] memory _amounts) external nonReentrant onlyGovernor {
        require(_tokens.length == _amounts.length, "input-length-mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            _withdraw(_tokens[i], _amounts[i], _msgSender());
        }
    }

    /**
     * @notice Withdraw all of multiple tokens.
     * @dev Only Governor is allowed to call.
     * @param _tokens Array of token addresses, tokens should be supported tokens.
     */
    function withdrawAll(address[] memory _tokens) external nonReentrant onlyGovernor {
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(whitelistedTokens.contains(_tokens[i]), "token-is-not-supported");
            CToken _cToken = CToken(cTokens[_tokens[i]]);
            require(_cToken.redeem(_cToken.balanceOf(address(this))) == 0, "redeem-failed");
            IERC20(_tokens[i]).safeTransfer(_msgSender(), IERC20(_tokens[i]).balanceOf(address(this)));
        }
    }

    /**
     * @notice Sweep any ERC20 token to governor address
     * @dev OnlyGovernor can call this and CTokens are not allowed to sweep
     * @param _fromToken Token address to sweep
     */
    function sweep(address _fromToken) external onlyGovernor {
        // Do not sweep cTokens
        require(!cTokenList.contains(_fromToken), "cToken-is-not-allowed-to-sweep");

        uint256 _amount = IERC20(_fromToken).balanceOf(address(this));
        IERC20(_fromToken).safeTransfer(_msgSender(), _amount);
    }

    /**
     * @notice Current withdrawable amount for given token.
     * If token is not supported by treasury, no cTokens in mapping, it will return 0.
     * @param _token Token to withdraw
     */
    function withdrawable(address _token) external view returns (uint256) {
        if (cTokens[_token] != address(0)) {
            CToken _cToken = CToken(cTokens[_token]);
            return (_cToken.balanceOf(address(this)) * _cToken.exchangeRateStored()) / 1e18;
        }
        return 0;
    }

    /// @dev Governor is defined in VUSD token contract only
    function governor() public view returns (address) {
        return vusd.governor();
    }

    /// @dev Add _token into the list, add _cToken in mapping
    function _addToken(
        IAddressList _list,
        address _token,
        IAddressList _cTokenList,
        address _cToken
    ) internal {
        require(_list.add(_token), "add-in-list-failed");
        require(_cTokenList.add(_cToken), "add-in-list-failed");
        cTokens[_token] = _cToken;
        IERC20(_token).safeApprove(_cToken, type(uint256).max);
    }

    /// @notice Approve all routers to spend COMP
    function _approveRouters(ISwapManager _swapManager, uint256 _amount) internal {
        for (uint256 i = 0; i < _swapManager.N_DEX(); i++) {
            IERC20(COMP).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    function _withdraw(
        address _token,
        uint256 _amount,
        address _tokenReceiver
    ) internal {
        require(whitelistedTokens.contains(_token), "token-is-not-supported");
        require(CToken(cTokens[_token]).redeemUnderlying(_amount) == 0, "redeem-underlying-failed");
        IERC20(_token).safeTransfer(_tokenReceiver, _amount);
    }
}
