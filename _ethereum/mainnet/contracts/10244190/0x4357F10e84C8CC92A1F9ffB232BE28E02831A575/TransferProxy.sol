pragma solidity 0.6.8;

import "./TransferHelper.sol";
import "./ZoraAuthorized.sol";

contract TransferProxy {

    ZoraAuthorized public zoraAuthorized;

    constructor(address _authorizedAddress) public {
        zoraAuthorized = ZoraAuthorized(_authorizedAddress);
    }

    /**
     * @dev Transfer tokens owned by the transfer proxy
     *      Can only be called by an authorized zora address
     *
     * @param token     Address to of the token to transfer
     * @param from      Address to transfer tokens from
     * @param to        Address to transfer tokens to
     * @param value     Amount of tokens to spend
     */
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 value
    )
        public
    {

        require(
            zoraAuthorized.isAuthorized(msg.sender) == true,
            "TransferProxy: msg.sender is not authorized"
        );

        TransferHelper.safeTransferFrom(
            token,
            from,
            to,
            value
        );

    }

}