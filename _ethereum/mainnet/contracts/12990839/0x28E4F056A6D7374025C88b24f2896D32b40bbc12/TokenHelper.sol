// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";

import "./IRaffleTicket.sol";

library TokenHelper {
	function ERC20Transfer(
		address token,
		address to,
		uint256 amount
	)
		public
	{
		(bool success, bytes memory data) =
				token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20: transfer amount exceeds balance');
	}

    function ERC20TransferFrom(
			address token,
			address from,
			address to,
			uint256 amount
    )
			public
		{
			(bool success, bytes memory data) =
					token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
			require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20: transfer amount exceeds balance or allowance');
    }

    function transferFrom(
        address token,
        uint256 tokenId,
        address from,
        address to
    )
            public
            returns (bool)
        {
                (bool success,) = token.call(abi.encodeWithSelector(IERC721.transferFrom.selector, from, to, tokenId));

                // in the ERC721 the transfer doesn't return a bool. So we need to check explicitly.
                return success;
    }

    function _mintTickets(
        address ticket,
        address to,
        uint256 amount
    ) public {
        (bool success,) = ticket.call(abi.encodeWithSelector(IRaffleTicket.mint.selector, to, 0, amount));

        require(success, 'ERC1155: mint failed');
    }
}