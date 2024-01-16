// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
pragma solidity 0.8.12;

//import "./IERC20.sol";
//import "./SafeERC20.sol";
//import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IDFRewards.sol";

interface IveOCEAN {
    function deposit_for(address _address, uint256 _amount) external;
}

contract DFStrategyV1 is ReentrancyGuard {
    using SafeERC20 for IERC20;
    IDFRewards dfrewards;
    uint8 public id = 1;

    constructor(address _dfrewards) {
        dfrewards = IDFRewards(_dfrewards);
    }

    function claimMultiple(address _to, address[] calldata tokenAddresses)
        public
    {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            dfrewards.claimFor(_to, tokenAddresses[i]);
        }
    }

    // Recipient claims for themselves
    function claim(address[] calldata tokenAddresses) external returns (bool) {
        claimMultiple(msg.sender, tokenAddresses);
        return true;
    }

    function claimables(address _to, address[] calldata tokenAddresses)
        external
        view
        returns (uint256[] memory result)
    {
        result = new uint256[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i += 1) {
            result[i] = dfrewards.claimable(_to, tokenAddresses[i]);
        }
        return result;
    }

}
