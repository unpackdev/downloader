//SPDX-License-Identifier: MIT
/*
Thermally stable Vanadium (23) complexes supported by the iminophenyl
 __________________________________________________________________________ 
|   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18 |
|                                                                          |
|1  H                                                                   He |
|                                                                          |
|2  Li  Be                                          B   C   N   O   F   Ne |
|                                                                          |
|3  Na  Mg                                          Al  Si  P   S   Cl  Ar |
|                                                                          |
|4  K   Ca  Sc  Ti  [V] Cr  Mn  Fe  Co  Ni  Cu  Zn  Ga  Ge  As  Se  Br  Kr |
|                                                                          |
|5  Rb  Sr  Y   Zr  Nb  Mo  Tc  Ru  Rh  Pd  Ag  Cd  In  Sn  Sb  Te  I   Xe |
|                                                                          |
|6  Cs  Ba  *   Hf  Ta  W   Re  Os  Ir  Pt  Au  Hg  Tl  Pb  Bi  Po  At  Rn |
|                                                                          |
|7  Fr  Ra  **  Rf  Db  Sg  Bh  Hs  Mt  Ds  Rg  Cn  Nh  Fl  Mc  Lv  Ts  Og|
|__________________________________________________________________________|
|                                                                          |
|                                                                          |
| Lantanoidi*   La  Ce  Pr  Nd  Pm  Sm  Eu  Gd  Tb  Dy  Ho  Er  Tm  Yb  Lu |
|                                                                          |
|  Aktinoidi**  Ac  Th  Pa  U   Np  Pu  Am  Cm  Bk  Cf  Es  Fm  Md  No  Lr |
|__________________________________________________________________________|

*/

pragma solidity ^0.8.5;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./ERC20.sol";
import "./IUniswapV2Pair.sol";
import "./Ownable.sol";

contract VANADIUM is ERC20, Ownable {
    string constant _name = "VANADIUM";
    string constant _symbol = "VANAD";
    uint256 _totalSupply = 23000000 * (10**decimals());
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;
    mapping(address => bool) isFeeExempt;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 totalFee = 3;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public router;
    address public pair;

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (recipient != pair && recipient != DEAD) {
            require(
                isTxLimitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxWalletAmount,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 taxed = shouldTakeFee(sender) ? getFeeAmount(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    function getFeeAmount(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / 100;
        return feeAmount;
    }

    function launch() external {
        totalFee = 3;
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    constructor() ERC20(_name, _symbol) {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        isFeeExempt[owner()] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }
}
