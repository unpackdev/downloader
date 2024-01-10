pragma solidity ^0.7.0;

import "./interfaces.sol";
import "./interface.sol";

abstract contract Helpers {
	ILido internal constant lidoInterface =
		ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

	address treasury = 0x28849D2b63fA8D361e5fc15cB8aBB13019884d09; // Instadapp's treasury address
}
//0xC7B5aF82B05Eb3b64F12241B04B2cF14469E39F7
