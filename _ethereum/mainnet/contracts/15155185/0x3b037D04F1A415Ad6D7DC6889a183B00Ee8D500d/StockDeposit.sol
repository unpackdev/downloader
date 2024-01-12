// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./VaultStorage.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract StockDeposit is VaultStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Function to Deposit assets into the Vault.
    /// @param _tokenAddress Address of the deposit token.
    /// @param _amount Amount of deposit token.
    function deposit(address _tokenAddress, uint256 _amount) public payable nonReentrant {
        uint256 _share;
        address tokenAddress;
        IERC20 token;
        address wEth = IAPContract(APContract).getWETH();
        addToAssetList(_tokenAddress);
        if (_tokenAddress == eth) tokenAddress = wEth;
        else {
            tokenAddress = _tokenAddress;
            token = IERC20(_tokenAddress);
        }

        if (totalSupply() == 0) {
            _share = IHexUtils(IAPContract(APContract).stringUtils())
                .toDecimals(tokenAddress, _amount);
        } else {
            _share = getMintValue(getDepositNAV(_tokenAddress, _amount));
        }

        tokenBalances.setTokenBalance(
            _tokenAddress,
            tokenBalances.getTokenBalance(_tokenAddress).add(_amount)
        );
        _mint(msg.sender, _share);
        if (_tokenAddress != eth)
            token.safeTransferFrom(msg.sender, address(this), _amount);
    }
}
