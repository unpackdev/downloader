pragma solidity 0.4.24;

import "./InterestConnector.sol";
import "./ISavingsDai.sol";

/**
 * @title SavingsDaiConnector
 * @dev This contract allows to partially deposit locked Dai tokens into the Maker DSR using the sDAI ERC4626 vault. 
 * @dev This must never be deployed standalone and only as an interface to interact with the SavingsDAI from the InterestConnector
 */
contract SavingsDaiConnector is InterestConnector {

    /**
     * @dev Tells the address of the DAI token in the Ethereum Mainnet.
     */
    function daiToken() public pure returns (ERC20) {
        return ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    }

    /**
     * @dev Tells the address of the sDAI token in the Ethereum Mainnet.
     */
    function sDaiToken() public pure returns (ISavingsDai) {
        return ISavingsDai(0x83F20F44975D03b1b09e64809B757c47f942BEeA);
    }

    /**
     * @dev Tells the current earned interest amount.
     * @param _token address of the underlying token contract.
     * @return total amount of interest that can be withdrawn now.
     */
    function interestAmount(address _token) public view returns (uint256) {
        require(_token == address(daiToken()), "Not DAI");
        uint256 underlyingBalance = sDaiToken().maxWithdraw(address(this));
        // 1 DAI is reserved for possible truncation/round errors
        uint256 invested = investedAmount(_token) + 1 ether;
        return underlyingBalance > invested ? underlyingBalance - invested : 0;
    }

    /**
     * @dev Tells if interest earning is supported for the specific token contract.
     * @param _token address of the token contract.
     * @return true, if interest earning is supported.
     */
    function _isInterestSupported(address _token) internal pure returns (bool) {
        return _token == address(daiToken());
    }

    /**
     * @dev Invests the given amount of DAI to the sDAI Vault.
     * Deposits _amount of _token into the sDAI vault.
     * @param _token address of the token contract.
     * @param _amount amount of tokens to invest.
     */
    function _invest(address _token, uint256 _amount) internal {
        (_token);
        daiToken().approve(address(sDaiToken()), _amount);
        require(sDaiToken().deposit(_amount, address(this)) > 0, "Failed to deposit");
    }

    /**
     * @dev Withdraws at least the given amount of DAI from the sDAI vault contract.
     * Withdraws the _amount of _token from the sDAI vault.
     * @param _token address of the token contract.
     * @param _amount minimal amount of tokens to withdraw.
     */
    function _withdrawTokens(address _token, uint256 _amount) internal {
        (_token);
        require(sDaiToken().withdraw(_amount, address(this), address(this)) > 0, "Failed to withdraw");
    }

    /**
     * @dev Previews a withdraw of the given amount of DAI from the sDAI vault contract.
     * Previews withdrawing the _amount of _token from the sDAI vault.
     * @param _token address of the token contract.
     * @param _amount minimal amount of tokens to withdraw.
     */
    function previewWithdraw(address _token, uint256 _amount) public view returns(uint256){
        (_token);
        return sDaiToken().previewWithdraw(_amount);
    }

}
