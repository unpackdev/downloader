pragma solidity ^0.8.0;

import "./ObscuraMintPass.sol";
import "./AccessControlEnumerable.sol";
import "./ReentrancyGuard.sol";


contract mp_sales is AccessControlEnumerable, ReentrancyGuard{

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    
    uint256 private constant DIVIDER = 10**5;
    address payable _obscuraAddress;

    
    event NewWallet(address _newAddress);


    ObscuraMintPass omp;

    struct Pass {
        uint256 maxTokens;
        uint256 circulatingPublic;
        uint256 circulatingReserved;
        uint256 platformReserveAmount;
        uint256 price;
        uint256 royalty;
        bool active;
        string name;
        string cid;
    }

    constructor(
        address payable _obscuraWallet, 
        address admin,
        address mintPass) {
        _obscuraAddress = _obscuraWallet;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MODERATOR_ROLE, admin);
        omp = ObscuraMintPass(mintPass);
    }

    function changeObscuraAddress(address payable _newAddress) external onlyRole(MODERATOR_ROLE) {
        _obscuraAddress = _newAddress;
        emit NewWallet(_newAddress);
    }


    function buyPass(uint project_number)  external payable nonReentrant {
        Pass memory p;
        (
            p.maxTokens,
            p.circulatingPublic,
            p.circulatingReserved,
            p.platformReserveAmount,
            p.price,
            ,
            p.active,
            ,
            
        ) = omp.passes(project_number);
        require(p.price == msg.value,"Incorrect amount sent");
        require(p.maxTokens - p.platformReserveAmount > p.circulatingPublic, "No mintpasses left");
        require(omp.hasRole(MINTER_ROLE, address(this)),"This sale contract is not allowed to mint");
        omp.mintTo(msg.sender, project_number);
        sendEth(_obscuraAddress,msg.value);
    }

    function sendEth(address destination, uint256 amount) internal {
        (bool sent, ) = destination.call{value: amount}(""); // don't use send or xfer (gas)
        require(sent, "cannot send ETH");
    }

}