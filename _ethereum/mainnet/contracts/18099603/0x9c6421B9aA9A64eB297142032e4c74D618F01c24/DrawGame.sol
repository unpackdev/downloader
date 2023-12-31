/*
 Telegram: https://t.me/DrawPortal
 Twitter: https://twitter.com/DrawBotEth
 Website: https://drawboteth.com/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DrawBot.sol";

/**
 * @title DrawEscrowContract
 * @dev A smart contract for playing an Draw  game on Telegram with Draw token bets.
 */
contract DrawGameEscrow is Ownable {
    DrawBot public token;

    struct DrawEscrow {
        bool ongoing;
        uint256 totalWager;
    }

    using SafeMath for uint256;

    mapping(uint256 => DrawEscrow) public games;
    address public taxReceiver;
    uint256 public taxPercentage;
    uint256 public burnPercentage;

    event GameStarted(
        uint256 indexed gameIdentifier,
        address[] indexed participants,
        uint256 totalWager
    );

    event GameEnded(
        uint256 indexed gameIdentifier,
        address indexed victor,
        uint256 prizeAmount
    );

    constructor(
        DrawBot _tokenAddress,
        address _taxReceiver,
        uint256 _taxPercentage,
        uint256 _burnPercentage
    ) {
        token = DrawBot(_tokenAddress);
        taxReceiver = _taxReceiver;
        taxPercentage = _taxPercentage;
        burnPercentage = _burnPercentage;
    }

    address[] internal players;

    /**
     * @dev Check if there is an ongoing game for a Telegram group.
     * @param _gameIdentifier Telegram group to check
     * @return true if there is an ongoing game, otherwise false
     */
    function isGameOngoing(uint256 _gameIdentifier) public view returns (bool) {
        return games[_gameIdentifier].ongoing;
    }

    /**
     * @dev Place bets for a new game.
     * @param gameIdentifier Identifier for the game
     * @param _betters Array of _betters addresses
     * @param amountBet Array of bet amounts corresponding to participants
     * @return true if bet are successfully placed
     */
    function postBets(
        uint256 gameIdentifier,
        address[] memory _betters,
        uint256[] memory amountBet
    ) external onlyOwner returns (bool) {
        require(
            amountBet.length > 1,
            "DrawEscrow: Must involve more than 1 participant"
        );
        require(
            amountBet.length == amountBet.length,
            "DrawEscrow: Participant count must match wager count"
        );
        require(
            areAllEntriesEqual(amountBet),
            "DrawEscrow: All amountBet amounts must be equal"
        );

        uint256 totalEntries = 0;
        for (uint256 i = 0; i < _betters.length; i++) {
            require(
                token.allowance(_betters[i], address(this)) >= amountBet[i],
                "DrawEscrow: Insufficient allowance"
            );
            players.push(_betters[i]);
            token.transferFrom(_betters[i], address(this), amountBet[i]);
            totalEntries += amountBet[i];
        }
        games[gameIdentifier] = DrawEscrow(true, totalEntries);

        emit GameStarted(gameIdentifier, players, totalEntries);
        return true;
    }

    /**
     * @dev Reward the winner of a game and distribute taxes.
     * @param _gameIdentifier Identifier for the game
     * @param _conqueror Address of the winner
     */
    function payWInner(
        uint256 _gameIdentifier,
        address _conqueror
    ) external onlyOwner {
        require(
            isGameOngoing(_gameIdentifier),
            "DrawEscrow: Invalid Game Identifier"
        );
        require(
            isParticipantInArray(_conqueror),
            "DrawEscrow: Invalid Winner Address"
        );

        DrawEscrow storage g = games[_gameIdentifier];
        uint256 taxAmount = g.totalWager.mul(taxPercentage).div(100);
        uint256 burnShare = g.totalWager.mul(burnPercentage).div(100);
        uint256 prizeAmount = g.totalWager.sub(taxAmount).sub(burnShare);
        require(
            taxAmount + prizeAmount + burnShare <= g.totalWager,
            "DrawEscrow: Transfer Amount Exceeds Total Share"
        );

        token.transfer(_conqueror, prizeAmount);
        token.transfer(taxReceiver, taxAmount);
        token.burn(burnShare);
        delete games[_gameIdentifier];
        delete players;

        emit GameEnded(_gameIdentifier, _conqueror, prizeAmount);
    }

    /**
     * @dev Set the address for tax collection.
     * @param _taxReceiver Address to receive taxes
     */
    function setTaxReceiver(address _taxReceiver) public onlyOwner {
        taxReceiver = _taxReceiver;
    }

    /**
     * @dev Set the tax percentage.
     * @param _taxPercentage New tax percentage
     */
    function setTaxPercentage(uint256 _taxPercentage) public onlyOwner {
        taxPercentage = _taxPercentage;
    }

    /**
     * @dev Check if a participant address is in the participants array.
     * @param _participant Address to check
     * @return true if the participant is in the array, otherwise false
     */
    function isParticipantInArray(
        address _participant
    ) private view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == _participant) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Check if all entries amounts in an array are equal.
     * @param entries Array of wager amounts
     * @return true if all Entries are equal, otherwise false
     */
    function areAllEntriesEqual(
        uint256[] memory entries
    ) private pure returns (bool) {
        if (entries.length <= 1) {
            return true;
        }

        for (uint256 i = 1; i < entries.length; i++) {
            if (entries[i] != entries[0]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Withdraw ETH balance from the contract.
     */
    function withdrawEther() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Withdraw ERC20 token balance from the contract.
     * @param _tokenAddress Address of the ERC20 token
     */
    function withdraw(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, balance);
    }

    /**
     * @dev Withdraw ERC20 token balance from the contract.
     */
    function withdrawOwner() public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function modifyTokenAddress(
        address payable _tokenAddress
    ) public onlyOwner {
        token = DrawBot(_tokenAddress);
    }
}
