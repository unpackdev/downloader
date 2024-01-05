// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Governable.sol";
import "./CollectableDust.sol";
import "./IWHAsset.sol";
import "./IChainLinkFeed.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";


contract WhiteKeep3rV2 is Governable, CollectableDust {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IChainLinkFeed public constant ETHUSD = IChainLinkFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IChainLinkFeed public constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    
    uint public gasUsed = 240_000;

    IERC20 public immutable token; 

    constructor(IERC20 _token) public Governable(msg.sender) CollectableDust() {
        token = _token;
    }

    function setGasUsed(uint256 _gasUsed) external onlyGovernor {
        gasUsed = _gasUsed;
    }

    function unwrapAll(address whAsset, uint[] calldata tokenIds) external {
        IWHAssetv2(whAsset).autoUnwrapAll(tokenIds, msg.sender);
    }

    function getRequestedPayment() public view returns(uint){
        uint256 gasPrice = Math.min(tx.gasprice, uint256(FASTGAS.latestAnswer()));

        return gasPrice.mul(gasUsed).mul(uint(ETHUSD.latestAnswer())).div(1e20);
    }

    function getRequestedPaymentETH() public view returns(uint){
        uint256 gasPrice = Math.min(tx.gasprice, uint256(FASTGAS.latestAnswer()));

        return gasPrice.mul(gasUsed);
    }

    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }

}
