// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./EscrowUtilsLib.sol";

library AragonCourtMetadataLib {
    bytes2 private constant IPFS_V1_PREFIX = 0x1220;
    bytes32 private constant AC_GREET_PREFIX = 0x4752454554000000000000000000000000000000000000000000000000000000; // GREET
    bytes32 private constant PAYEE_BUTTON_COLOR = 0xffb46d0000000000000000000000000000000000000000000000000000000000; // Orange
    bytes32 private constant PAYER_BUTTON_COLOR = 0xffb46d0000000000000000000000000000000000000000000000000000000000; // Orange
    bytes32 private constant DEFAULT_STATEMENT_PAYER = bytes32(0);
    bytes32 private constant DEFAULT_STATEMENT_PAYEE = bytes32(0);
    string private constant PAYER_BUTTON = "Payer";
    string private constant PAYEE_BUTTON = "Payee";
    string private constant PAYEE_SETTLEMENT = " % released to Payee";
    string private constant PAYER_SETTLEMENT = " % refunded to Payer";
    string private constant SEPARATOR = ", ";
    string private constant NEW_LINE = "\n";
    string private constant DESC_PREFIX = "Should the escrow funds associated with ";
    string private constant DESC_SUFFIX = "the contract be distributed according to the claim of Payer or Payee?";
    string private constant DESC_MILESTONE_PREFIX = "Milestone ";
    string private constant DESC_MILESTONE_SUFFIX = " of ";
    string private constant PAYER_CLAIM_PREFIX = "Payer claim: ";
    string private constant PAYEE_CLAIM_PREFIX = "Payee claim: ";

    struct Claim {
        uint refundedPercent;
        uint releasedPercent;
        bytes32 statement;
    }

    struct EnforceableSettlement {
        address escrowContract;
        Claim payerClaim;
        Claim payeeClaim;
        uint256 fillingStartsAt;
        uint256 did;
        uint256 ruling;
    }

    /**
     * @dev ABI encoded payload for Aragon Court dispute metadata.
     *
     * @param _enforceableSettlement EnforceableSettlement suggested by both parties.
     * @param _termsCid Latest approved version of IPFS cid for contract in dispute.
     * @param  _plaintiff Address of disputer.
     * @param _index Milestone index to dispute.
     * @param _multi Does contract has many milestones?
     * @return description text
     */
    function generatePayload(
        EnforceableSettlement memory _enforceableSettlement,
        bytes32 _termsCid,
        address _plaintiff,
        uint16 _index,
        bool _multi
    ) internal pure returns (bytes memory) {
        bytes memory _desc = textForDescription(
            _index,
            _multi,
            _enforceableSettlement.payeeClaim,
            _enforceableSettlement.payerClaim
        );
        
        return abi.encode(
            AC_GREET_PREFIX,
            toIpfsCid(_termsCid),
            _plaintiff,
            PAYER_BUTTON,
            PAYER_BUTTON_COLOR,
            PAYEE_BUTTON,
            PAYER_BUTTON_COLOR,
            _desc
        );
    }

    /**
     * @dev By default Payee asks for a full release of escrow funds.
     *
     * @return structured claim.
     */
    function defaultPayeeClaim() internal pure returns (Claim memory) {
        return Claim({
            refundedPercent: 0,
            releasedPercent: 100,
            statement: DEFAULT_STATEMENT_PAYEE
        });
    }

    /**
     * @dev By default Payer asks for a full refund of escrow funds.
     *
     * @return structured claim.
     */
    function defaultPayerClaim() internal pure returns (Claim memory) {
        return Claim({
            refundedPercent: 100,
            releasedPercent: 0,
            statement: DEFAULT_STATEMENT_PAYER
        });
    }

    /**
     * @dev Adds prefix to produce compliant hex encoded IPFS cid.
     *
     * @param _chunkedCid Bytes32 chunked cid version.
     * @return full IPFS cid
     */
    function toIpfsCid(bytes32 _chunkedCid) internal pure returns (bytes memory) {
        return abi.encodePacked(IPFS_V1_PREFIX, _chunkedCid);
    }

    /**
     * @dev Produces different texts based on milestone to be disputed.
     * e.g. "Should the funds in the escrow associated with (Milestone X of)
     * the contract be released/refunded according to Payer or Payee's claim?" or
     * "Should the funds in the escrow associated with the contract ..."  in case
     * of single milestone.
     *
     * @param _index Milestone index to dispute.
     * @param _multi Does contract has many milestones?
     * @param _payeeClaim Suggested claim from Payee.
     * @param _payerClaim Suggested claim from Payer.
     * @return description text
     */
    function textForDescription(
        uint256 _index,
        bool _multi,
        Claim memory _payeeClaim,
        Claim memory _payerClaim
    ) internal pure returns (bytes memory) {
        bytes memory _claims = abi.encodePacked(
            NEW_LINE,
            NEW_LINE,
            PAYER_CLAIM_PREFIX,
            textForClaim(_payerClaim.refundedPercent, _payerClaim.releasedPercent),
            NEW_LINE,
            NEW_LINE,
            PAYEE_CLAIM_PREFIX,
            textForClaim(_payeeClaim.refundedPercent, _payeeClaim.releasedPercent)
        );

        if (_multi) {
            return abi.encodePacked(
                DESC_PREFIX,
                DESC_MILESTONE_PREFIX,
                uint2str(_index),
                DESC_MILESTONE_SUFFIX,
                DESC_SUFFIX,
                _claims
            );
        } else {
            return abi.encodePacked(
                DESC_PREFIX,
                DESC_SUFFIX,
                _claims
            );
        }
    }

    /**
     * @dev Produces different texts for buttons in context of refunded and released percents.
     * e.g. "90 % released to Payee, 10 % refunded to Payer" or "100 % released to Payee" etc
     *
     * @param _refundedPercent Percent to refund 0-100.
     * @param _releasedPercent Percent to release 0-100.
     * @return button text
     */
    function textForClaim(uint256 _refundedPercent, uint256 _releasedPercent) internal pure returns (string memory) {
        if (_refundedPercent == 0) {
            return string(abi.encodePacked(uint2str(_releasedPercent), PAYEE_SETTLEMENT));
        } else if (_releasedPercent == 0) {
            return string(abi.encodePacked(uint2str(_refundedPercent), PAYER_SETTLEMENT));
        } else {
            return string(abi.encodePacked(
                uint2str(_releasedPercent),
                PAYEE_SETTLEMENT,
                SEPARATOR,
                uint2str(_refundedPercent),
                PAYER_SETTLEMENT
            ));
        }
    }

    /**
     * @dev oraclizeAPI function to convert uint256 to memory string.
     *
     * @param _i Number to convert.
     * @return number in string encoding.
     */
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        
        unchecked {
            while (_i != 0) {
                bstr[k--] = bytes1(uint8(48 + _i % 10));
                _i /= 10;
            }
        }
        return string(bstr);
    }
}