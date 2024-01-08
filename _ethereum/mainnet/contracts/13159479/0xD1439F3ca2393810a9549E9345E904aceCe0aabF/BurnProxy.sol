// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./Ownable.sol";
import "./IBasisAsset.sol";
import "./IBurnProxy.sol";

contract BurnProxy is Context, IBurnProxy {
    address public bond;
    address public redeemPool;

    constructor(address _bond, address _redeemPool) {
        bond = _bond;
        redeemPool = _redeemPool;
    }

    modifier onlyRedeemPool() {
        require(_msgSender() == redeemPool, 'only redeemPool');

        _;
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyRedeemPool
    {
        IBasisAsset(bond).burnFrom(account, amount);
    }
}
