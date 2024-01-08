// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./SafeERC20.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Compound.sol";
import "./LibCompound.sol";
import "./JITUCompound.sol";
import "./Gelatofied.sol";

/// @dev this contract serves as a KeeperDAO's JITU wrapper
/// @dev this contract allows gelato to call `underwrite` and `reclaim` JITU functions and be paid for the costs
contract GelatoJITU is Gelatofied, Ownable {
    ERC721Enumerable hidingVaultNFT;
    JITUCompound jitu;

    constructor(
        address payable _gelato,
        ERC721Enumerable _hidingVaultNFT,
        JITUCompound _jitu
    ) Gelatofied(_gelato) {
        hidingVaultNFT = _hidingVaultNFT;
        jitu = _jitu;
    }

    /// @notice deposit eth
    receive() external payable {}

    /// @notice withdraw contract eth/token
    /// @param _token the address of token to be withdrawn
    /// @param _receiver the address to receive eth
    /// @param _amount the amount of eth to be withdrawn
    function withdraw(
        address _token,
        address payable _receiver,
        uint256 _amount
    ) external onlyOwner {
        _withdraw(_token, _receiver, _amount);
    }

    /// @notice set HidingVaultNFT address
    /// @param _hidingVaultNFT the address of HidingVaultNFT
    function setConfig(ERC721Enumerable _hidingVaultNFT, JITUCompound _jitu) external onlyOwner {
        if (_hidingVaultNFT != ERC721Enumerable(address(0))) hidingVaultNFT = _hidingVaultNFT;
        if (_jitu != JITUCompound(payable(0))) jitu = _jitu;
    }

    /// @notice set token to use as payment
    /// @param _token the address of token to be set as default token payment
    function setPaymentToken(address _token) external onlyOwner {
        _setPaymentToken(_token);
    }

    /// @notice underwrite the given wallet, with the given amount of
    ///         compound tokens
    ///
    /// @param _wallet the address of the compound wallet
    /// @param _cToken the address of the cToken
    /// @param _amount the amount of ERC20 tokens
    /// @param _gelatoFee the fee amount to be paid to gelato to cover gas cost
    /// @param _gelatopPaymentToken the address of the payment token to be used to pay gelato
    function underwrite(
        address _wallet,
        address _cToken,
        uint256 _amount,
        uint256 _gelatoFee,
        address _gelatopPaymentToken
    ) external gelatofy(_gelatoFee, _gelatopPaymentToken) {
        jitu.underwrite(_wallet, CToken(_cToken), _amount);
    }

    /// @notice reclaim the given amount of compound tokens
    ///          from the given wallet
    ///
    /// @param _wallet the address of the compound wallet
    /// @param _gelatoFee the fee amount to be paid to gelato to cover gas cost
    /// @param _gelatopPaymentToken the address of the payment token to be used to pay gelato
    function reclaim(
        address _wallet,
        uint256 _gelatoFee,
        address _gelatopPaymentToken
    ) external gelatofy(_gelatoFee, _gelatopPaymentToken) {
        jitu.reclaim(_wallet);
    }

    /// @notice get KCompound positions
    function getKCompoundPositions() external view returns (address[] memory) {
        uint256 totalAccounts = hidingVaultNFT.totalSupply();
        address[] memory accounts = new address[](totalAccounts);

        for (uint256 i = 0; i < totalAccounts; i++) {
            accounts[i] = address(uint160(hidingVaultNFT.tokenByIndex(i)));
        }

        return accounts;
    }

    /// @notice get underwrite params
    ///
    /// @param _account the address of the compound wallet
    function getUnderwriteParams(address _account)
        external
        view
        returns (address cToken, uint256 amount)
    {
        address[] memory cTokens = LibCToken.COMPTROLLER.getAssetsIn(_account);

        uint256 highestUSDValue = 0;
        for (uint256 i = 0; i < cTokens.length; i++) {
            uint256 tokenBalance = CToken(cTokens[i]).balanceOf(_account);
            uint256 tokenUSDVal =
                LibCompound.collateralValueInUSD(CToken(cTokens[i]), tokenBalance);

            if (tokenUSDVal > highestUSDValue) {
                highestUSDValue = tokenUSDVal;
                cToken = cTokens[i];
                amount = tokenBalance / 3;
            }
        }
    }
}
