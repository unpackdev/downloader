// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./HeaderRLP.sol";
import "./OilerOptionBase.sol";

contract OilerOptionBaseFee is OilerOption {
    string private constant _optionType = "F";
    string private constant _name = "OilerOptionBaseFee";

    constructor() OilerOption() {}

    function init(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateralAddress
    ) external {
        super._init(_strikePrice, _expiryTS, _put, _collateralAddress);
    }

    function exercise(bytes calldata _rlp) external returns (bool) {
        require(isActive(), "OilerOptionBaseFee.exercise: not active, cannot exercise");

        uint256 blockNumber = HeaderRLP.checkBlockHash(_rlp);
        require(
            blockNumber >= startBlock,
            "OilerOptionBaseFee.exercise: can only be exercised with a block after option creation"
        );
        uint256 baseFee = HeaderRLP.getBaseFee(_rlp);

        _exercise(baseFee);
        return true;
    }

    function optionType() external pure override returns (string memory) {
        return _optionType;
    }

    function name() public pure override returns (string memory) {
        return _name;
    }
}
