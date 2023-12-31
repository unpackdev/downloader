// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IVoucher.sol";
import "./AdscendoPool.sol";
import "./LSTETH.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract AdscendoFactory is Ownable {
    address[] internal _pools;

    event CreatePool(address poolAddress_, uint liquidationPrice_);

    constructor(address owner_) Ownable(owner_) {}

    function pools() public view returns (address[] memory) {
        return _pools;
    }

    function createPool(
        uint liquidationPrice_,
        uint safePrice_,
        address ausdAddress_,
        address stEthAddress_,
        address priceFeedAddress_,
        address insurance_,
        address management_,
        address admin_,
        uint mintFee_,
        uint redeemFee_
    ) external onlyOwner returns (address) {
        LSTETH newLstEth = new LSTETH(
            "Leveraged Lido Staked Ether",
            string.concat(
                "LSTETH",
                Strings.toString(liquidationPrice_ / (10 ** 18))
            ),
            address(this)
        );

        AdscendoPool _p = new AdscendoPool(
            liquidationPrice_,
            safePrice_,
            ausdAddress_,
            address(newLstEth),
            stEthAddress_,
            priceFeedAddress_,
            insurance_,
            management_,
            admin_,
            mintFee_,
            redeemFee_
        );

        _pools.push(address(_p));
        IVoucher(ausdAddress_).addPool(address(_p));
        IVoucher(address(newLstEth)).addPool(address(_p));

        emit CreatePool(address(_p), liquidationPrice_);

        return address(_p);
    }
}
