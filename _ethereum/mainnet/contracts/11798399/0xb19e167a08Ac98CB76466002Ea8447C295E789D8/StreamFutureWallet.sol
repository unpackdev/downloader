pragma solidity 0.7.6;

import "./FutureWallet.sol";

/**
 * @title Strean Future Wallet abstraction
 * @author Gaspard Peduzzi
 * @notice Abstraction for the future wallets that works with an IBT for which its holder gets the interest directly in its wallet progressively (i.e aTokens)
 * @dev Override future wallet abstraction with the particular functioning of stream-based IBT
 */
abstract contract StreamFutureWallet is FutureWallet {
    using SafeMathUpgradeable for uint256;

    uint256 private scaledTotal;
    uint256[] private scaledFutureWallets;

    /**
     * @notice Intializer
     * @param _futureAddress the address of the corresponding future
     * @param _adminAddress the address of the admin
     */
    function initialize(address _futureAddress, address _adminAddress) public override initializer {
        super.initialize(_futureAddress, _adminAddress);
    }

    /**
     * @notice register the yield of an expired period
     * @param _amount the amount of yield to be registered
     */
    function registerExpiredFuture(uint256 _amount) public override {
        require(hasRole(FUTURE_ROLE, msg.sender), "Caller is not allowed to register an expired future");

        uint256 currentTotal = ibt.balanceOf(address(this));

        if (scaledFutureWallets.length > 1) {
            uint256 scaledInput =
                IAPWineMaths(IRegistry(IController(future.getControllerAddress()).getRegistryAddress()).getMathsUtils())
                    .getScaledInput(_amount, scaledTotal, currentTotal);
            scaledFutureWallets.push(scaledInput);
            scaledTotal = scaledTotal.add(scaledInput);
        } else {
            scaledFutureWallets.push(_amount);
            scaledTotal = scaledTotal.add(_amount);
        }
    }

    /**
     * @notice return the yield that could be redeemed by an address for a particular period
     * @param _periodIndex the index of the corresponding period
     * @param _tokenHolder the FYT holder
     * @return the yield that could be redeemed by the token holder for this period
     */
    function getRedeemableYield(uint256 _periodIndex, address _tokenHolder) public view override returns (uint256) {
        IFutureYieldToken fyt = IFutureYieldToken(future.getFYTofPeriod(_periodIndex));
        uint256 senderTokenBalance = fyt.balanceOf(_tokenHolder);
        uint256 scaledOutput = (senderTokenBalance.mul(scaledFutureWallets[_periodIndex]));
        return
            IAPWineMaths(IRegistry(IController(future.getControllerAddress()).getRegistryAddress()).getMathsUtils())
                .getActualOutput(scaledOutput, scaledTotal, ibt.balanceOf(address(this)))
                .div(fyt.totalSupply());
    }

    /**
     * @notice collect and update the yield balance of the sender
     * @param _periodIndex the index of the corresponding period
     * @param _userFYT the FYT holder balance
     * @param _totalFYT the total FYT supply
     * @return the yield claimed
     */
    function _updateYieldBalances(
        uint256 _periodIndex,
        uint256 _userFYT,
        uint256 _totalFYT
    ) internal override returns (uint256) {
        uint256 scaledOutput = (_userFYT.mul(scaledFutureWallets[_periodIndex])).div(_totalFYT);
        uint256 claimableYield =
            IAPWineMaths(IRegistry(IController(future.getControllerAddress()).getRegistryAddress()).getMathsUtils())
                .getActualOutput(scaledOutput, scaledTotal, ibt.balanceOf(address(this)));
        scaledFutureWallets[_periodIndex] = scaledFutureWallets[_periodIndex].sub(scaledOutput);
        scaledTotal = scaledTotal.sub(scaledOutput);
        return claimableYield;
    }
}
