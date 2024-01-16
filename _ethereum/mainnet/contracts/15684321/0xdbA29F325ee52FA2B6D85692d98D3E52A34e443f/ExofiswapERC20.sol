// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IExofiswapERC20.sol";

contract ExofiswapERC20 is ERC20, IExofiswapERC20
{
	// keccak256("permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 private constant _PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
	mapping(address => uint256) private _nonces;

	constructor(string memory tokenName) ERC20(tokenName, "ENERGY")
	{ } // solhint-disable-line no-empty-blocks

	// The standard ERC-20 race condition for approvals applies to permit as well.
	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) override public
	{
		// solhint-disable-next-line not-rely-on-time
		require(deadline >= block.timestamp, "Exofiswap: EXPIRED");
		bytes32 digest = keccak256(
			abi.encodePacked(
				"\x19\x01",
				DOMAIN_SEPARATOR(),
				keccak256(
					abi.encode(
						_PERMIT_TYPEHASH,
						owner,
						spender,
						value,
						_nonces[owner]++,
						deadline
					)
				)
			)
		);
		address recoveredAddress = ecrecover(digest, v, r, s);
		// Since the ecrecover precompile fails silently and just returns the zero address as signer when given malformed messages,
		// it is important to ensure owner != address(0) to avoid permit from creating an approval to spend “zombie funds”
		// belong to the zero address.
		require(recoveredAddress != address(0) && recoveredAddress == owner, "Exofiswap: INVALID_SIGNATURE");
		_approve(owner, spender, value);
	}

	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() override public view returns(bytes32)
	{
		// If the DOMAIN_SEPARATOR contains the chainId and is defined at contract deployment instead of reconstructed
		// for every signature, there is a risk of possible replay attacks between chains in the event of a future chain split
		return keccak256(
			abi.encode(
				keccak256(
					"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
				),
				keccak256(bytes(name())),
				keccak256(bytes("1")),
				block.chainid,
				address(this)
			)
		);
	}

	function nonces(address owner) override public view returns (uint256)
	{
		return _nonces[owner];
	}

	function PERMIT_TYPEHASH() override public pure returns (bytes32) //solhint-disable-line func-name-mixedcase
	{
		return _PERMIT_TYPEHASH;
	}
}
