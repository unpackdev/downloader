// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


contract aKeeperAirdrop is Ownable {
    using SafeMath for uint;

    IERC20 public aKEEPER;
    IERC20 public USDC;
    address public gnosisSafe;
    
    constructor(address _aKEEPER, address _USDC, address _gnosisSafe) {
        require( _aKEEPER != address(0) );
        require( _USDC != address(0) );
        aKEEPER = IERC20(_aKEEPER);
        USDC = IERC20(_USDC);
        gnosisSafe = _gnosisSafe;
    }

    receive() external payable { }

    function airdropTokens(address[] calldata _recipients, uint[] calldata _amounts) external onlyOwner() {
        for (uint i=0; i < _recipients.length; i++) {
            aKEEPER.transfer(_recipients[i], _amounts[i]);
        }
    }

    function refundUsdcTokens(address[] calldata _recipients, uint[] calldata _amounts) external onlyOwner() {
        for (uint i=0; i < _recipients.length; i++) {
            USDC.transfer(_recipients[i], _amounts[i]);
        }
    }

    function refundEth(address[] calldata _recipients, uint[] calldata _amounts) external onlyOwner() {
        for (uint i=0; i < _recipients.length; i++) {
            safeTransferETH(_recipients[i], _amounts[i]);
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

    function withdraw() external onlyOwner() {
        uint256 amount = aKEEPER.balanceOf(address(this));
        aKEEPER.transfer(msg.sender, amount);
    }

    function withdrawUsdc() external onlyOwner() {
        uint256 amount = USDC.balanceOf(address(this));
        USDC.transfer(gnosisSafe, amount);
    }

    function withdrawEth() external onlyOwner() {
        safeTransferETH(gnosisSafe, address(this).balance);
    }
}
