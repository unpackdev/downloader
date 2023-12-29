// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./Ownable.sol";
import "./AccessControlInternal.sol";
import "./TermsStorage.sol";
import "./Counters.sol";
import "./ConstantsLib.sol";

contract TermsFacet is OwnableInternal, AccessControlInternal {
    using Counters for Counters.Counter;
    /**
     * @notice Thrown if the caller is not a Keepers license operator
     */
    error NotTermsOperator(address);

    event TermsPartSet(uint256 indexed part, string indexed termsPart, uint256 indexed version);

    // expose the constant publicly
    string public constant WHERE_TO_FIND_TERMS = ConstantsLib.WHERE_TO_FIND_TERMS;

    /*//////////////////////////////////////////////////////////////
                          GET + SET TERMS AND CONDITIONS
    //////////////////////////////////////////////////////////////*/
    function getTerms() external view returns (string memory terms) {
        TermsStorage.Layout storage l = TermsStorage.layout();
        uint256 i;
        while (bytes(l.termsParts[i]).length != 0) {
            terms = string.concat(terms, l.termsParts[i]);
            unchecked {
                i++;
            }
        }
    }

    function setTermsPart(uint256 i, string memory part) external {
        TermsStorage.Layout storage l = TermsStorage.layout();
        if (!_hasRole(ConstantsLib.KEEPERS_TERMS_OPERATOR, msg.sender)) {
            revert NotTermsOperator(msg.sender);
        }
        l.termsParts[i] = part;
        l.termsVersion.increment();

        emit TermsPartSet(i, part, l.termsVersion.current());
    }

    function setTermsOperator(address operator) external onlyOwner {
        _grantRole(ConstantsLib.KEEPERS_TERMS_OPERATOR, operator);
    }

    function revokeTermsOperator(address operator) external onlyOwner {
        _revokeRole(ConstantsLib.KEEPERS_TERMS_OPERATOR, operator);
    }

    function getTermsPart(uint256 i) external view returns (string memory) {
        TermsStorage.Layout storage l = TermsStorage.layout();
        return l.termsParts[i];
    }

    function getTermsVersion() external view returns (uint256) {
        TermsStorage.Layout storage l = TermsStorage.layout();
        return l.termsVersion.current();
    }
}
