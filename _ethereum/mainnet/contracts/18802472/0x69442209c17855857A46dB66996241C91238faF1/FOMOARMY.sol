// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
library SafeMath {
    // Safe addition
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    // Safe subtraction
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    // Safe multiplication
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
}
contract FOMOARMY {
    using SafeMath for uint256;
    string public symbol = "FAR";
    string public name = "FOMOARMY";
    uint8 public decimals = 18;
    uint public _totalSupply = 21_000_000_000 * 10**18;
    address public owner;
    address public myWallet;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    uint public lastActionTimestamp;
    uint public antiBotDelay = 30 seconds;

    uint public initialPrice = 1000000000; // Initial price of the token in wei ($0.0000000001 equivalent)
    uint public priceMultiplier = 100000001;
    uint public tokensSold;
    uint public tokensBought;
    address public admin; // Contract deployer is the initial admin
    mapping(address => bool) public moderators; // Mapping of moderators
    struct Proposal {
        string description;
        uint votes;
        bool executed;
    }
    Proposal[] public proposals;
    mapping(address => mapping(uint => bool)) public voted;

    event NewProposal(uint proposalId, string description);
    event Transfer(address indexed from, address indexed to, uint tokens); // Transfer event

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }
    modifier onlyModerator() {
        require(moderators[msg.sender], "Only moderators can call this function");
        _;
    }
    modifier onlyAfterDelay() {
        require(block.timestamp > lastActionTimestamp + antiBotDelay, "Anti-bot delay not elapsed");
        _;
    }
    constructor() {
        owner = msg.sender;
        myWallet = 0x192b0B28Bfb0F42921bef3BAdBE0946e359F5FC8;
        balances[owner] = _totalSupply;
        admin = msg.sender; // Contract deployer is the initial admin
        moderators[msg.sender] = true; // Admin is the first moderator
        emit Transfer(address(0), owner, _totalSupply);
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function adjustPrice(uint _tokensBought, uint _tokensSold) internal {
        tokensBought += _tokensBought;
        tokensSold += _tokensSold;

        if (tokensBought % 1_000_000_000 == 0 || tokensSold % 1_000_000_000 == 0) {
            uint newPrice = initialPrice * priceMultiplier;
            require(newPrice > initialPrice, "FOMOARMY: Price must increase");
            initialPrice = newPrice;
        }
    }
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }
    function createProposal(string memory _description) public onlyModerator {
        proposals.push(Proposal({
            description: _description,
            votes: 0,
            executed: false
        }));
        emit NewProposal(proposals.length - 1, _description);
    }
    function vote(uint _proposalId) public {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        require(!voted[msg.sender][_proposalId], "Already voted for this proposal");

        proposals[_proposalId].votes++;
        voted[msg.sender][_proposalId] = true;
    }
    function executeProposal(uint _proposalId) public onlyModerator {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        proposals[_proposalId].executed = true;
        // Implement the proposal execution logic here based on the proposal description.
    }
    function addModerator(address _moderator) public onlyAdmin {
        moderators[_moderator] = true;
    }
    function removeModerator(address _moderator) public onlyAdmin {
        moderators[_moderator] = false;
    }
    function _transfer(address _from, address _to, uint _tokens) internal {
        require(_to != address(0), "Transfer to the zero address");
        balances[_from] = balances[_from].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(_from, _to, _tokens);
    }
    function transfer(address _to, uint _tokens) public onlyAfterDelay {
        _transfer(msg.sender, _to, _tokens);
        lastActionTimestamp = block.timestamp;
    }
    function transferFrom(address _from, address _to, uint _tokens) public onlyAfterDelay returns (bool success) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_tokens);
        _transfer(_from, _to, _tokens);
        lastActionTimestamp = block.timestamp;
        return true;
    }
}