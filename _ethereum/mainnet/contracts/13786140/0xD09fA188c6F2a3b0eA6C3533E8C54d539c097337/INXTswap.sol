pragma solidity ^0.8.3;

import "./ERC20.sol";


contract INXTswap {
    IERC20 public INXT;
    address public ownerOfNewTokens;
    IERC20 public INXTO;

    constructor(
        address _INXT,
        address _ownerOfNewTokens,
        address _INXTO
    ) {
        INXT = IERC20(_INXT);
        ownerOfNewTokens = _ownerOfNewTokens;
        INXTO = IERC20(_INXTO);
    }

    function swap(uint256 _amount) public {
        require(
            INXT.allowance(ownerOfNewTokens, address(this)) >= _amount,
            "INXT token allowance too low (swap is completed)."
        );
        require(
            INXTO.allowance(msg.sender, address(this)) >= _amount,
            "INTXO token allowance too low."
        );

        _safeTransferFrom(INXT, ownerOfNewTokens, msg.sender, _amount);
        
        _safeTransferFrom(INXTO, msg.sender, address(this), _amount);
        
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }
}
