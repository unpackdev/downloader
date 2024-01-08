// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./CToken.sol";
import "./CompoundVars.sol";
import "./JITU.sol";
import "./Gelatofied.sol";

interface IKComptrollerG {
    function valueInUSD(CToken _cToken, uint256 _amount)
        external
        view
        returns (uint256);
}

/// @dev this contract serves as a KeeperDAO's JITU wrapper
/// @dev this contract allows gelato to call `underwrite` and `reclaim` JITU functions and be paid for the costs
contract GelatoJITU is Gelatofied, Ownable {
    JITU jitu;
    ERC721 kCompound;
    CompoundVars vars;

    constructor(
        JITU _jitu,
        address payable _gelato,
        ERC721 _kCompound,
        CompoundVars _vars
    ) Gelatofied(_gelato) {
        jitu = _jitu;
        kCompound = _kCompound;
        vars = _vars;
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

    /// @notice set jitu address
    /// @param _jitu the address of JITU
    /// @param _kCompound the address of kCompount
    /// @param _vars the address of CompoundVars
    function setConfig(
        JITU _jitu,
        ERC721 _kCompound,
        CompoundVars _vars
    ) external onlyOwner {
        if (_jitu != JITU(0)) jitu = _jitu;
        if (_kCompound != ERC721(0)) kCompound = _kCompound;
        if (_vars != CompoundVars(0)) vars = _vars;
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
    /// @param _token the address of the ERC20 token
    /// @param _amount the amount of ERC20 tokens
    /// @param _gelatoFee the fee amount to be paid to gelato to cover gas cost
    /// @param _gelatopPaymentToken the address of the payment token to be used to pay gelato
    function underwrite(
        address _wallet,
        address _token,
        uint256 _amount,
        uint256 _gelatoFee,
        address _gelatopPaymentToken
    ) external gelatofy(_gelatoFee, _gelatopPaymentToken) {
        jitu.underwrite(_wallet, _token, _amount);
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
        uint256 totalAccounts = kCompound.totalSupply();
        address[] memory accounts = new address[](totalAccounts);

        for (uint256 i = 0; i < totalAccounts; i++) {
            accounts[i] = address(kCompound.tokenByIndex(i));
        }

        return accounts;
    }

    /// @notice get underwrite params
    ///
    /// @param _account the address of the compound wallet
    function getUnderwriteParams(address _account)
        external
        returns (address token, uint256 amount)
    {
        CToken[] memory cTokens = vars.comptroller().getAssetsIn(_account);

        uint256 highestUSDValue = 0;
        for (uint256 i = 0; i < cTokens.length; i++) {
            uint256 tokenBalance = cTokens[i].balanceOfUnderlying(_account);
            uint256 tokenUSDVal =
                IKComptrollerG(address(vars.kComptroller())).valueInUSD(
                    cTokens[i],
                    tokenBalance
                );

            if (tokenUSDVal > highestUSDValue) {
                highestUSDValue = tokenUSDVal;
                token = _underlyingToken(cTokens[i]);
                amount = tokenBalance / 3;
            }
        }
    }

    function _underlyingToken(CToken cToken) private view returns (address) {
        if (cToken == vars.cEther()) {
            return vars.weth();
        } else {
            return CErc20(address(cToken)).underlying();
        }
    }
}
