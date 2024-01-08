//SPDX-License-Identifier: Unlicense
/// @title: cozy co. membership
/// @author: The Stitcher AKA samking.eth
/*            



           :-.:-   .-:.=:    -==. :- .===  .==:      :-::-   .--.-:
         *@%..=@--%@+  %@# .#%%@@#-+.-@@#  #@@-    +@@: -@*:%@#  *@%.
        %@@:  :.-@@%  .@@@  ....:-:  %@@: -@@#    +@@=  ::.@@@.  %@@:
        %@@-    -@@+  #@@--=*%#*++*.-@@%.:%@@:    *@@+   ..@@#  +@@=-%@*
         =*#*=:  .+=.=+-  ==..=*#+: .**+--@@+      -***=-  .=+.-+-  .**=
                                   +@%. .@@=
                                    :=..-:

*/

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IMembershipMetadata.sol";

contract CozyCoMembership is Ownable, ERC1155Burnable {
    using MerkleProof for bytes32[];
    uint256[] private _membershipTypes;
    mapping(uint256 => address) private _membershipMetadata;
    mapping(uint256 => bytes32) private _merkleRoots;
    mapping(uint256 => mapping(address => bool)) private _claimedMemberships;

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_membershipMetadata[id] != address(0), "no metadata");
        return IMembershipMetadata(_membershipMetadata[id]).getURI(id);
    }

    function issueMembership(address to, uint256 membershipId)
        public
        virtual
        onlyOwner
    {
        _mintMembership(to, membershipId);
    }

    function issueMemberships(address[] memory _members, uint256 token)
        public
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _members.length; i++) {
            issueMembership(_members[i], token);
        }
    }

    function issueOneOffMembership(
        address to,
        uint256 membershipId,
        address metadata
    ) public virtual onlyOwner {
        require(
            _membershipMetadata[membershipId] == address(0),
            "membershipId in use"
        );
        _membershipMetadata[membershipId] = metadata;
        _mintMembership(to, membershipId);
    }

    function joinCozyCo(bytes32[] memory proof, uint256 membershipId) public {
        // If there's a merkleRoot for a given membershipId, then we know
        // the membership requires an "allow list" so we check if the sender
        // is on said list. If not, then we allow them to claim one token.
        if (_merkleRoots[membershipId] != 0) {
            require(
                proof.verify(
                    _merkleRoots[membershipId],
                    keccak256(abi.encodePacked(_msgSender()))
                ),
                "not claimable for address"
            );
        }
        _mintMembership(_msgSender(), membershipId);
    }

    function _mintMembership(address to, uint256 membershipId) private {
        require(_membershipMetadata[membershipId] != address(0), "no metadata");
        require(balanceOf(to, membershipId) == 0, "already member");
        require(
            _claimedMemberships[membershipId][to] == false,
            "already claimed"
        );
        _mint(to, membershipId, 1, "");
        _claimedMemberships[membershipId][to] = true;
    }

    function revokeMembership(
        address _address,
        uint256[] memory ids,
        uint256[] memory amounts,
        bool allowFutureReclaim
    ) public virtual onlyOwner {
        _burnBatch(_address, ids, amounts);
        // If for some reason we want to re-issue these memberships in future,
        // we want to reset the claimed state for the member
        if (allowFutureReclaim) {
            for (uint256 id = 0; id < ids.length; id++) {
                _claimedMemberships[id][_address] = false;
            }
        }
    }

    function addMembershipMetadataAddress(
        uint256 membershipId,
        address _address
    ) public onlyOwner {
        require(
            _membershipMetadata[membershipId] == address(0),
            "membershipId in use"
        );
        _membershipMetadata[membershipId] = _address;
        _membershipTypes.push(membershipId);
    }

    function dangerouslySetMembershipMetadataAddress(
        uint256 membershipId,
        address _address
    ) public onlyOwner {
        _membershipMetadata[membershipId] = _address;
    }

    function getMembershipTypes()
        public
        view
        returns (uint256[] memory membershipTypes)
    {
        return _membershipTypes;
    }

    function getMembershipMetadataAddress(uint256 membershipId)
        public
        view
        returns (address)
    {
        return _membershipMetadata[membershipId];
    }

    function setMembershipMerkleRoot(bytes32 root, uint256 membershipId)
        public
        onlyOwner
    {
        _merkleRoots[membershipId] = root;
    }

    function getMembershipMerkleRoot(uint256 membershipId)
        public
        view
        returns (bytes32)
    {
        return _merkleRoots[membershipId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor() ERC1155("") {}
}
