pragma solidity 0.7.6;

import "./FutureWallet.sol";

/**
 * @title Rate Future Wallet abstraction
 * @author Gaspard Peduzzi
 * @notice Abstraction for the future wallets that works with an IBT whose value incorporates the fees (i.e. cTokens)
 * @dev Override future wallet abstraction with the particular functioning of rate based IBT
 */
abstract contract RateFutureWallet is FutureWallet {
    using SafeMathUpgradeable for uint256;

    uint256[] internal futureWallets;

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
        futureWallets.push(_amount);
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
        return (senderTokenBalance.mul(futureWallets[_periodIndex])).div(fyt.totalSupply());
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
        uint256 claimableYield = (_userFYT.mul(futureWallets[_periodIndex])).div(_totalFYT);
        futureWallets[_periodIndex] = futureWallets[_periodIndex].sub(claimableYield);
        return claimableYield;
    }
}
