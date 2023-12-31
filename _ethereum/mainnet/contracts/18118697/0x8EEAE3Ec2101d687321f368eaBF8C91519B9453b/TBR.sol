// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AccessControl.sol";
import "./Ownable.sol";

contract TBR is Ownable, AccessControl {
    // events
    event SessionToggled(address indexed _from, bool _to);

    // variables
    address[] public users;
    bool public sessionLive = false;
    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    mapping(address => uint256) public totalCoins;
    uint256 public fixPrizePool;

    constructor(address _operator, address _deployer) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, _operator);
        transferOwnership(_deployer);
    }

    // methods
    function addCoins(uint256 _coins) external payable {
        require(!sessionLive, "Session is live");
        require(
            _coins == 10 || _coins == 20 || _coins == 30,
            "Coins value didn't match"
        );
        require(totalCoins[msg.sender] < 30, "Max coins reached");
        require(totalCoins[msg.sender] + _coins <= 30, "You exceed max coins");
        if (totalCoins[msg.sender] == 0) {
            users.push(msg.sender);
        }
        if (_coins == 10) {
            require(msg.value == 0.008 ether, "Price value didn't match");
            totalCoins[msg.sender] = totalCoins[msg.sender] + 10;
        } else if (_coins == 20) {
            require(msg.value == 0.016 ether, "Price value didn't match");
            totalCoins[msg.sender] = totalCoins[msg.sender] + 20;
        } else if (_coins == 30) {
            require(msg.value == 0.024 ether, "Price value didn't match");
            totalCoins[msg.sender] = totalCoins[msg.sender] + 30;
        }
    }

    function airdropCoins(address[] memory _addresses, uint256 _coins)
        external
        onlyOwner
    {
        require(!sessionLive, "Session is live");
        require(_addresses.length > 0, "Address is empty");
        require(
            _coins == 10 || _coins == 20 || _coins == 30,
            "Coins value didn't match"
        );

        for (uint256 _i = 0; _i < _addresses.length; _i++) {
            if (
                totalCoins[_addresses[_i]] < 30 &&
                totalCoins[_addresses[_i]] + _coins <= 30
            ) {
                if (totalCoins[_addresses[_i]] == 0) {
                    users.push(_addresses[_i]);
                }
                totalCoins[_addresses[_i]] =
                    totalCoins[_addresses[_i]] +
                    _coins;
            }
        }
    }

    function resetSession() external onlyRole(OPERATOR_ROLE) {
        require(sessionLive, "Session is not live");
        for (uint256 _i = 0; _i < users.length; _i++) {
            delete totalCoins[users[_i]];
        }
        users = new address[](0);
        fixPrizePool = address(this).balance;
    }

    function shareReward(address[] memory _winnerAddress) external onlyOwner {
        require(_winnerAddress.length == 2, "TBR needs 2 winners at least");
        require(fixPrizePool != 0, "Prize pool is zero");

        (bool firstWinnerSent, ) = _winnerAddress[0].call{
            value: (fixPrizePool * 60) / 100
        }("");
        require(firstWinnerSent, "Failed to send Ether");

        (bool secondWinnerSent, ) = _winnerAddress[1].call{
            value: (fixPrizePool * 30) / 100
        }("");
        require(secondWinnerSent, "Failed to send Ether");

        (bool platformSent, ) = msg.sender.call{
            value: (fixPrizePool * 10) / 100
        }("");
        require(platformSent, "Failed to send Ether");

        fixPrizePool == 0;
    }

    function toggle() external onlyRole(OPERATOR_ROLE) {
        sessionLive = !sessionLive;
        emit SessionToggled(msg.sender, sessionLive);
    }

    function totalPrizePool() external view returns (uint256) {
        return (address(this).balance * 90) / 100;
    }
}
