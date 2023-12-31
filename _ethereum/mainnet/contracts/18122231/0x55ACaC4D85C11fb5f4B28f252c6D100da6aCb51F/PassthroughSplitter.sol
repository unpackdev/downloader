// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./Ownable.sol";
import "./IERC20.sol";

contract PassthroughSplitter is Ownable {
    address public teamAddress;
    address public potAddress;
    address public assistant;
    uint256 public teamRatio = 7;
    uint256 public potRatio = 3;

    constructor(address _team, address _pot, address _assistant) {
        teamAddress = _team;
        potAddress = _pot;
        assistant = _assistant;
    }

    modifier ownerOrAssistantOnly() {
        if (msg.sender != owner()) {
            require(assistant != address(0), "Assistant address is not set");
            require(msg.sender == assistant, "Not authorized.");
        }
        _;
    }

    function setTeamAddress(address _team) external onlyOwner {
        teamAddress = _team;
    }

    function setPotAddress(address _pot) external onlyOwner {
        potAddress = _pot;
    }

    function setAssistantAddress(address _assistant) external onlyOwner {
        assistant = _assistant;
    }

    function disburseToken(IERC20 _token) external ownerOrAssistantOnly {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Balance is 0");
        bool teamSent = token.transfer(teamAddress, (balance * teamRatio) / 10);
        require(teamSent, "Error while transfering to team");
        bool potSent = token.transfer(potAddress, (balance * potRatio) / 10);
        require(potSent, "Error while transfering to pot");
    }

    receive() external payable {
        (bool teamSent, ) = teamAddress.call{
            value: (msg.value * teamRatio) / 10
        }("");
        require(teamSent, "Error while transfering to team");

        (bool potSent, ) = potAddress.call{value: (msg.value * potRatio) / 10}(
            ""
        );
        require(potSent, "Error while transfering to pot");
    }
}
