// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

library EscrowUtilsLib {
    struct MilestoneParams {
        address paymentToken;
        address treasury;
        address payeeAccount;
        address refundAccount;
        address escrowDisputeManager;
        uint autoReleasedAt;
        uint amount;
        uint16 parentIndex;
    }
    
    struct Contract {
        address payer;
        address payerDelegate;
        address payee;
        address payeeDelegate;
    }

    /**
     * @dev Generate bytes32 uid for contract's milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @return milestone id (mid).
     */
    function genMid(bytes32 _cid, uint16 _index) internal pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _index));
    }

    /**
     * @dev Generate unique terms key in scope of a contract.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid cid of suggested contract version.
     * @return unique storage key for amendment.
     */
    function genTermsKey(bytes32 _cid, bytes32 _termsCid) internal pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _termsCid));
    }

    /**
     * @dev Generate unique settlement key in scope of a contract milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone index.
     * @param _revision Current version of milestone extended terms.
     * @return unique storage key for amendment.
     */
    function genSettlementKey(bytes32 _cid, uint16 _index, uint8 _revision) internal pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _index, _revision));
    }
}