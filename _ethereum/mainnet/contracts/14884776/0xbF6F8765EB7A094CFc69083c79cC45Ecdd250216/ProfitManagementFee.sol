// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./VaultStorage.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

/// @title The profit management fee contract for Yieldster
/// @author Yieldster
/// @notice For each transaction that changes the vault's nav, this contract has the business logic to transfer a certain portion of the deposit/withdrawals to the strategy's beneficiary
/// @dev Delegate calls are made from the vault to this contract

contract ProfitManagementFee is VaultStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event CallStatusInProfitFee(string message);

    /// @notice This function is called for each deposit and withdrawal
    /// @dev Delegate calls are made from the vault to this function.
    /// @param _tokenAddress the deposit/withdrawal token

    function executeSafeCleanUp(address _tokenAddress)
        public
        payable
        returns (uint256)
    {
        uint256 currentVaultNAV = getVaultNAV();
        address wEth = IAPContract(APContract).getWETH();
        (uint256 feeAmountToTransfer, uint256 feeInUSD) = calculateFee(
            _tokenAddress
        );

        if (feeAmountToTransfer > 0) {
            if (
                tokenBalances.getTokenBalance(_tokenAddress) >
                feeAmountToTransfer
            ) {
                transferFee(_tokenAddress, feeAmountToTransfer);
            } else {
                if (tokenBalances.getTokenBalance(_tokenAddress) > threshold) {
                    for (uint256 i = 0; i < assetList.length; i++) {
                        if (feeInUSD != 0) {
                            address tokenAddress;
                            if (assetList[i] == eth) tokenAddress = wEth;
                            else tokenAddress = assetList[i];

                            uint256 tokenUSD = IAPContract(APContract)
                                .getUSDPrice(assetList[i]);

                            uint256 tokenBalanceInVault = tokenBalances
                                .getTokenBalance(assetList[i]);

                            uint256 normalizedTokenBalance = IHexUtils(
                                IAPContract(APContract).stringUtils()
                            ).toDecimals(tokenAddress, tokenBalanceInVault);

                            uint256 totalTokenPriceInUSD = tokenUSD
                                .mul(normalizedTokenBalance)
                                .div(1e18);

                            if (totalTokenPriceInUSD >= feeInUSD) {
                                uint256 tokenCount = feeInUSD.mul(1e18).div(
                                    tokenUSD
                                );
                                uint256 tokenCountDecimals = IHexUtils(
                                    IAPContract(APContract).stringUtils()
                                ).fromDecimals(tokenAddress, tokenCount);

                                transferFee(assetList[i], tokenCountDecimals);
                                feeInUSD = 0;
                            } else {
                                transferFee(assetList[i], tokenBalanceInVault);
                                feeInUSD = feeInUSD.sub(totalTokenPriceInUSD);
                            }
                        } else break;
                    }
                }
            }
        }
        tokenBalances.setLastTransactionNAV(currentVaultNAV);
        return feeAmountToTransfer;
    }

    /// @dev Function to transfer fee to strategyBeneficiary.
    /// @param _tokenAddress Address of token on which fee has to be given.
    /// @param _feeAmountToTransfer Amount of fee to transfer(amount of tokens).
    function transferFee(address _tokenAddress, uint256 _feeAmountToTransfer)
        internal
    {
        updateTokenBalance(_tokenAddress, _feeAmountToTransfer, false);
        if (_tokenAddress == eth) {
            address payable to = payable(strategyBeneficiary);
            // to.transfer replaced here
            (bool success, ) = to.call{value: _feeAmountToTransfer}("");
            if (success == false) {
                emit CallStatusInProfitFee("call failed in profitManagementee");
            }
        } else {
            IERC20(_tokenAddress).safeTransfer(
                strategyBeneficiary,
                _feeAmountToTransfer
            );
        }
    }

    /// @dev Function to calculate fee.
    /// @param _tokenAddress Address of token on which fee has to be calculated.
    function calculateFee(address _tokenAddress)
        public
        view
        returns (uint256, uint256)
    {
        address wEth = IAPContract(APContract).getWETH();
        address tokenAddress = _tokenAddress;
        if (_tokenAddress == eth) tokenAddress = wEth;
        uint256 currentVaultNAV = getVaultNAV();
        if (currentVaultNAV > tokenBalances.getLastTransactionNav()) {
            uint256 profit = currentVaultNAV -
                tokenBalances.getLastTransactionNav();

            uint256 percentage = strategyPercentage;
            uint256 fee = (profit.mul(percentage)).div(1e20);
            uint256 tokenUSD = IAPContract(APContract).getUSDPrice(
                _tokenAddress
            );
            uint256 tokenCount = fee.mul(1e18).div(tokenUSD);
            //return tokenCount
            uint256 tokenCountDecimals = IHexUtils(
                IAPContract(APContract).stringUtils()
            ).fromDecimals(tokenAddress, tokenCount);

            return (tokenCountDecimals, fee);
        } else {
            return (0, 0);
        }
    }
}
