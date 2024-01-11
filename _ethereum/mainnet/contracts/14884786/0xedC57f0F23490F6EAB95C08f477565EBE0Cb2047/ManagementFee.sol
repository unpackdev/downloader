// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./VaultStorage.sol";
import "./ManagementFeeStorage.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/// @title The platform management fee contract for Yieldster
/// @author Yieldster
/// @notice For each transaction that changes the vault's nav, this contract has the business logic to transfer a certain portion of the deposit/withdrawals to YieldsterDAO
/// @dev Delegate calls are made from the vault to this contract

contract ManagementFee is VaultStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event CallStatusInManagementFee(string message);

    /// @dev Function to process platform fee acquired by Yieldster.
    /// @param _feeAmountToTransfer Amount of fee to transfer(amount of tokens).
    /// @param _tokenAddress Address of token on which fee has to be given.
    /// @param _feeInUSD value of token is USD .
    function processPlatformFee(
        uint256 _feeAmountToTransfer,
        address _tokenAddress,
        uint256 _feeInUSD
    ) internal {
        if (
            tokenBalances.getTokenBalance(_tokenAddress) > _feeAmountToTransfer
        ) {
            transferFee(_tokenAddress, _feeAmountToTransfer);
        } else {
            if (tokenBalances.getTokenBalance(_tokenAddress) > threshold) {
                for (uint256 i = 0; i < assetList.length; i++) {
                    if (_feeInUSD != 0) {
                        address wEth = IAPContract(APContract).getWETH();
                        address tokenAddress;
                        if (assetList[i] == eth) tokenAddress = wEth;
                        else tokenAddress = assetList[i];

                        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(
                            assetList[i]
                        );

                        uint256 tokenBalanceInVault = tokenBalances
                            .getTokenBalance(assetList[i]);

                        uint256 normalizedTokenBalance = IHexUtils(
                            IAPContract(APContract).stringUtils()
                        ).toDecimals(tokenAddress, tokenBalanceInVault);

                        uint256 totalTokenPriceInUSD = tokenUSD
                            .mul(normalizedTokenBalance)
                            .div(1e18);

                        if (totalTokenPriceInUSD >= _feeInUSD) {
                            uint256 tokenCount = _feeInUSD.mul(1e18).div(
                                tokenUSD
                            );
                            uint256 tokenCountDecimals = IHexUtils(
                                IAPContract(APContract).stringUtils()
                            ).fromDecimals(tokenAddress, tokenCount);

                            transferFee(assetList[i], tokenCountDecimals);
                            _feeInUSD = 0;
                        } else {
                            transferFee(assetList[i], tokenBalanceInVault);
                            _feeInUSD = _feeInUSD.sub(totalTokenPriceInUSD);
                        }
                    } else break;
                }
            }
        }
    }

    /// @dev Function to transfer fee to yieldster DAO.
    /// @param _tokenAddress Address of token on which fee has to be given.
    /// @param _feeAmountToTransfer Amount of fee to transfer(amount of tokens).
    function transferFee(address _tokenAddress, uint256 _feeAmountToTransfer)
        internal
    {
        updateTokenBalance(_tokenAddress, _feeAmountToTransfer, false);
        if (_tokenAddress == eth) {
            address payable to = payable(
                IAPContract(APContract).yieldsterDAO()
            );
            // to.transfer replaced here
            (bool success, ) = to.call{value: _feeAmountToTransfer}("");
            if (success == false) {
                emit CallStatusInManagementFee("call failed in managementFee");
            }
        } else {
            IERC20(_tokenAddress).safeTransfer(
                IAPContract(APContract).yieldsterDAO(),
                _feeAmountToTransfer
            );
        }
    }

    /// @dev Function to calculate feeAmount.
    /// @param blockDifference No of blocks after last transaction in which management fees were paid.
    /// @param _tokenAddress Address of token.
    function feeAmount(uint256 blockDifference, address _tokenAddress)
        public
        view
        returns (uint256, uint256)
    {
        uint256 vaultNAV = getVaultNAV();
        ManagementFeeStorage mStorage = ManagementFeeStorage(
            IAPContract(APContract).getPlatformFeeStorage()
        );
        address tokenAddress = _tokenAddress;
        if (_tokenAddress == eth) {
            address wEth = IAPContract(APContract).getWETH();
            tokenAddress = wEth;
        }
        uint256 platformFee = mStorage.getPlatformFee();
        uint256 platformNavInterest = vaultNAV
            .mul(blockDifference.mul(1e18))
            .mul(platformFee)
            .div(uint256(262800000).mul(1e36));

        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 platformShareCount = platformNavInterest.mul(1e18).div(
            tokenUSD
        );

        uint256 tokenCountDecimals = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).fromDecimals(tokenAddress, platformShareCount);

        return (tokenCountDecimals, platformNavInterest);
    }

    /// @dev Function to calculate fee.
    /// @param _tokenAddress Address of token on which fee has to be calculated.
    function calculateFee(address _tokenAddress)
        public
        returns (uint256, uint256)
    {
        uint256 blockDifference;
        if (tokenBalances.getLastTransactionBlockNumber() != 0) {
            blockDifference = uint256(block.number).sub(
                tokenBalances.getLastTransactionBlockNumber()
            );
        } else {
            tokenBalances.setLastTransactionBlockNumber();
        }
        uint256 vaultNAV = getVaultNAV();
        if (vaultNAV > 0) {
            return feeAmount(blockDifference, _tokenAddress);
        } else {
            return (0, 0);
        }
    }

    /// @notice This function is called for each deposit and withdrawal
    /// @dev Delegate calls are made from the vault to this function.
    /// @param _tokenAddress the deposit/withdrawal token
    function executeSafeCleanUp(address _tokenAddress)
        public
        payable
        returns (uint256)
    {
        (uint256 amount, uint256 feeInUSD) = calculateFee(_tokenAddress);

        if (amount > 0) {
            processPlatformFee(amount, _tokenAddress, feeInUSD);
            tokenBalances.setLastTransactionBlockNumber();
        }
        return amount;
    }
}
