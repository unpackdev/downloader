// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

interface IVotingEscrow {
    function totalSupply(uint256 timestamp) external view returns (uint256);

    function balanceOf(address _t, uint256 timestamp)
        external
        view
        returns (uint256);
}

interface ILendFlareTokenLocker {
    function fund(address[] memory _recipients, uint256[] memory _amounts)
        external;
}

contract CurveInvestor is Initializable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Snapshot {
        uint256 blockTimestamp;
        uint256 block;
        uint256 votingEscrowSupply;
    }

    Snapshot public snapshot;

    address public constant votingEscrow =
        0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;
    address public lendFlareTokenLocker;

    uint256 public lockedSupply;
    uint256 public allocatedSupply;

    mapping(address => bool) public investors;

    event Bind(address indexed investor, uint256 amount);

    function initialize(address _lendFlareTokenLocker, uint256 _allocatedSupply)
        public
        initializer
    {
        require(_allocatedSupply > 0, " !_allocatedSupply");

        snapshot.blockTimestamp = block.timestamp;
        snapshot.votingEscrowSupply = IVotingEscrow(votingEscrow).totalSupply(
            block.timestamp
        );

        lendFlareTokenLocker = _lendFlareTokenLocker;
        allocatedSupply = _allocatedSupply;
    }

    function _calculate(address _sender) internal view returns (uint256) {
        uint256 bal = IVotingEscrow(votingEscrow).balanceOf(
            _sender,
            snapshot.blockTimestamp
        );

        uint256 amount = allocatedSupply
            .mul(1e18)
            .div(snapshot.votingEscrowSupply)
            .mul(bal)
            .div(1e18);

        return amount;
    }

    function check(address _sender) public view returns (uint256) {
        if (investors[_sender]) return 0;

        return _calculate(_sender);
    }

    function bind() public nonReentrant {
        require(!investors[msg.sender], "!You've tied it up.");

        investors[msg.sender] = true;

        uint256 amount = _calculate(msg.sender);

        require(amount > 0, "!amount");

        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        recipients[0] = msg.sender;
        amounts[0] = amount;
        lockedSupply = lockedSupply.add(amount);

        ILendFlareTokenLocker(lendFlareTokenLocker).fund(recipients, amounts);

        emit Bind(msg.sender, amount);
    }
}
