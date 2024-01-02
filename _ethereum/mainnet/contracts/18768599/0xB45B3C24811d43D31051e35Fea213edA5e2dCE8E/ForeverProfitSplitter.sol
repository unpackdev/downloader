// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 /$$$$$$$$ /$$$$$$  /$$$$$$$  /$$$$$$$$ /$$    /$$ /$$$$$$$$ /$$$$$$$
| $$_____//$$__  $$| $$__  $$| $$_____/| $$   | $$| $$_____/| $$__  $$
| $$     | $$  \ $$| $$  \ $$| $$      | $$   | $$| $$      | $$  \ $$
| $$$$$  | $$  | $$| $$$$$$$/| $$$$$   |  $$ / $$/| $$$$$   | $$$$$$$/
| $$__/  | $$  | $$| $$__  $$| $$__/    \  $$ $$/ | $$__/   | $$__  $$
| $$     | $$  | $$| $$  \ $$| $$        \  $$$/  | $$      | $$  \ $$
| $$     |  $$$$$$/| $$  | $$| $$$$$$$$   \  $/   | $$$$$$$$| $$  | $$
|__/      \______/ |__/  |__/|________/    \_/    |________/|__/  |__/

         /$$
       /$$$$$$\ /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$   /$$ /$$$$$$$
      /$$__  $$||_  $$__/| $$__  $$| $$_____/| $$$ | $$| $$__  $$
     | $$  \__/   | $$   | $$  \ $$| $$      | $$$$| $$| $$  \ $$
     |  $$$$$$    | $$   | $$$$$$$/| $$$$$   | $$ $$ $$| $$  | $$
      \____  $$   | $$   | $$__  $$| $$__/   | $$  $$$$| $$  | $$
      /$$  \ $$   | $$   | $$  \ $$| $$      | $$\  $$$| $$  | $$
     |  $$$$$$/   | $$   | $$  | $$| $$$$$$$$| $$ \  $$| $$$$$$$/
      \_  $$_/    |__/   |__/  |__/|________/|__/  \__/|_______/
        \__/

    Contract: ForeverProfitSplitter
*/

import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IForeverProfitSplitter {
    enum ProfitOutlet {
        TRENDING,
        DEV,
        OTHER_SLOT_1,
        OTHER_SLOT_2,
        STAKING_POOL,
        TEAM_MEMBERS,
        TEAM_MEMBER_1,
        TEAM_MEMBER_2,
        TEAM_MEMBER_3,
        TEAM_MEMBER_4,
        TEAM_MEMBER_5,
        TEAM_MEMBER_6,
        TEAM_MEMBER_7,
        TEAM_MEMBER_8
    }

    function setProfitOutletRecipient(ProfitOutlet, address) external;

    function setProfitShares(uint256, uint256, uint256, uint256, uint256, uint256) external;

    function takeBalance() external;
}

interface IWETH is IERC20 {
    function withdraw(uint256) external;
}

