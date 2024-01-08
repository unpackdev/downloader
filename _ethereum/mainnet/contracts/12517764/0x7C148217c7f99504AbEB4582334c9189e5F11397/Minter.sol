// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ReentrancyGuard.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./IAddressList.sol";
import "./IAddressListFactory.sol";
import "./ICompound.sol";
import "./IVUSD.sol";

/// @title Minter contract which will mint VUSD 1:1, less minting fee, with DAI, USDC or USDT.
contract Minter is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string public constant NAME = "VUSD-Minter";
    string public constant VERSION = "1.1.0";

    IAddressList public immutable whitelistedTokens;
    IVUSD public immutable vusd;

    uint256 public mintingFee; // Default no fee
    uint256 public constant MAX_MINTING_FEE = 10_000; // 10_000 = 100%
    uint256 public constant MINT_LIMIT = 50_000_000 * 10**18; // 50M VUSD

    mapping(address => address) public cTokens;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    event UpdatedMintingFee(uint256 previousMintingFee, uint256 newMintingFee);

    constructor(address _vusd) {
        require(_vusd != address(0), "vusd-address-is-zero");
        vusd = IVUSD(_vusd);

        IAddressListFactory _factory = IAddressListFactory(0xded8217De022706A191eE7Ee0Dc9df1185Fb5dA3);
        IAddressList _whitelistedTokens = IAddressList(_factory.createList());
        // Add token into the list, add cToken into the mapping and approve cToken to spend token
        _addToken(_whitelistedTokens, DAI, address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643));
        _addToken(_whitelistedTokens, USDC, address(0x39AA39c021dfbaE8faC545936693aC917d5E7563));
        _addToken(_whitelistedTokens, USDT, address(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9));

        whitelistedTokens = _whitelistedTokens;
    }

    modifier onlyGovernor() {
        require(_msgSender() == governor(), "caller-is-not-the-governor");
        _;
    }

    ////////////////////////////// Only Governor //////////////////////////////
    /**
     * @notice Add token as whitelisted token for VUSD system
     * @dev Add token address in whitelistedTokens list and add cToken in mapping
     * @param _token address which we want to add in token list.
     * @param _cToken CToken address correspond to _token
     */
    function addWhitelistedToken(address _token, address _cToken) external onlyGovernor {
        _addToken(whitelistedTokens, _token, _cToken);
    }

    /**
     * @notice Remove token from whitelisted tokens
     * @param _token address which we want to remove from token list.
     */
    function removeWhitelistedToken(address _token) external onlyGovernor {
        require(whitelistedTokens.remove(_token), "remove-from-list-failed");
        IERC20(_token).approve(cTokens[_token], 0);
        delete cTokens[_token];
    }

    /// @notice Update minting fee
    function updateMintingFee(uint256 _newMintingFee) external onlyGovernor {
        require(_newMintingFee <= MAX_MINTING_FEE, "minting-fee-limit-reached");
        require(mintingFee != _newMintingFee, "same-minting-fee");
        emit UpdatedMintingFee(mintingFee, _newMintingFee);
        mintingFee = _newMintingFee;
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Mint VUSD
     * @param _token Address of token being deposited
     * @param _amount Amount of _token
     */
    function mint(address _token, uint256 _amount) external nonReentrant {
        require(whitelistedTokens.contains(_token), "token-is-not-supported");
        uint256 _mintage = _calculateMintage(_token, _amount);
        require(availableMintage() >= _mintage, "mint-limit-reached");
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        address _cToken = cTokens[_token];
        require(CToken(_cToken).mint(_amount) == 0, "cToken-mint-failed");
        IERC20(_cToken).safeTransfer(treasury(), IERC20(_cToken).balanceOf(address(this)));
        vusd.mint(_msgSender(), _mintage);
    }

    /**
     * @notice Calculate mintage for supported tokens.
     * @param _token Address of token which will be deposited for this mintage
     * @param _amount Amount of _token
     */
    function calculateMintage(address _token, uint256 _amount) external view returns (uint256 _mintReturn) {
        if (whitelistedTokens.contains(_token)) {
            uint256 _mintage = _calculateMintage(_token, _amount);
            return _mintage > availableMintage() ? 0 : _mintage;
        }
        // Return 0 for unsupported tokens.
        return 0;
    }

    /// @notice Check available mintage based on mint limit
    function availableMintage() public view returns (uint256 _mintage) {
        return MINT_LIMIT - vusd.totalSupply();
    }

    /// @dev Treasury is defined in VUSD token contract only
    function treasury() public view returns (address) {
        return vusd.treasury();
    }

    /// @dev Governor is defined in VUSD token contract only
    function governor() public view returns (address) {
        return vusd.governor();
    }

    /**
     * @dev Add _token into the list, add _cToken in mapping and
     * approve cToken to spend token
     */
    function _addToken(
        IAddressList _list,
        address _token,
        address _cToken
    ) internal {
        require(_list.add(_token), "add-in-list-failed");
        cTokens[_token] = _cToken;
        IERC20(_token).safeApprove(_cToken, type(uint256).max);
    }

    /**
     * @notice Calculate mintage based on mintingFee, if any.
     * Also covert _token defined decimal amount to 18 decimal amount
     * @return VUSD mintage based on given input
     */
    function _calculateMintage(address _token, uint256 _amount) internal view returns (uint256) {
        uint256 _decimals = IERC20Metadata(_token).decimals();
        uint256 _mintage = mintingFee != 0 ? _amount - ((_amount * mintingFee) / MAX_MINTING_FEE) : _amount;
        // Convert final amount to 18 decimals
        return _mintage * 10**(18 - _decimals);
    }
}
