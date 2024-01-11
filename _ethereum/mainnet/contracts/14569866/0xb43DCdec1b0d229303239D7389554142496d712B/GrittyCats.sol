// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./BBPCCreator.sol";
import "./RoyaltySplits.sol";

/**
 *
 *   ██████╗ ██████╗ ██╗████████╗████████╗██╗   ██╗
 *  ██╔════╝ ██╔══██╗██║╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝
 *  ██║  ███╗██████╔╝██║   ██║      ██║    ╚████╔╝
 *  ██║   ██║██╔══██╗██║   ██║      ██║     ╚██╔╝
 *  ╚██████╔╝██║  ██║██║   ██║      ██║      ██║
 *   ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝      ╚═╝
 *   ██████╗ █████╗ ████████╗███████╗
 *  ██╔════╝██╔══██╗╚══██╔══╝██╔════╝
 *  ██║     ███████║   ██║   ███████╗
 *  ██║     ██╔══██║   ██║   ╚════██║
 *  ╚██████╗██║  ██║   ██║   ███████║
 *   ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
 *
 *  Block Block Punch Click
 *  https://www.grittycats.com
 *
 */
contract GrittyCats is RoyaltySplits, BBPCCreator {
	constructor(
		string memory _baseURI,
		uint256 _maxPresaleMint,
		uint256 _maxPublicMint,
		uint256 _maxSupply,
		uint256 _reserveAmount
	)
		BBPCCreator(
			"GrittyCats",
			"GCAT",
			_baseURI,
			_maxPresaleMint,
			_maxPublicMint,
			_maxSupply,
			_reserveAmount,
			addresses,
			splits
		)
	{}
}
