// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Roles.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";
import "./Context.sol";


contract CitizenDaoLedger is Context, AccessControlEnumerable {
    using Counters for Counters.Counter;

    mapping (uint256 => address) private daos;
    Counters.Counter private daoCounter;
    address private nextLedger;

    struct Proposal {
        address dao;
        address proposer;
        uint256 index;
        uint256 blockNumber;
        bool passed;
        uint256 blockNumberPassedAt;
    }

    Counters.Counter private proposalCounter;
    mapping (uint256 => Proposal) private proposals;
    mapping (address => mapping (uint256 => uint256)) private proposalIndexByDao;
    

    constructor (address[] memory admins) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(Roles.LEDGER_WRITER_ROLE, _msgSender());
        for (uint i = 0; i < admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
        proposalCounter.increment(); // start proposal index at 1 for sense checking
    }


    function getCurrentDao() public view returns (address) {
        return daoCounter.current() > 0 ? daos[daoCounter.current()-1] : address(0x0);
    }

    function getDaoByIndex(uint256 index) public view returns (address) {
        require(index < daoCounter.current(), "CitizenDaoLedger: invalid dao index");
        return daos[index];
    }

    function updateDao(address dao) public returns (bool) {
        require(hasRole(Roles.LEDGER_WRITER_ROLE, _msgSender()), "CitizenDaoLedger: must have ledger writer role to update DAO");
        daos[daoCounter.current()] = dao;
        daoCounter.increment();
        emit DaoUpdated(_msgSender(), dao);
        return true;
    }

    function isMostRecentLedger() public view returns (bool) {
        return nextLedger == address(0x0);
    }

    function setMoreRecentLedger(address ledger) public returns (bool) {
        require(hasRole(Roles.LEDGER_WRITER_ROLE, _msgSender()), "CitizenDaoLedger: must have ledger writer role to update ledger");
        require(isMostRecentLedger(), "CitizenDaoLedger: Ledger no longer most recent");
        nextLedger = ledger;
        emit LedgerUpdated(_msgSender(), ledger);
        return true;
    }

    function getMoreRecentLedger() public view returns (address) {
        return nextLedger;
    }

    function proposal(address proposer, uint256 daoIndex) public returns (uint256) {
        require(hasRole(Roles.LEDGER_WRITER_ROLE, _msgSender()), "CitizenDaoLedger: must have ledger writer role to add proposal");
        require(_msgSender() == getCurrentDao(), "CitizenDaoLedger: only current DAO can write proposal ");
        uint256 index = proposalCounter.current();
        proposals[index].dao = _msgSender();
        proposals[index].proposer = proposer;
        proposals[index].index = daoIndex;
        proposals[index].blockNumber = block.number;

        proposalIndexByDao[_msgSender()][daoIndex] = index;
        emit Proposed(_msgSender(), daoIndex, index);
        proposalCounter.increment();
        return index;
    }

    function proposalPassed(uint256 daoIndex) public returns (bool) {
        require(hasRole(Roles.LEDGER_WRITER_ROLE, _msgSender()), "CitizenDaoLedger: must have ledger writer role to add proposal");
        require(_msgSender() == getCurrentDao(), "CitizenDaoLedger: only current DAO can update proposal");
        uint256 index = proposalIndexByDao[_msgSender()][daoIndex];
        require(index != 0, "CitizenDaoLedger: invalid DAO proposal index");
        require(!proposals[index].passed, "CitizenDaoLedger: proposal already passed");

        proposals[index].passed = true;
        proposals[index].blockNumberPassedAt = block.number;

        emit ProposalPassed(_msgSender(), daoIndex, index);
        return true;
    }

    function getProposal(uint256 index) public view returns (address, address, uint256, uint256, bool, uint256) {
        return (proposals[index].dao,
                proposals[index].proposer,
                proposals[index].index,
                proposals[index].blockNumber,
                proposals[index].passed,
                proposals[index].blockNumberPassedAt);
    }

    function canWriteToLedger(address writer) public view returns (bool) {
        return hasRole(Roles.LEDGER_WRITER_ROLE, writer) && isMostRecentLedger();
    }


    event Proposed(address indexed dao, uint256 indexed daoIndex, uint256 indexed ledgerIndex);
    event ProposalPassed(address indexed dao, uint256 indexed daoIndex, uint256 indexed ledgerIndex);
    event DaoUpdated(address indexed updater, address indexed dao);
    event LedgerUpdated(address indexed updater, address indexed ledger);
}
