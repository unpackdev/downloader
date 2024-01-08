// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./IAddressList.sol";
import "./IAddressListFactory.sol";
import "./ICompound.sol";
import "./IVUSD.sol";

/// @title VUSD Treasury, It stores cTokens and redeem those from Compound as needed.
contract Treasury is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string public constant NAME = "VUSD-Treasury";
    string public constant VERSION = "1.1.0";

    IAddressList public immutable whitelistedTokens;
    IVUSD public immutable vusd;
    address public redeemer;

    mapping(address => address) public cTokens;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    event UpdatedRedeemer(address indexed previousRedeemer, address indexed newRedeemer);

    constructor(address _vusd) {
        require(_vusd != address(0), "vusd-address-is-zero");
        vusd = IVUSD(_vusd);

        IAddressListFactory _factory = IAddressListFactory(0xded8217De022706A191eE7Ee0Dc9df1185Fb5dA3);
        IAddressList _whitelistedTokens = IAddressList(_factory.createList());
        // Add token into the list, add cToken into the mapping
        _addToken(_whitelistedTokens, DAI, address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643));
        _addToken(_whitelistedTokens, USDC, address(0x39AA39c021dfbaE8faC545936693aC917d5E7563));
        _addToken(_whitelistedTokens, USDT, address(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9));

        whitelistedTokens = _whitelistedTokens;
    }

    modifier onlyGovernor() {
        require(_msgSender() == governor(), "caller-is-not-the-governor");
        _;
    }

    modifier onlyAuthorized() {
        require(_msgSender() == governor() || _msgSender() == redeemer, "caller-is-not-authorized");
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
        _addToken(whitelistedTokens, _token, _cToken);
    }

    /**
     * @notice Remove token from treasury management system
     * @dev Removing token even if treasury has some balance of that token is intended behavior.
     * @param _token address which we want to remove from token list.
     */
    function removeWhitelistedToken(address _token) external onlyGovernor {
        require(whitelistedTokens.remove(_token), "remove-from-list-failed");
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

    ///////////////////////////////////////////////////////////////////////////

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
        address _cToken
    ) internal {
        require(_list.add(_token), "add-in-list-failed");
        cTokens[_token] = _cToken;
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
