pragma solidity 0.6.12;

/**
 * mine SUSHI via SUSHIswap.MasterChef
 * will transferOnwership to stakeGatling
 */
contract StrategySushiStorage {

    //Sushi MasterChef
    address public constant stakeRewards = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;
    // UniLP ([usdt-eth].part)
    address public  stakeLpPair;
    //earnToken
    address public constant earnTokenAddr = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public stakeGatling;
    address public admin;
    uint256 public pid;

    event AdminChanged(address previousAdmin, address newAdmin); 

}