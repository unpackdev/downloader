// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

import "./ZapDepositor.sol";
import "./ILidoSTETH.sol";
import "./IWETH9.sol";
contract LidoDepositor is ZapDepositor {
    using SafeERC20Upgradeable for IERC20;

    ILidoSTETH public constant ST_ETH =
        ILidoSTETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84); // mainnet address

    IWETH9 public constant weth9 =
        IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // mainnet address
    
    fallback() external payable {}

    /**
     * @notice Deposit a defined underling in the depositor protocol
     * @param _token the token to deposit
     * @param _underlyingAmount the amount to deposit
     * @return the amount ibt generated and sent back to the caller
     */

    function depositInProtocol(address _token, uint256 _underlyingAmount)
        public
        override
        onlyZaps
        tokenIsValid(_token)
        returns (uint256)
    {
        require(_token == address(0x00), "Lido: Token address not valid");

        IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            _underlyingAmount
        );

        uint256 wethBalance = IERC20(_token).balanceOf(address(this));
        // swap weth to eth
        weth9.withdraw(wethBalance);

        ST_ETH.submit{ value: address(this).balance }(
            address(0x00)
        ); // deposit ETH and get STETH to depositor with referral address to 0x00.
        uint256 IBTAMOUNT = ST_ETH.balanceOf(address(this));
        return IBTAMOUNT;
    }

    /**
     * @notice Deposit a defined underling in the depositor protocol from the caller adderss
     * @param _token the token to deposit
     * @param _underlyingAmount the amount to deposit
     * @param _from the address from which the underlying need to be pulled
     * @return the amount ibt generated
     */
    function depositInProtocolFrom(
        address _token,
        uint256 _underlyingAmount,
        address _from
    ) public override onlyZaps tokenIsValid(_token) returns (uint256) {
        IERC20(_token).transferFrom(_from, address(this), _underlyingAmount); // pull weth from user to depositor
        uint256 wethBalance = IERC20(_token).balanceOf(address(this));

        weth9.withdraw(wethBalance);

        uint256 IBTAMOUNT = ST_ETH.getSharesByPooledEth(address(this).balance);        
        ST_ETH.submit{ value: address(this).balance }(
            address(0x00)
        ); // deposit ETH and get STETH to depositor with referral address to 0x00.
        
        ST_ETH.transfer(msg.sender, IBTAMOUNT);
        
        return IBTAMOUNT;
    }
}
