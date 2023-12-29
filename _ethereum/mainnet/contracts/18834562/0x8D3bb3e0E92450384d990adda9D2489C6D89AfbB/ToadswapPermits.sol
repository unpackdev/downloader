// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.20;
import "./IPermitDai.sol";
import "./IERC20Permit.sol";
library ToadswapPermits {
    bytes32 public constant DAI_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    error NotDaiPermit();
    error NotPermittable();
    function permitDai(address PERMIT2, address holder, address tok, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) internal {
        IPermitDai dpermit = IPermitDai(tok);
        // The Dai-style permit's typehash is always the same
        if(dpermit.PERMIT_TYPEHASH() != DAI_TYPEHASH) {
            revert NotDaiPermit();
        }
        dpermit.permit(holder, PERMIT2, nonce, deadline, true, v, r, s);
    }

    function permit(address PERMIT2, address holder, address tok, uint256 deadline, uint8 v, bytes32 r, bytes32 s) internal {
        // There isn't actually a really easy way to check if an IERC20Permit actually meets the standard
        // So best we can do is try and ensure success on the selector nonces(address) - this will match Permit and Dai Permit
        (bool success, ) = tok.call(abi.encodeWithSelector(0x7ecebe00, holder));
        if(!success) {
            revert NotPermittable();
        }
        IERC20Permit ptok = IERC20Permit(tok);
        ptok.permit(holder, PERMIT2, type(uint256).max, deadline, v, r, s);
    }
}