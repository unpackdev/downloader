// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC165.sol";

contract EGAirdrop is Ownable {
    IERC721 public immutable endGame;

    constructor(address _endGame) {
        require(_endGame != address(0), "invalid EndGame address");
        require(IERC165(_endGame).supportsInterface(0x80ac58cd), "Non-erc721");

        endGame = IERC721(_endGame);
    }

    /**
     * @dev disperse token
     *
     * @notice Should approve first
     * @notice should be used for consecutive tokenIds owning
     *
     * @param recipients Aarray of addresses for disperse
     * @param amounts Aarray of amounts for disperse
     * @param startId ERC721 token start ID for disperse
     */
    function disperseToken(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 startId
    ) external onlyOwner {
        require(recipients.length == amounts.length && amounts.length > 0, "Invalid inputs");
        require(startId > 0, "invalid start tokenIds");

        uint256 index = startId;
        for (uint256 i = 0; i < recipients.length; i++) {
            for (uint256 j = 0; j < amounts[i]; j++) {
                endGame.transferFrom(msg.sender, recipients[i], index);
                index++;
            }
        }
    }

    /**
     * @dev withdraw tokens which were sent accidently
     *
     * @param _ids Array of token ids to withdraw
     * @param receiver Receiver address to get tokens
     */
    function withdraw(uint256[] calldata _ids, address receiver) external onlyOwner {
        require(_ids.length > 0, "invalid token amount");

        for (uint256 i = 0; i < _ids.length; i++) {
            endGame.transferFrom(address(this), receiver, _ids[i]);
        }
    }
}
