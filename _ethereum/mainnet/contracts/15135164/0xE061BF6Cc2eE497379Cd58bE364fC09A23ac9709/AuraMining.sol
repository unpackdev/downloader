pragma solidity ^0.8.9;

import "./AuraMath.sol";


interface IAura {
    function totalSupply() external view returns(uint256);
    function EMISSIONS_MAX_SUPPLY() external view returns(uint256);
    function INIT_MINT_AMOUNT() external view returns(uint256);
    function totalCliffs() external view returns(uint256);
    function reductionPerCliff() external view returns(uint256);
    function minterMinted() external view returns(uint256);
}



contract AuraMining {

    using AuraMath for uint256;

    IAura public constant aura = IAura(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);

    function ConvertBalToAura(uint256 _amount, uint256 minterMinted) external view returns(uint256) {

        uint256 totalSupply = aura.totalSupply();
        uint256 EMISSIONS_MAX_SUPPLY = aura.EMISSIONS_MAX_SUPPLY();
        uint256 INIT_MINT_AMOUNT = aura.INIT_MINT_AMOUNT();
        uint256 totalCliffs = aura.totalCliffs();
        uint256 reductionPerCliff = aura.reductionPerCliff();

        // e.g. emissionsMinted = 6e25 - 5e25 - 0 = 1e25;
        uint256 emissionsMinted = totalSupply - INIT_MINT_AMOUNT - minterMinted;
        // e.g. reductionPerCliff = 5e25 / 500 = 1e23
        // e.g. cliff = 1e25 / 1e23 = 100
        uint256 cliff = emissionsMinted.div(reductionPerCliff);

        // e.g. 100 < 500
        if (cliff < totalCliffs) {
            // e.g. (new) reduction = (500 - 100) * 2.5 + 700 = 1700;
            // e.g. (new) reduction = (500 - 250) * 2.5 + 700 = 1325;
            // e.g. (new) reduction = (500 - 400) * 2.5 + 700 = 950;
            uint256 reduction = totalCliffs.sub(cliff).mul(5).div(2).add(700);
            // e.g. (new) amount = 1e19 * 1700 / 500 =  34e18;
            // e.g. (new) amount = 1e19 * 1325 / 500 =  26.5e18;
            // e.g. (new) amount = 1e19 * 950 / 500  =  19e17;
            uint256 amount = _amount.mul(reduction).div(totalCliffs);
            // e.g. amtTillMax = 5e25 - 1e25 = 4e25
            uint256 amtTillMax = EMISSIONS_MAX_SUPPLY.sub(emissionsMinted);
            if (amount > amtTillMax) {
                amount = amtTillMax;
            }
            //mint
            return amount;
        }
        return 0;
    }

}
