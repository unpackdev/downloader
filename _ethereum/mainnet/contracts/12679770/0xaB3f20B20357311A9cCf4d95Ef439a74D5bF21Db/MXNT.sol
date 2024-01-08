pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: MIT OR Apache-2.0

import "./MexicanCurrency.sol";
import "./SafeMathUpgradeable.sol";

contract MXNT is MexicanCurrency {
    uint8 constant DECIMALS = 6;
    using SafeMathUpgradeable for uint256;

    function initialize(uint256 _initialSupply) public initializer {
        __ERC20_init_unchained("Axolotl MXN", "MXNT");
        __Ownable_init_unchained();
        _mint(_msgSender(), _initialSupply);
        paused = false;
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    function name() public pure override returns (string memory) {
        return "Axolotl MXN";
    }

    function symbol() public pure override returns (string memory) {
        return "MXNT";
    }

    function setParams(Params memory _params) public onlyOwner {
        require(_params.basisPointsRate <= 20);
        require(_params.maximumFee < 50);

        params = _params;
        params.maximumFee = params.maximumFee.mul(10**DECIMALS);
    }
}
