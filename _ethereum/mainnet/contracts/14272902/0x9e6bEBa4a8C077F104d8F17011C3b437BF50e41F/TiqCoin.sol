pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./safeMath.sol";


contract TiqCoin is ERC20{

    using SafeMath for uint256;

    //コンストラクタ
    constructor() ERC20("TiqCoin","TIQ") {
        uint256 initialSupply = 1000000; //小数点以下を無視して100万枚発行
        _mint(msg.sender, initialSupply.mul(uint256(10).pow(uint256(decimals())))); //小数点以下は18ケタ
    }

}
