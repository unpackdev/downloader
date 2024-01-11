// OpenZeppelin Contracts v4.4.1
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Counters.sol"; //inherited counter approach for security
import "./Ownable.sol"; //only owner of contract can mint 
import "./ERC721URIStorage.sol"; //storage based URI management
import "./ERC2981.sol"; // ERC2981 NFT Royalty Standard


contract LockBoxManager is ERC721URIStorage, ERC2981, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private counter;
    enum StateType { DocumentInspection, AvailableToShare, SharingRequestPending, SharingWithThirdParty, Terminated }

    struct LockBox {
        //string LockBoxID;
        // string LockBoxName;
        address CurrentAuthorizedUser;
        string ExpirationDate;
        address ThirdPartyRequestor;
        string IntendedPurpose;
        string LockBoxStatus;
        string RejectionReason;
        StateType State;
    }
    mapping (uint256 => LockBox) public lockBoxes;

    address public Owner;
    address public ReupCo;
//    string LockBoxName;
//    string public LockBoxID;
//    address public CurrentAuthorizedUser;
//    string public ExpirationDate;
//    string public Image;
//    address public ThirdPartyRequestor;
//    string public IntendedPurpose;
//    string public LockBoxStatus;
//    string public RejectionReason;
//    StateType public State;
    string public ApplicationName;
    string public WorkflowName;


    event LogContractCreated(string applicationName, string workflowName, address originatingAddress);
    event LogContractUpdated(string applicationName, string workflowName, string action, address originatingAddress);


    modifier onlyReupCo(string memory reason) {
        require(ReupCo == msg.sender, reason);
        _;
    }

    modifier onlyContractOwner(string memory reason){
        require(owner() == msg.sender, reason);
        _;
    }

    // TODO: An ERC721 token requires a name and symbol, change `Token Name` and `TKN` to something you'd like.
    constructor(/* string memory lockBoxName ,*/ address reupCo) ERC721("Token Name", "TKN") {
        Owner = msg.sender;
        //LockBoxName = lockBoxName;
        ApplicationName = "LockBoxManager";
        WorkflowName = "LockBoxManager";

        //State = StateType.DocumentInspection;

        ReupCo = reupCo;

        emit LogContractCreated(ApplicationName, WorkflowName, msg.sender);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyContractOwner("Only owner can set royalty info") {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function BeginInspection(uint256 _lockBoxId) public onlyReupCo("owner cannot begin review process") {
        /* ~Need to update to confirm sender is REUP~ - Done
        Also need to add a function to re-assign owner in case of sale.
        */
        ReupCo = msg.sender;

        lockBoxes[_lockBoxId].LockBoxStatus = "Pending";
        lockBoxes[_lockBoxId].State = StateType.DocumentInspection;
        emit LogContractUpdated(ApplicationName, WorkflowName, "BeginInspection", msg.sender);
    }

    function RejectItem(uint256 _lockBoxId, string memory rejectionReason) public onlyReupCo("only reupCo can reject item") {
        lockBoxes[_lockBoxId].RejectionReason = rejectionReason;
        lockBoxes[_lockBoxId].LockBoxStatus = "Rejected";
        lockBoxes[_lockBoxId].State = StateType.DocumentInspection;
        emit LogContractUpdated(ApplicationName, WorkflowName, "RejectItem", msg.sender);
    }

//    function UploadDocuments(uint256 _lockBoxId, string memory lockBoxID) public onlyReupCo("only reupCo can upload documents") {
//        lockBoxes[_lockBoxId].LockBoxStatus = "Approved";
//        lockBoxes[_lockBoxId].LockBoxID = lockBoxID;
//        lockBoxes[_lockBoxId].State = StateType.AvailableToShare;
//        emit LogContractUpdated(ApplicationName, WorkflowName, "UploadDocuments", msg.sender);
//    }

    function ShareWithThirdParty(uint256 _lockBoxId, address thirdPartyRequestor, string memory expirationDate, string memory intendedPurpose)
    public
    onlyContractOwner("only owner can share with third party") {

        lockBoxes[_lockBoxId].ThirdPartyRequestor = thirdPartyRequestor;
        lockBoxes[_lockBoxId].CurrentAuthorizedUser = lockBoxes[_lockBoxId].ThirdPartyRequestor;

        lockBoxes[_lockBoxId].LockBoxStatus = "Shared";
        lockBoxes[_lockBoxId].IntendedPurpose = intendedPurpose;
        lockBoxes[_lockBoxId].ExpirationDate = expirationDate;
        lockBoxes[_lockBoxId].State = StateType.SharingWithThirdParty;
        emit LogContractUpdated(ApplicationName, WorkflowName, "ShareWithThirdParty", msg.sender);
    }

    function ReleaseLockBoxAccess(uint256 _lockBoxId ) public {
        if (lockBoxes[_lockBoxId].CurrentAuthorizedUser != msg.sender) {
            revert("only current authorized user can release lockBox access");
        }
        lockBoxes[_lockBoxId].LockBoxStatus = "Available";
        lockBoxes[_lockBoxId].ThirdPartyRequestor = address(0x000);
        lockBoxes[_lockBoxId].CurrentAuthorizedUser = address(0x000);
        lockBoxes[_lockBoxId].IntendedPurpose = "";
        lockBoxes[_lockBoxId].State = StateType.AvailableToShare;
        emit LogContractUpdated(ApplicationName, WorkflowName, "AvailableToShare", msg.sender);
    }

    function RevokeAccessFromThirdParty(uint256 _lockBoxId ) public onlyContractOwner("only owner can revoke access from third party") {
        lockBoxes[_lockBoxId].LockBoxStatus = "Available";
        lockBoxes[_lockBoxId].CurrentAuthorizedUser = address(0x000);
        lockBoxes[_lockBoxId].State = StateType.AvailableToShare;
        emit LogContractUpdated(ApplicationName, WorkflowName, "RevokeAccessFromThirdParty", msg.sender);
    }

    function Terminate(uint256 _lockBoxId ) public onlyContractOwner("only owner can terminate") {
        lockBoxes[_lockBoxId].CurrentAuthorizedUser = address(0x000);
        lockBoxes[_lockBoxId].State = StateType.Terminated;
        emit LogContractUpdated(ApplicationName, WorkflowName, "Terminate", msg.sender);
    }

    function mintToken() public onlyReupCo("Only ReupCo can mint a new lockBox") {
        // Mint a token to an address with tokenId of the current supply (starts at 0)

        _safeMint(msg.sender, counter.current());
        counter.increment();
    }

    function getTokenCount() public view returns(uint256) {
        return counter.current();
    }

    function setLockBoxURI(uint256 _lockBoxId, string memory _tokenURI) public onlyReupCo("Only ReupCo can change the tokenURI") {
        _setTokenURI(_lockBoxId, _tokenURI);
        lockBoxes[_lockBoxId].LockBoxStatus = "Approved";
        lockBoxes[_lockBoxId].State = StateType.AvailableToShare;
        emit LogContractUpdated(ApplicationName, WorkflowName, "UploadDocuments", msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*
        --- Optional convenience functions - won't use anytime soon -- remove if helpful ---
    function AcceptSharingRequest() public {
        if (Owner != msg.sender) {
            revert("only owner can accept sharing request");
        }
        CurrentAuthorizedUser = ThirdPartyRequestor;
        State = StateType.SharingWithThirdParty;
        emit LogContractUpdated(ApplicationName, WorkflowName, "AcceptSharingRequest", msg.sender);
    }
    function RejectSharingRequest() public {
        if (Owner != msg.sender) {
            revert("only owner can reject sharing request");
        }
            LockBoxStatus = "Available";
            CurrentAuthorizedUser = address(0x000);
            State = StateType.AvailableToShare;
            emit LogContractUpdated(ApplicationName, WorkflowName, "RejectSharingRequest", msg.sender);
    }
    function RequestLockBoxAccess(string memory intendedPurpose) public {
        if (Owner == msg.sender) {
            revert("owner cannot request access to its own lockBox");
        }
        ThirdPartyRequestor = msg.sender;
        IntendedPurpose = intendedPurpose;
        State = StateType.SharingRequestPending;
                emit LogContractUpdated(ApplicationName, WorkflowName, "RequestLockBoxAccess", msg.sender);
    }
    */

}