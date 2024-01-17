// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./Distributor.sol";

contract BasicDistributor is Distributor, ReentrancyGuard {
	// The practical limit for this distributor is gas: distributing to 250 addresses costs about 7,000,000 gas!
    constructor(
        IERC20 _token, // the purchased token
        uint256 _total, // total claimable
        address[] memory _recipients,
        uint256[] memory _amounts,
        uint256 voteWeightBips, // the factor for voting power (e.g. 15000 means users have a 50% voting bonus for unclaimed tokens)
        string memory _uri // information on the sale (e.g. merkle proofs)
    ) Distributor(_token, _total, voteWeightBips, _uri) {
		require(_recipients.length == _amounts.length, "_recipients, _amounts different lengths");
		uint256 _t;
        for (uint256 i = _recipients.length; i != 0; ) {
            unchecked {
                --i;
            }

			_initializeDistributionRecord(_recipients[i], _amounts[i]);
			_t += _amounts[i];
        }
		require(_total == _t, "sum(_amounts) != _total");
    }

	function _getVestedBips(address /*beneficiary*/, uint /*time*/) public pure override returns (uint256) {
		return 10000;
	}

    function NAME() external pure virtual override returns (string memory) {
        return "BasicDistributor";
    }

    function VERSION() external pure virtual override returns (uint256) {
        return 2;
    }

    function claim(address beneficiary) external nonReentrant {
        uint256 amount = getClaimableAmount(beneficiary);
        super._executeClaim(beneficiary, amount);
    }
}
