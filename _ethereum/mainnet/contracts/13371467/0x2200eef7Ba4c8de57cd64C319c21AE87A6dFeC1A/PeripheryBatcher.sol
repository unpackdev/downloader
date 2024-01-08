// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./IFactory.sol";
import "./IPeriphery.sol";
import "./IPeripheryBatcher.sol";
import "./IVault.sol";

import "./console.sol";

contract PeripheryBatcher is Ownable, IPeripheryBatcher {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IFactory public factory;
    IPeriphery public periphery;


    mapping(address => address) public tokenAddress;

    mapping(address => mapping(address => uint)) userLedger;
    // vault addr -> user addr -> amount to be deposited

    event Deposit (address indexed sender, address indexed vault, uint amountIn);
    event Withdraw (address indexed sender, address indexed vault, uint amountOut);


    constructor(IFactory _factory, IPeriphery _periphery) {
        factory = _factory;
        periphery = _periphery;
    } 

    /// @inheritdoc IPeripheryBatcher
    function depositFunds(uint amountIn, address vaultAddress) external override {
        require(tokenAddress[vaultAddress] != address(0), 'Invalid vault address');

        require(IERC20(tokenAddress[vaultAddress]).allowance(msg.sender, address(this)) >= amountIn, 'No allowance');

        IERC20(tokenAddress[vaultAddress]).safeTransferFrom(msg.sender, address(this), amountIn);

        userLedger[vaultAddress][msg.sender] = userLedger[vaultAddress][msg.sender].add(amountIn);

        emit Deposit(msg.sender, vaultAddress, amountIn);
    }


    function withdrawFunds(uint amountOut, address vaultAddress) external override {
        require(tokenAddress[vaultAddress] != address(0), 'Invalid vault address');

        require(userLedger[vaultAddress][msg.sender] >= amountOut, 'No funds available');

        userLedger[vaultAddress][msg.sender] = userLedger[vaultAddress][msg.sender].sub(amountOut);

        IERC20(tokenAddress[vaultAddress]).safeTransfer(msg.sender, amountOut);

        emit Withdraw(msg.sender, vaultAddress, amountOut);

    }

    /// @inheritdoc IPeripheryBatcher
    function batchDepositPeriphery(address vaultAddress, address[] memory users, uint slippage) external override onlyOwner {

        IERC20 vault = IERC20(vaultAddress);

        IERC20 token = IERC20(tokenAddress[vaultAddress]);

        uint amountToDeposit = 0;

        for (uint i=0; i< users.length; i++) {
            amountToDeposit = amountToDeposit.add(userLedger[vaultAddress][users[i]]);
        }

        require(amountToDeposit > 0, 'no deposits to make');

        uint oldLPBalance = vault.balanceOf(address(this));
        
        periphery.vaultDeposit(amountToDeposit, address(token), slippage, factory.vaultManager(vaultAddress));

        uint lpTokensReceived = vault.balanceOf(address(this)).sub(oldLPBalance);

        for (uint i=0; i< users.length; i++) {
            uint userAmount = userLedger[vaultAddress][users[i]];
            if (userAmount > 0) {
                uint userShare = userAmount.mul(lpTokensReceived).div(amountToDeposit);
                userLedger[vaultAddress][users[i]] = 0;
                vault.transfer(users[i], userShare);
            }
        }

    }

    /// @inheritdoc IPeripheryBatcher
    function setVaultTokenAddress(address vaultAddress, address token) external override onlyOwner {
        (, , IERC20Metadata token0, IERC20Metadata token1) = _getVault(vaultAddress);
        require(address(token0) == token || address(token1) == token, 'wrong token address');
        tokenAddress[vaultAddress] = token;

        IERC20(token).approve(address(periphery), type(uint256).max);
    }

    /**
      * @notice Get the balance of a token in contract
      * @param token token whose balance needs to be returned
      * @return balance of a token in contract
     */
    function _tokenBalance(IERC20Metadata token) internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
      * @notice Get the vault details from strategy address
      * @param vaultAddress strategy to get manager vault from
      * @return vault, poolFee, token0, token1
     */
    function _getVault(address vaultAddress) internal view 
        returns (IVault, IUniswapV3Pool, IERC20Metadata, IERC20Metadata) 
    {
        
        require(vaultAddress != address(0x0), "Not a valid vault");

        IVault vault = IVault(vaultAddress);
        IUniswapV3Pool pool  = vault.pool();

        IERC20Metadata token0 = vault.token0();
        IERC20Metadata token1 = vault.token1();

        return (vault, pool, token0, token1);
    }

}
