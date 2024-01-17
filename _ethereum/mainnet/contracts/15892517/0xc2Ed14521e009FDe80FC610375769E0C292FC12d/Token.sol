/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12;

import "./ERC20.sol";

import "./Facts.sol";
import "./FactSigs.sol";
import "./Storage.sol";
import "./IReliquary.sol";

contract Token is ERC20 {
    mapping(address => bool) public claimed;

    IReliquary immutable reliquary;
    address immutable USDT;
    uint immutable blockNum;

    constructor(
        address _reliquary,
        address _USDT,
        uint _blockNum
    ) ERC20("AirDropExampleUSDT", "ADUSDT") {
        reliquary = IReliquary(_reliquary);
        USDT = _USDT;
        blockNum = _blockNum;
    }

    /// @inheritdoc ERC20
    function decimals() public view virtual override returns (uint8) {
        // match the same value used in USDT
        return 6;
    }

    function slotForUSDTBalance(address who) public pure returns (bytes32) {
        return
            Storage.mapElemSlot(
                bytes32(uint(2)),
                bytes32(uint256(uint160(who)))
            );
    }

    function mint(address who) external {
        require(claimed[who] == false, "already claimed");

        (bool exists, , bytes memory data) = reliquary.verifyFactNoFee(
            USDT,
            FactSigs.storageSlotFactSig(slotForUSDTBalance(who), blockNum)
        );
        require(exists, "storage proof missing");
        claimed[who] = true;

        uint priorUSDTBalance = Storage.parseUint256(data);
        _mint(who, priorUSDTBalance);
    }
}