contract ForeverProfitSplitter is Ownable, ReentrancyGuard, IForeverProfitSplitter {

    modifier onlyRecipient() {
        require(profitOutletRecipient[profitOutletLookup[_msgSender()]] == _msgSender(),
            "Caller is not a recipient.");
        _;
    }

    uint256 private _maxTeamMembersShare = 25000;
    uint256 private _maxDevShare = 25000;
    uint256 private _minimumStakingPoolShare = 15000;

    bool public autoSendToStakingPool = true;

    mapping(ProfitOutlet => uint256) public profitOutletBalance;
    mapping(ProfitOutlet => address) public profitOutletRecipient;
    mapping(ProfitOutlet => uint256) public profitOutletShare;
    mapping(address => ProfitOutlet) public profitOutletLookup;

    address public weth;

    event ProfitShareSet(
        uint256 newDevShare,
        uint256 newTrendingShare,
        uint256 newEmptySlot1Share,
        uint256 newEmptySlot2Share,
        uint256 newStakingPoolShare,
        uint256 newTeamMembersShare
    );
    event TeamMemberShareSet(
        uint256 newTeamMember1Share,
        uint256 newTeamMember2Share,
        uint256 newTeamMember3Share,
        uint256 newTeamMember4Share,
        uint256 newTeamMember5Share,
        uint256 newTeamMember6Share,
        uint256 newTeamMember7Share,
        uint256 newTeamMember8Share
    );
    event ProfitOutletRecipientSet(ProfitOutlet profitOutlet, address oldProfitRecipient, address newProfitRecipient);
    event EthFundsReceived(
        address user,
        uint256 amount
    );
    event WethSet(address weth);
    event AutoSendToStakingPoolSet(bool newValue);

    constructor() {
        // DEV
        profitOutletLookup[address(0x4BE77Df0A25827B83CE2a54593b708CFc386242d)] = ProfitOutlet.DEV;
        profitOutletRecipient[ProfitOutlet.DEV] = address(0x4BE77Df0A25827B83CE2a54593b708CFc386242d);
        profitOutletShare[ProfitOutlet.DEV] = 10000;

        // TRENDING
        profitOutletLookup[address(0xB024D12eB7B7D21F50BcbEa10922b5e139257c5C)] = ProfitOutlet.TRENDING;
        profitOutletRecipient[ProfitOutlet.TRENDING] = address(0xB024D12eB7B7D21F50BcbEa10922b5e139257c5C);
        profitOutletShare[ProfitOutlet.TRENDING] = 20000;

        // STAKING
        profitOutletLookup[address(0x392aA88063A798A7c12d0c9F5650e249e36Ea1ef)] = ProfitOutlet.STAKING_POOL;
        profitOutletRecipient[ProfitOutlet.STAKING_POOL] = address(0x392aA88063A798A7c12d0c9F5650e249e36Ea1ef);
        profitOutletShare[ProfitOutlet.STAKING_POOL] = 60000;

        profitOutletShare[ProfitOutlet.OTHER_SLOT_1] = 0;
        profitOutletShare[ProfitOutlet.OTHER_SLOT_2] = 0;
        profitOutletShare[ProfitOutlet.TEAM_MEMBERS] = 10000;

        // TEAM MEMBER 1
        profitOutletLookup[address(0xE0a029E3dC9510C3A7D82b233D86A8d8D13CA9ea)] = ProfitOutlet.TEAM_MEMBER_1;
        profitOutletRecipient[ProfitOutlet.TEAM_MEMBER_1] = address(0xE0a029E3dC9510C3A7D82b233D86A8d8D13CA9ea);
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_1] = 25000;

        // TEAM MEMBER 2
        profitOutletLookup[address(0x34E0539890fD0DD7e8bA86025589d4206E191D5f)] = ProfitOutlet.TEAM_MEMBER_2;
        profitOutletRecipient[ProfitOutlet.TEAM_MEMBER_2] = address(0x34E0539890fD0DD7e8bA86025589d4206E191D5f);
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_2] = 25000;

        // TEAM MEMBER 3
        profitOutletLookup[address(0xfAF0e06693284097e6E1dD0e1628374639C3d566)] = ProfitOutlet.TEAM_MEMBER_3;
        profitOutletRecipient[ProfitOutlet.TEAM_MEMBER_3] = address(0xfAF0e06693284097e6E1dD0e1628374639C3d566);
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_3] = 25000;

        // TEAM MEMBER 4
        profitOutletLookup[address(0xD52bC5C367413028E05941b8bb44C855C60DD5B1)] = ProfitOutlet.TEAM_MEMBER_4;
        profitOutletRecipient[ProfitOutlet.TEAM_MEMBER_4] = address(0xD52bC5C367413028E05941b8bb44C855C60DD5B1);
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_4] = 25000;

        profitOutletShare[ProfitOutlet.TEAM_MEMBER_5] = 0;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_6] = 0;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_7] = 0;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_8] = 0;

        weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    receive() external payable {
        uint256 _numberOfEthInTransaction = msg.value;

        uint256 _amountDev = (_numberOfEthInTransaction * profitOutletShare[ProfitOutlet.DEV]) / 100000;
        uint256 _amountTrending = (_numberOfEthInTransaction * profitOutletShare[ProfitOutlet.TRENDING]) / 100000;
        uint256 _amountOtherProfitSlot1 = (_numberOfEthInTransaction * profitOutletShare[ProfitOutlet.OTHER_SLOT_1]) / 100000;
        uint256 _amountOtherProfitSlot2 = (_numberOfEthInTransaction * profitOutletShare[ProfitOutlet.OTHER_SLOT_2]) / 100000;
        uint256 _amountStakingPool = (_numberOfEthInTransaction * profitOutletShare[ProfitOutlet.STAKING_POOL]) / 100000;
        uint256 _amountForTeamMembers = (_numberOfEthInTransaction * profitOutletShare[ProfitOutlet.TEAM_MEMBERS]) / 100000;

        uint256 _amountTeamMember1 = (_amountForTeamMembers * profitOutletShare[ProfitOutlet.TEAM_MEMBER_1]) / 100000;
        uint256 _amountTeamMember2 = (_amountForTeamMembers * profitOutletShare[ProfitOutlet.TEAM_MEMBER_2]) / 100000;
        uint256 _amountTeamMember3 = (_amountForTeamMembers * profitOutletShare[ProfitOutlet.TEAM_MEMBER_3]) / 100000;
        uint256 _amountTeamMember4 = (_amountForTeamMembers * profitOutletShare[ProfitOutlet.TEAM_MEMBER_4]) / 100000;
        uint256 _amountTeamMember5 = (_amountForTeamMembers * profitOutletShare[ProfitOutlet.TEAM_MEMBER_5]) / 100000;
        uint256 _amountTeamMember6 = (_amountForTeamMembers * profitOutletShare[ProfitOutlet.TEAM_MEMBER_6]) / 100000;
        uint256 _amountTeamMember7 = (_amountForTeamMembers * profitOutletShare[ProfitOutlet.TEAM_MEMBER_7]) / 100000;
        uint256 _amountTeamMember8 = (_amountForTeamMembers * profitOutletShare[ProfitOutlet.TEAM_MEMBER_8]) / 100000;

        profitOutletBalance[ProfitOutlet.DEV] += _amountDev;
        profitOutletBalance[ProfitOutlet.TRENDING] += _amountTrending;
        profitOutletBalance[ProfitOutlet.OTHER_SLOT_1] += _amountOtherProfitSlot1;
        profitOutletBalance[ProfitOutlet.OTHER_SLOT_2] += _amountOtherProfitSlot2;
        profitOutletBalance[ProfitOutlet.STAKING_POOL] += _amountStakingPool;
        profitOutletBalance[ProfitOutlet.TEAM_MEMBER_1] += _amountTeamMember1;
        profitOutletBalance[ProfitOutlet.TEAM_MEMBER_2] += _amountTeamMember2;
        profitOutletBalance[ProfitOutlet.TEAM_MEMBER_3] += _amountTeamMember3;
        profitOutletBalance[ProfitOutlet.TEAM_MEMBER_4] += _amountTeamMember4;
        profitOutletBalance[ProfitOutlet.TEAM_MEMBER_5] += _amountTeamMember5;
        profitOutletBalance[ProfitOutlet.TEAM_MEMBER_6] += _amountTeamMember6;
        profitOutletBalance[ProfitOutlet.TEAM_MEMBER_7] += _amountTeamMember7;
        profitOutletBalance[ProfitOutlet.TEAM_MEMBER_8] += _amountTeamMember8;

        if (autoSendToStakingPool && _amountStakingPool > 0) {
            _sendBalance(ProfitOutlet.STAKING_POOL);
        }

        emit EthFundsReceived(
            _msgSender(),
            msg.value
        );
    }

    function setWETH(address _weth) external onlyOwner {
        require(_weth != address(0) && _weth != address(0x000000000000000000000000000000000000dEaD), "New weth address can not be address 0x");
        weth = _weth;
        emit WethSet(_weth);
    }

    function setAutoSendToStakingPool(bool _newValue) external onlyOwner {
        require(_newValue != autoSendToStakingPool, "autoSendToStakingPool is already that value");
        autoSendToStakingPool = _newValue;
        emit AutoSendToStakingPoolSet(_newValue);
    }

    function setProfitOutletRecipient(ProfitOutlet _profitOutlet, address _profitRecipient) external onlyOwner {
        require(_profitRecipient != address(0) && _profitRecipient != address(0x000000000000000000000000000000000000dEaD), "New recipient wallet can not be address 0x");
        require(profitOutletRecipient[_profitOutlet] != _profitRecipient, "The recipient address is already this address");

        address oldProfitRecipient = profitOutletRecipient[_profitOutlet];
        profitOutletLookup[_profitRecipient] = _profitOutlet;
        profitOutletRecipient[_profitOutlet] = _profitRecipient;

        emit ProfitOutletRecipientSet(_profitOutlet, oldProfitRecipient, _profitRecipient);
    }

    function setProfitShares(
        uint256 _newDevShare,
        uint256 _newTrendingShare,
        uint256 _newEmptySlot1Share,
        uint256 _newEmptySlot2Share,
        uint256 _newStakingPoolShare,
        uint256 _newTeamMembersShare) external onlyOwner {

        require(_newTeamMembersShare <= _maxTeamMembersShare, "Team members can never receive more then 25%");
        require(_newDevShare <= _maxDevShare, "Dev can never receive more then 25%");
        require(_newStakingPoolShare <= _minimumStakingPoolShare, "Staking pool can never receive less then 15%");
        require(_newDevShare + _newTrendingShare + _newEmptySlot1Share + _newEmptySlot2Share +
        _newStakingPoolShare + _newTeamMembersShare == 100000,
            "Summed profit shares are not 100%"
        );

        profitOutletShare[ProfitOutlet.DEV] = _newDevShare;
        profitOutletShare[ProfitOutlet.TRENDING] = _newTrendingShare;
        profitOutletShare[ProfitOutlet.OTHER_SLOT_1] = _newEmptySlot1Share;
        profitOutletShare[ProfitOutlet.OTHER_SLOT_2] = _newEmptySlot2Share;
        profitOutletShare[ProfitOutlet.STAKING_POOL] = _newStakingPoolShare;
        profitOutletShare[ProfitOutlet.TEAM_MEMBERS] = _newTeamMembersShare;

        emit ProfitShareSet(
            _newDevShare,
            _newTrendingShare,
            _newEmptySlot1Share,
            _newEmptySlot2Share,
            _newStakingPoolShare,
            _newTeamMembersShare
        );
    }

    function setTeamMembersShare(
        uint256 _newTeamMember1Share,
        uint256 _newTeamMember2Share,
        uint256 _newTeamMember3Share,
        uint256 _newTeamMember4Share,
        uint256 _newTeamMember5Share,
        uint256 _newTeamMember6Share,
        uint256 _newTeamMember7Share,
        uint256 _newTeamMember8Share
    ) external onlyOwner {
        require(_newTeamMember1Share + _newTeamMember2Share + _newTeamMember3Share + _newTeamMember4Share +
        _newTeamMember5Share + _newTeamMember6Share + _newTeamMember7Share + _newTeamMember8Share == 100000,
            "Summed team member shares are not 100%"
        );

        profitOutletShare[ProfitOutlet.TEAM_MEMBER_1] = _newTeamMember1Share;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_2] = _newTeamMember2Share;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_3] = _newTeamMember3Share;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_4] = _newTeamMember4Share;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_5] = _newTeamMember5Share;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_6] = _newTeamMember6Share;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_7] = _newTeamMember7Share;
        profitOutletShare[ProfitOutlet.TEAM_MEMBER_8] = _newTeamMember8Share;

        emit TeamMemberShareSet(
            _newTeamMember1Share,
            _newTeamMember2Share,
            _newTeamMember3Share,
            _newTeamMember4Share,
            _newTeamMember5Share,
            _newTeamMember6Share,
            _newTeamMember7Share,
            _newTeamMember8Share
        );
    }

    function takeBalance() external onlyRecipient {
        _sendBalance(profitOutletLookup[_msgSender()]);
    }

    function pushAll() external {
        _sendBalance(ProfitOutlet.TRENDING);
        _sendBalance(ProfitOutlet.DEV);
        _sendBalance(ProfitOutlet.OTHER_SLOT_1);
        _sendBalance(ProfitOutlet.OTHER_SLOT_2);
        _sendBalance(ProfitOutlet.STAKING_POOL);
        _sendBalance(ProfitOutlet.TEAM_MEMBER_1);
        _sendBalance(ProfitOutlet.TEAM_MEMBER_2);
        _sendBalance(ProfitOutlet.TEAM_MEMBER_3);
        _sendBalance(ProfitOutlet.TEAM_MEMBER_4);
        _sendBalance(ProfitOutlet.TEAM_MEMBER_5);
        _sendBalance(ProfitOutlet.TEAM_MEMBER_6);
        _sendBalance(ProfitOutlet.TEAM_MEMBER_7);
        _sendBalance(ProfitOutlet.TEAM_MEMBER_8);
    }

    function rescueWETH() external onlyOwner {
        IWETH(weth).withdraw(IERC20(weth).balanceOf(address(this)));
    }

    function rescueETH() external onlyOwner {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "No ETH to withdraw");

        (bool success,) = profitOutletRecipient[ProfitOutlet.DEV].call{value : _balance}("");
        require(success, "ETH transfer failed");
    }

    function _sendBalance(ProfitOutlet profitOutlet) internal nonReentrant {
        if (profitOutletRecipient[profitOutlet] == address(0)) {
            return;
        }

        uint256 _ethToSend = profitOutletBalance[profitOutlet];

        if (_ethToSend > 0) {
            profitOutletBalance[profitOutlet] = 0;

            (bool success,) = profitOutletRecipient[profitOutlet].call{value : _ethToSend}("");
            if (!success) {
                profitOutletBalance[profitOutlet] += _ethToSend;
            }
        }
    }

}
