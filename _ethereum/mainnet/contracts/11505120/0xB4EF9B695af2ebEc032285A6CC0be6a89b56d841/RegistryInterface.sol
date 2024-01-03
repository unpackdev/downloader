pragma solidity ^0.7.4;

interface RegistryInterface {

    /**
     *  Returns admin address for cToken contracts
     *  @return admin address
     */
    function admin() external view returns (address payable);

    /**
     *  Returns address of actual PToken implementation contract
     *  @return Address of contract
     */
    function pTokenImplementation() external view returns (address);

    function addPToken(address underlying, address pToken) external returns(uint);
    function addPETH(address pETH_) external returns(uint);
    function addPPIE(address pPIE_) external returns(uint);
}
