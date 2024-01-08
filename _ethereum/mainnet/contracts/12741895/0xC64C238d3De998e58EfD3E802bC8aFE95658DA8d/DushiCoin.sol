pragma solidity >=0.7.0 <0.9.0;

import "./ERC20PresetMinterPauser.sol";

contract DushiCoin is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("DushiCoin", "DUSHI") {
    }
}