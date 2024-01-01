// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

// solhint-disable no-inline-assembly
library ZeroCheck {
	function isZero(address _addr) public pure returns (bool isAddrZero) {
		assembly {
			isAddrZero := iszero(_addr)
		}
	}

	function isNotZero(address _addr) public pure returns (bool isAddrNotZero) {
		assembly {
			isAddrNotZero := gt(_addr, 0)
		}
	}

	function revertIfZero(address _addr, bytes4 _selector) public pure {
		assembly {
			if iszero(_addr) {
				mstore(0x00, _selector)
				revert(0x00, 0x04)
			}
		}
	}
}
