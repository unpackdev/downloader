/// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;
import "./Governable.sol";
import "./MerkleProof.sol";

/**
 * @title RCA Treasury
 * @notice This contract holds all Ether funds from both liquidated tokens
 * and fees that are taken for the operation of the ecosystem.
 * It also functions as the contract to claim losses from when a hack occurs.
 * @author Robert M.C. Forster
 */
contract RcaTreasury is Governable {
    // Amount of claims available for individual addresses (in Ether).
    // ID of hack => amount claimable.
    mapping(uint256 => bytes32) public claimsRoots;
    // address => id of hack => claimed.
    mapping(address => mapping(uint256 => bool)) public claimed;

    event Claim(address indexed user, uint256 indexed hackId, uint256 indexed etherAmount);
    event Root(uint256 indexed coverId, bytes32 root);

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// constructor ////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Constructor just used to set governor that can withdraw funds from the contract.
     * @param _governor Full owner of this contract.
     */
    constructor(address _governor) {
        initializeGovernable(_governor);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// fallback //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Just here to accept Ether.
     */
    receive() external payable {}

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// external //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Users claim directly from here for loss in any vault.
     * @param _user Address of the user to claim for.
     * @param _loss The amount of loss (in Ether) that the protocol is paying.
     * @param _hackId ID given to the hack that resulted in this loss.
     * @param _claimsProof Merkle proof to verify this user's claim.
     */
    function claimFor(
        address payable _user,
        uint256 _loss,
        uint256 _hackId,
        bytes32[] calldata _claimsProof
    ) external {
        require(!claimed[_user][_hackId], "Loss has already been claimed.");
        verifyClaim(_user, _hackId, _loss, _claimsProof);
        claimed[_user][_hackId] = true;
        _user.transfer(_loss);
        emit Claim(_user, _hackId, _loss);
    }

    // capacity available function
    function verifyClaim(
        address _user,
        uint256 _hackId,
        uint256 _amount,
        bytes32[] memory _claimsProof
    ) public view {
        bytes32 leaf = keccak256(abi.encodePacked(_user, _hackId, _amount));
        require(MerkleProof.verify(_claimsProof, claimsRoots[_hackId], leaf), "Incorrect capacity proof.");
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////// onlyGov //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Governance sends in hack ID and a Merkle root corresponding to individual loss in this hack.
     * @param _hackId ID of the hack that this root is for. (Assigned by our protocol).
     * @param _newClaimsRoot Merkle root for new capacities available for each protocol (in USD).
     */
    function setClaimsRoot(uint256 _hackId, bytes32 _newClaimsRoot) external onlyGov {
        claimsRoots[_hackId] = _newClaimsRoot;
        emit Root(_hackId, _newClaimsRoot);
    }

    /**
     * @notice Governance may withdraw any amount to any address.
     * @param _to Address to send funds to.
     * @param _amount Amount of funds (in Ether) to send.
     */
    function withdraw(address payable _to, uint256 _amount) external onlyGov {
        _to.transfer(_amount);
    }
}
