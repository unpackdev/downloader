// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Royalty.sol";
import "./Ownable.sol";

import "./Signatures.sol";

contract PyramidDao is ERC721Royalty, Ownable {
    using Signatures for bytes;
    using Strings for uint;

    address _royaltyAddress;

    bool _useLevelOrderURI = false;

    error InvalidInvite();
    error InviteAlreadyUsed();
    error InviteRequired();
    error NotAuthorised();
    error PaymentTooSmall();
    error TokenDoesNotExist();
    error WalletQuantityExceeded();
    error ZeroBalance();

    event MemberWithdrawal(uint256 memberId, uint256 amount);
    event NewMember(Member newMember);

    // mapping from memberId to inviteCodes
    mapping(uint256 => mapping(uint256 => bool)) _inviteUsed;

    string _defaultBaseURI;
    string _levelOrderURI;
    string _uriSuffix = '';

    struct Member {
        uint256 invitedBy;
        uint256 inviteCount;
        uint256 level;
        uint256 order;
        uint256 totalCommission;
        uint256 unclaimedCommission;
    }

    uint96 _royaltyNumerator = 1000;

    // Public

    // mapping from address to memberId
    mapping(address => uint256) public memberId;

    //mapping from memberId to Member
    mapping(uint256 => Member) public members;

    string public contractURI;

    uint256 public commissionReserve = 0;
    uint256 public fooCount = 0;
    uint256 public totalSupply = 7;
    uint256 public membershipFee = 0.22 ether;

    // Constructor

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI
    )
        ERC721(_name, _symbol)
    {
        _defaultBaseURI = _baseURI;
        contractURI = _contractURI;
        _royaltyAddress = msg.sender;
    }

    /**
     * Payable
     */

    /**
     * Join
     * @dev allows an account with an inviteCode to purchase a membership
     * @param inviteCode an inviteCode provided by an existing member
     * @return Member
     */
    function join(
        uint256 inviteCode,
        uint256 invitedById,
        bytes calldata signature
    ) external payable returns (Member memory) {
        if (msg.value < membershipFee) revert PaymentTooSmall();
        verifyInvite(inviteCode, invitedById, signature);

        totalSupply++;
        Member memory newMember = updateMembers(invitedById, totalSupply);

        _safeMint(msg.sender, totalSupply);
        emit NewMember(newMember);
        return newMember;
    }

    /**
     * Join First
     * @dev allows an account to join as the first member of an order without an invite code
     * @return Member
     */
    function joinFirst() external payable returns (Member memory) {
        if (fooCount >= 7) revert InviteRequired();
        if (msg.value < membershipFee) revert PaymentTooSmall();

        fooCount++;
        Member memory newMember = Member(0, 0, 0, fooCount, 0, 0);
        members[fooCount] = newMember;

        _safeMint(msg.sender, fooCount);
        emit NewMember(newMember);
        return newMember;
    }

    /**
     * Public
     */

    /**
     * Invite Code Used?
     * @dev allows public to check if a member's invite code has been used
     * @param _memberId id of the member that created the invite code
     * @param inviteCode invite code to check has been used
     * @return bool
     */
    function inviteUsed(uint256 _memberId, uint256 inviteCode) external view returns (bool) {
        return _inviteUsed[_memberId][inviteCode];
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        uint256 royaltyAmount = (salePrice * _royaltyNumerator) /
            _feeDenominator();

        uint256 order = members[tokenId].order;
        address fooAddress = ownerOf(order);
        uint256 fooLevel = members[order].level;

        if (fooLevel == 22 && fooAddress != address(0)) {
            return (fooAddress, royaltyAmount);
        }

        return (_royaltyAddress, royaltyAmount);
    }

    /**
     * Token URI
     * @dev gets the metadata URI for the token
     * @param tokenId the id of the token
     * @return string the URI for the token metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        if (_useLevelOrderURI) {
            Member storage member = members[tokenId];

            return
                string(
                    abi.encodePacked(
                        _levelOrderURI,
                        "/",
                        member.level.toString(),
                        "/",
                        member.order.toString(),
                        "?memberId=",
                        tokenId.toString()
                    )
                );
        }

        return string(abi.encodePacked(_defaultBaseURI, tokenId.toString(), _uriSuffix));
    }

    /**
     * Withdraw To
     * @dev allows a member or owner to withdraw unclaimed commission
     * @param to the address to transfer funds to
     */
    function withdrawTo(address to) external {
        if (msg.sender == owner()) {
            uint256 balance = ownerBalance();
            if (balance == 0) revert ZeroBalance();

            payable(to).transfer(ownerBalance());
        } else {
            uint256 memberId_ = memberId[msg.sender];
            if (memberId_ == 0) revert NotAuthorised();

            uint256 commission = members[memberId_].unclaimedCommission;
            if (commission == 0) revert ZeroBalance();

            members[memberId_].unclaimedCommission = 0;
            commissionReserve -= commission;

            payable(to).transfer(commission);
            emit MemberWithdrawal(memberId_, commission);
        }
    }

    /**
     * Owner
     */

    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function setDefaultBaseURI(string memory uri) public onlyOwner {
        _defaultBaseURI = uri;
    }

    function setLevelOrderURI(string memory uri) public onlyOwner {
        _levelOrderURI = uri;
    }

    function setRoyaltyAddress(address recipient) external onlyOwner {
        _royaltyAddress = recipient;
    }

    function setRoyaltyNumerator(uint96 feeNumerator) external onlyOwner {
        _royaltyNumerator = feeNumerator;
    }

    function setMembershipFee(uint256 price) external onlyOwner {
        membershipFee = price;
    }

    function toggleTokenURI() external onlyOwner {
        _useLevelOrderURI = !_useLevelOrderURI;
    }

    /**
     * Internal
     */

    function ownerBalance() internal view returns (uint256) {
        return address(this).balance - commissionReserve;
    }

    function updateMemberLevel(Member storage member) private {
        uint256 count = 1;
        uint256 i = 1;
        uint256 level = 0;

        while (member.inviteCount >= count) {
            level++;
            i++;
            count += i;
        }
        if (level > member.level) {
            member.level = level;
        }
    }

    function updateMembers(uint256 invitedById, uint256 newMemberId)
        private
        returns (Member memory newMember)
    {
        Member storage invitedBy = members[invitedById];
        invitedBy.inviteCount++;

        if (invitedBy.level < 22) {
            updateMemberLevel(invitedBy);
        }

        uint256 divisor = 2;

        newMember = Member(
            invitedById,
            0,
            0,
            invitedBy.order,
            0,
            0
        );

        while (invitedById != 0 && divisor <= 8) {
            uint256 commission = membershipFee / divisor;
            members[invitedById].totalCommission += commission;
            members[invitedById].unclaimedCommission += commission;
            commissionReserve += commission;

            divisor *= 2;
            invitedById = members[invitedById].invitedBy;
        }

        members[newMemberId] = newMember;
    }

    function verifyInvite(
        uint256 inviteCode,
        uint256 _memberId,
        bytes memory signature
    ) private {
        bytes32 message = keccak256(abi.encodePacked(inviteCode));
        address signer = ownerOf(_memberId);

        if (!signature.verifySignature(message, signer)) revert InvalidInvite();
        if (_inviteUsed[_memberId][inviteCode]) revert InviteAlreadyUsed();

        _inviteUsed[_memberId][inviteCode] = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (to != address(0)) {
            if (balanceOf(to) > 0) revert WalletQuantityExceeded();
            memberId[to] = tokenId;

            if (from != address(0)) {
                memberId[from] = 0;
            }
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }
}
