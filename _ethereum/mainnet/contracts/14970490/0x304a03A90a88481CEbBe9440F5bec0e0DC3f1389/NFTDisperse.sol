// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC165.sol";

contract NFTDisperse is Ownable {
    /**
     * @dev disperse token
     *
     * @notice Should approve first
     * @notice should be used for consecutive tokenIds owning
     *
     * @param recipients Aarray of addresses for disperse
     * @param tokenIds Aarray of amounts for disperse
     */
    function disperseToken(
        address _token,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external {
        require(IERC165(_token).supportsInterface(0x80ac58cd), "Non-erc721");
        require(recipients.length == tokenIds.length && recipients.length > 0, "Invalid inputs");

        for (uint256 i = 0; i < recipients.length; i++) {
            IERC721(_token).transferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }

    /**
     * @dev withdraw tokens which were sent accidently
     *
     * @param _ids Array of token ids to withdraw
     * @param receiver Receiver address to get tokens
     */
    function withdraw(
        address _token,
        uint256[] calldata _ids,
        address receiver
    ) external onlyOwner {
        require(_ids.length > 0, "invalid token amount");

        for (uint256 i = 0; i < _ids.length; i++) {
            IERC721(_token).transferFrom(address(this), receiver, _ids[i]);
        }
    }
}
