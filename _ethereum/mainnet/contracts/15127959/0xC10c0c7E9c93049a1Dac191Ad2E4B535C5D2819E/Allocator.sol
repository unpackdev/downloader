// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Timers.sol";
import "./Maintanable.sol";
import "./IAllocator.sol";

contract Allocator is Maintanable, IAllocator {
    using Timers for Timers.BlockNumber;

    bool public allocatorActive;
    bool public allocatorInitialized;

    //Phases
    Phase[] internal _phases;

    // Allocation
    uint256 public baseMaxAllocation;
    uint256 internal _totalAllocation;
    mapping(address => uint256) internal _curAllocations;
    mapping(address => uint256) internal _maxAllocations;

    // Modifiers
    modifier onlyWhenAllocatable(address allocator, uint256 amount) {
        (bool allowed, string memory message) = canAllocate(allocator, amount);
        require(allowed, message);
        _;
    }

    function initializeAllocator() public onlyOwner {
        require(!allocatorInitialized, 'Allocator: already initialized');
        allocatorInitialized = true;
        setAllocatorActive(true);
    }

    function setAllocatorActive(bool active) public override onlyOwner {
        allocatorActive = active;
        emit AllocatorSet(active);
    }

    function isAllocatorActive() public view override returns (bool) {
        return allocatorInitialized && allocatorActive;
    }

    function currentAllocation(address allocator) public override view returns(uint256) {
        return _curAllocations[allocator];
    }

    function maximumAllocation(address allocator) public override view returns(uint256) {
        return _maxAllocations[allocator];
    }

    function totalAllocationLimit() public view override returns(uint256) {
        return _totalAllocation;
    }

    function setAllocations(Allocation[] memory allocs) external override onlyMaintainer {
        for (uint i=0; i < allocs.length; i++) {
            setAllocation(allocs[i].allocator, allocs[i].amount);
        }
    }

    function setAllocation(address allocator, uint256 amount) public override onlyMaintainer {
        _maxAllocations[allocator] = amount;
        emit MaxAllocation(allocator, amount);
    }

    function setBaseAllocation(uint256 amount) public override onlyOwner {
        baseMaxAllocation = amount;
        emit MaxBaseAllocation(amount);
    }

    function canAllocate(address allocator, uint256 amount) public view override returns (bool, string memory) {
        uint256 phaseMintLimit = getCurrentPhaseLimit();

        if (!isAllocatorActive()) {
            return (false, "Allocator: cannot allocate yet!");
        }
        if (phaseMintLimit != 0 && (_totalAllocation + amount > phaseMintLimit)) {
            return (false, "Allocator: phase limit reached!");
        }

        uint256 curAllocation = _curAllocations[allocator];
        uint256 maxAllocation = _maxAllocations[allocator];

        if ((maxAllocation != 0 && curAllocation + amount > maxAllocation)
            || (maxAllocation == 0 && curAllocation + amount > baseMaxAllocation))
        {
            return (false, "Allocator: max user allocation limit reached!");
        }

        return (true, "");
    }

    function allocate(address allocator, uint256 amount) public onlyMaintainer onlyWhenAllocatable(allocator, amount) {
        _curAllocations[allocator] += amount;
        _totalAllocation += amount;
        emit CurrentAllocation(allocator, _curAllocations[allocator]);
    }


    // Phases
    function setPhases(Phase[] memory phases) public override onlyOwner {
        delete _phases;

        for (uint i=0; i < phases.length; i++) {
            insertPhase(phases[i]);
        }
    }

    function insertPhase(Phase memory phase) public override onlyOwner {
        if (_phases.length > 0) {
            Phase storage lastPhase = _phases[_phases.length-1];
            require(lastPhase.block.getDeadline() < phase.block.getDeadline() && lastPhase.mintLimit < phase.mintLimit,
                "Allocator: wrong phase parameters!");
        }

        _phases.push(phase);
        emit PhaseSet({ id: _phases.length-1, deadline: phase.block.getDeadline(), limit: phase.mintLimit });
    }

    function updatePhase(uint256 phaseId, uint64 blockNumber, uint256 minLimit) public override onlyOwner {
        require(phaseId < _phases.length, "Phase do not exist!");

        if (phaseId > 0) {
            Phase storage phaseBefore = _phases[phaseId-1];
            require(phaseBefore.block.getDeadline() < blockNumber && phaseBefore.mintLimit < minLimit,
                "Allocator: wrong phase parameters!");
        }

        if (phaseId < _phases.length-1) {
            Phase storage phaseAfter = _phases[phaseId+1];
            require(phaseAfter.block.getDeadline() > blockNumber && phaseAfter.mintLimit > minLimit,
                "Allocator: wrong phase parameters!");
        }

        Phase storage phaseUp = _phases[phaseId];
        phaseUp.block.setDeadline(blockNumber);
        phaseUp.mintLimit = minLimit;

        emit PhaseSet({id: phaseId, deadline: blockNumber, limit: minLimit});
    }

    function getPhases() external view override returns(Phase[] memory) {
        return _phases;
    }

    function getCurrentPhaseLimit() public view override returns(uint256) {
        for (uint i=0; i < _phases.length; i++) {
            Phase storage nextPhase = _phases[i];
            
            if (!nextPhase.block.isExpired()) {
                return nextPhase.mintLimit;
            }
        }
        return 0;
    }
}