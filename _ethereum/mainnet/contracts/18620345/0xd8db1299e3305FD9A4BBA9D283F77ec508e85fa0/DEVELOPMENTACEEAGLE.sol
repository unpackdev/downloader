//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function SupplyPerPhase() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract DEVELOPMENTACEEAGLE  {
    IERC20 public ACEEAGLE = IERC20(0x560D9A8beaAE8B1bFFEEA1fc6ecB1F32DFB9495E);


    address payable public owner;

    uint256 public totalUsers;
  
   
   
   

    bool public AirdropNotToClaim;
    mapping(address => bool) public  oldUser;

    struct user {
     
        uint256 token_balance;
        uint256 claimed_token;
    }

    mapping(address => user) public  users;
    mapping(address => uint256) public wallets;

    modifier onlyOwner() {
        require(msg.sender == owner, "ACEEAGLE: Not an owner");
        _;
    }

  
    event ClaimToken(address indexed _user, uint256 indexed _amount);

    constructor() {
        owner = payable(0xD25D0bC76DC005962b3D106Ce8B32888e9d09e5e);
   
        AirdropNotToClaim = false;
    }

    receive() external payable {}

 

function whiteList(address[] calldata _addresses, uint256[] calldata _value) external onlyOwner() {
    require(_addresses.length == _value.length, "ACEEAGLE: Array lengths do not match");

    for (uint256 i = 0; i < _addresses.length; i++) {
        address _address = _addresses[i];
        uint256 value = _value[i];
        users[_address].token_balance = users[_address].token_balance + value;
             if (oldUser[_addresses[i]] != true) {
            totalUsers += 1;
        }
    }
     
   
}


    // Claim ACEEAGLE tokens
    function claimTokens() external {
        require(AirdropNotToClaim == false, "ACEEAGLE : ACEEAGLE  is not finished");
        require(users[msg.sender].token_balance != 0, "ACEEAGLE: 0 to claim");

        user storage _usr = users[msg.sender];

        ACEEAGLE.transfer(msg.sender, _usr.token_balance);
        _usr.claimed_token += _usr.token_balance;
        _usr.token_balance -= _usr.token_balance;

        emit ClaimToken(msg.sender, _usr.token_balance);
    }


    function startAirdropClaim(bool _off) external onlyOwner {
        AirdropNotToClaim = _off;
    }
  
    

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        ACEEAGLE = IERC20(_token);
    }

    // to draw funds for 
    function transferFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
        token.transfer(msg.sender, _value);
    }

    
}