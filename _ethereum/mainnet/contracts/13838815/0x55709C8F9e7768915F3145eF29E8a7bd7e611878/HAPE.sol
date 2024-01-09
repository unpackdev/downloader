pragma solidity >=0.7.0 <0.9.0;

import "./ERC20PresetFixedSupply.sol";

contract HAPECoin is ERC20{
    constructor() ERC20 ('HAPECoin', 'HAPE') {
        _mint(0xBf95194Ca4a633B929d1E534cFb7D94c64f5FC1a, 1000000000000000000000000000);
    }
}