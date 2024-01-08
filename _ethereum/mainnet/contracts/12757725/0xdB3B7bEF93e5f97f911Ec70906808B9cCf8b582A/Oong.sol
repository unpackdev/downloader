// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract Oong is ERC1155, Ownable {
    uint256 public constant VOTE = 0;
    address public constant HANDRESS = 0xe189a4C9F6468dFb7bBcFf246fa358CdEEAe2071;
    constructor() ERC1155("https://3kc6lfhj55s43elgks6urb36jmedzw6b3qnwmp6pxs3ckkmiehza.arweave.net/2oXllOnvZc2RZlS9SId-Swg828HcG2Y_z7y2JSmIIfI") {
        _mint(HANDRESS, VOTE, 19, "");
    }
}
