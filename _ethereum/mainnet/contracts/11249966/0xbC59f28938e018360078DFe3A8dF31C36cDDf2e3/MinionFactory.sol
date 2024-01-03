// File: browser/IMoloch.sol

pragma solidity ^0.5.11;

interface IMoloch {

    function depositToken() external view returns(address);
    function getProposalFlags(uint256 proposalId) external view
        returns (bool[6] memory);
    function members(address usr) external view
        returns (address, uint256, uint256, bool, uint256, uint256);
    function userTokenBalances(address user, address token) external view
        returns (uint256);

    function cancelProposal(uint256 proposalId) external;
    function withdrawBalance(address token, uint256 amount) external;

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256 proposalId);
}

// File: browser/Minion.sol

pragma solidity 0.5.11;


contract Minion {

    // --- Constants ---
    string public constant MINION_ACTION_DETAILS = '{"isMinion": true, "title":"MINION", "description":"';

    // --- State and data structures ---
    IMoloch public moloch;
    address public molochApprovedToken;
    mapping (uint256 => Action) public actions; // proposalId => Action

    struct Action {
        uint256 value;
        address to;
        address proposer;
        bool executed;
        bytes data;
    }

    // --- Events ---
    event ActionProposed(uint256 proposalId, address proposer);
    event ActionCanceled(uint256 proposalId);
    event ActionExecuted(uint256 proposalId, address executor);

    // --- Modifiers ---
    modifier memberOnly() {
        require(isMember(msg.sender), "Minion::not member");
        _;
    }

    // --- Constructor ---
    constructor(address _moloch) public {
        moloch = IMoloch(_moloch);
        molochApprovedToken = moloch.depositToken();
    }

    // --- Fallback function ---
    function() external payable {}

    // withdraw funds from the moloch
    function doWithdraw(address _token, uint256 _amount) public {
        moloch.withdrawBalance(_token, _amount);
    }

    function proposeAction(
        address _actionTo,
        uint256 _actionValue,
        bytes calldata _actionData,
        string calldata _description
    )
        external
        memberOnly
        returns (uint256)
    {
        // can't call arbitrary functions on parent moloch, and no calls to
        // zero address allows us to check that Minion submitted
        // the proposal without getting the proposal struct from the moloch
        require(
            !(_actionTo == address(0) || _actionTo == address(moloch)),
            "Minion::invalid _actionTo"
        );

        string memory details = string(abi.encodePacked(MINION_ACTION_DETAILS, _description, '"}'));

        uint256 proposalId = moloch.submitProposal(
            address(this),
            0,
            0,
            0,
            molochApprovedToken,
            0,
            molochApprovedToken,
            details
        );

        Action memory action = Action({
            value: _actionValue,
            to: _actionTo,
            proposer: msg.sender,
            executed: false,
            data: _actionData
        });

        actions[proposalId] = action;

        emit ActionProposed(proposalId, msg.sender);
        return proposalId;
    }

    function cancelAction(uint256 _proposalId) external {
        Action memory action = actions[_proposalId];
        require(msg.sender == action.proposer, "Minion::not proposer");
        delete actions[_proposalId];
        emit ActionCanceled(_proposalId);
        moloch.cancelProposal(_proposalId);
    }

    function executeAction(uint256 _proposalId) external returns (bytes memory) {
        Action memory action = actions[_proposalId];
        bool[6] memory flags = moloch.getProposalFlags(_proposalId);

        // minion did not submit this proposal
        require(action.to != address(0), "Minion::invalid _proposalId");
        require(!action.executed, "Minion::action executed");
        require(address(this).balance >= action.value, "Minion::insufficient eth");
        require(flags[2], "Minion::proposal not passed");

        // execute call
        actions[_proposalId].executed = true;
        (bool success, bytes memory retData) = action.to.call.value(action.value)(action.data);
        require(success, "Minion::call failure");
        emit ActionExecuted(_proposalId, msg.sender);
        return retData;
    }

    // --- View functions ---
    function isMember(address usr) public view returns (bool) {
        (, uint shares,,,,) = moloch.members(usr);
        return shares > 0;
    }
}
// File: browser/MinionFactory.sol

pragma solidity 0.5.11;


contract MinionFactory {

   Minion private M;
   
    address[] public Minions;

    event Summoned(address indexed minion, address indexed dao, address summoner, uint version);

    function summonMinion(
        address _dao,
        uint256 _version) public {
            
        M = new Minion(_dao);

        Minions.push(address(M));

        emit Summoned(address(M), _dao, msg.sender, _version);

    }

    function getMinionCount() public view returns (uint256 MinionCount) {
        return Minions.length;
    }
}