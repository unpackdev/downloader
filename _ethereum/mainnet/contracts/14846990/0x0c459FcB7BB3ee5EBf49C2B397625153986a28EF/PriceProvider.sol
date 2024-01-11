// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract PriceProvider {

    function changeActive(address token, bool active) public virtual {}

    /****************** view functions ****************** */

    function isActive(address token) public virtual view returns(bool) {}

    function isListed(address token) public virtual view returns(bool) {}

    function getPrice(address token) public virtual view returns(uint256 priceMantissa, uint8 priceDecimals) {}

    function getPriceSigned(address token, uint256 priceMantissa, uint256 validTo, bytes memory signature) public virtual view returns(uint256 _priceMantissa, uint8 _priceDecimals) {}

    function getEvaluation(address token, uint256 tokenAmount) public virtual view returns(uint256 evaluation) {}
    
    /**
     * @dev return the evaluation in $ of `tokenAmount` with signed price
     * @param token the address of token to get evaluation in $
     * @param tokenAmount the amount of token to get evaluation. Amount is scaled by 10 in power token decimals
     * @param priceMantissa the price multiplied by priceDecimals. The dimension of priceMantissa should be $/token
     * @param validTo the timestamp in seconds, when price is gonna be not valid.
     * @param signature the ECDSA sign on eliptic curve secp256k1.        
     */
    function getEvaluationSigned(address token, uint256 tokenAmount, uint256 priceMantissa, uint256 validTo, bytes memory signature) public virtual view returns(uint256 evaluation) {}

    function getPriceDecimals() public virtual view returns (uint8 priceDecimals) {}

}