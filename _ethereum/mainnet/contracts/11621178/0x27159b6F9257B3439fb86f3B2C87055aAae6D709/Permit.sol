pragma solidity ^0.7.3;

import "./IToken.sol";
import "./IEIP712_DAI.sol";

library Permit {

	function permit(
		address currency,
		uint256 amount,
		address sender,
		address spender,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal {
		if (IToken(currency).allowance(sender, spender) < amount) {
		    if (keccak256(bytes(IToken(currency).symbol())) == 0xa5e92f3efb6826155f1f728e162af9d7cda33a574a1153b58f03ea01cc37e568) {
		        // DAI has a custom permit method
		        uint256 nonce = IToken(currency).nonces(sender);
		        IEIP712_DAI(currency).permit(sender, spender, nonce, deadline, true, v, r, s);
		    }/* else {
		        IToken(currency).permit(sender, spender, uint256(-1), deadline, v, r, s);
		    }*/
		}
	}

}