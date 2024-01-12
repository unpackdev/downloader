pragma solidity ^0.8.1;

import "./Multisig.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Escrow is MultiSigWallet {
    using SafeERC20 for IERC20;
    uint cliff; // represents a cliff for a user to claim available tokens
    
    address beneficiary_1;
    address beneficiary_2;

    uint claimed_1;
    uint claimed_2;

    address escrowToken;

    event Claim(address indexed beneficiary, uint indexed timestamp, uint indexed amount);
    event BeneficiaryUpdated(address indexed old, address indexed updated);
    event EscrowTokenUpdated(address oldToken, address newToken);

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary_1 || msg.sender == beneficiary_2, "Not a beneficiary");
        _;
    }

    modifier pastCliff() {
        require(block.timestamp >= cliff, "cliff");
        _;
    }

    constructor (address[] memory _owners, uint _required, address _ben1, address _ben2, uint _cliff, address _escrowToken) MultiSigWallet(_owners, _required) {
        beneficiary_1 = _ben1;
        beneficiary_2 = _ben2;
        cliff = _cliff;
        escrowToken = _escrowToken;
    }

    function getClaimableAmount(address claimer) public view returns (uint _claimed) {
        if (claimer != beneficiary_1 && claimer != beneficiary_2) return 0;
        (uint alreadyClaimed, uint claimedByOther) = claimer == beneficiary_1 ? (claimed_1, claimed_2) : (claimed_2, claimed_1);
        uint totalAvailable = IERC20(escrowToken).balanceOf(address(this));
        _claimed = 0;

        if (alreadyClaimed > claimedByOther) {
            // our claimer has claimed more already than the other beneficiary
            _claimed = totalAvailable - (alreadyClaimed - claimedByOther);
            _claimed = _claimed / 2; 
        } else {
            // beneficiaries are at equal claim, or the other benny has claimed more.  Account for the difference
            _claimed = totalAvailable - (claimedByOther - alreadyClaimed);
            _claimed = _claimed / 2;
            _claimed += claimedByOther - alreadyClaimed;
        }
    }

    function claim() onlyBeneficiary pastCliff external returns (uint amount) {
        amount = getClaimableAmount(msg.sender);

        if (msg.sender == beneficiary_1) claimed_1 = claimed_1 + amount;
        else if (msg.sender == beneficiary_2) claimed_2 = claimed_2 + amount;

        IERC20(escrowToken).safeTransfer(msg.sender, amount);

        emit Claim(msg.sender, block.timestamp, amount);
    }

    function updateBeneficiary(address _old, address _new) onlyWallet public {
        if (_old == beneficiary_1) beneficiary_1 = _new;
        else if (_old == beneficiary_2) beneficiary_2 = _new;

        emit BeneficiaryUpdated(_old, _new);
    }

    function updateEscrowToken(address _new) onlyWallet public {
        address old = escrowToken;
        escrowToken = _new;

        emit EscrowTokenUpdated(old, _new);
    }

}