// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "Initializable.sol";
import "SetGetAssembly.sol";

contract Governable is Initializable, SetGetAssembly {
    event GovernanceUpdated(address newGovernance, address oldGovernance);

    bytes32 internal constant _GOVERNANCE_SLOT =
        0x597f9c7c685b907e823520bd45aeb3d58b505f86b2e41cd5b4cd5b6c72782950;
    bytes32 internal constant _PENDING_GOVERNANCE_SLOT =
        0xcd77091f18f9504fccf6140ab99e20533c811d470bb9a5a983d0edc0720fbf8c;

    modifier onlyGovernance() {
        require(_governance() == msg.sender, "Not governance");
        _;
    }

    constructor() public {
        assert(
            _GOVERNANCE_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.mesh.finance.governable.governance")
                    ) - 1
                )
        );
        assert(
            _PENDING_GOVERNANCE_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.governable.pendingGovernance"
                        )
                    ) - 1
                )
        );
    }

    function initializeGovernance(address _governance) public initializer {
        _setGovernance(_governance);
    }

    function _setGovernance(address _governance) private {
        setAddress(_GOVERNANCE_SLOT, _governance);
    }

    function _setPendingGovernance(address _pendingGovernance) private {
        setAddress(_PENDING_GOVERNANCE_SLOT, _pendingGovernance);
    }

    function updateGovernance(address _newGovernance) public onlyGovernance {
        require(
            _newGovernance != address(0),
            "new governance shouldn't be empty"
        );
        _setPendingGovernance(_newGovernance);
    }

    function acceptGovernance() public {
        require(_pendingGovernance() == msg.sender, "Not pending governance");
        address oldGovernance = _governance();
        _setGovernance(msg.sender);
        emit GovernanceUpdated(msg.sender, oldGovernance);
    }

    function _governance() internal view returns (address str) {
        return getAddress(_GOVERNANCE_SLOT);
    }

    function _pendingGovernance() internal view returns (address str) {
        return getAddress(_PENDING_GOVERNANCE_SLOT);
    }

    function governance() public view returns (address) {
        return _governance();
    }
}
