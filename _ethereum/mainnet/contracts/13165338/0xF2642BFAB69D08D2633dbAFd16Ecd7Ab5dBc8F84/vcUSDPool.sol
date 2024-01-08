// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./AccessControl.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./vcUSD.sol";
import "./WalletTokensalePrivate.sol";



contract vcUSDPool is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    bool public saleUnlocked = true;
    bool public claimUnlocked = true;
    mapping(bytes32 => bool) hashes;

    address public vcUSDAddress;
    address public USDTAddress;
    address public service_backend;
    address public privateAddress;

    event vcUSDBuy(address indexed user, uint256 amount, uint256 time);
    event vcUSDSell(address indexed user, uint256 amount, uint256 time);
    event RefferalsClaimed(address indexed user, uint256 amount, uint256 time);

    constructor(
        address _USDTAddress,
        address _vcUSDAddress,
        address _service_backend
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SERVICE_ROLE, ADMIN_ROLE);

        vcUSDAddress = _vcUSDAddress;
        USDTAddress = _USDTAddress;
        service_backend = _service_backend;
        _setupRole(SERVICE_ROLE, service_backend);
    }

    modifier refferalClaimUnlocked() {
        require(claimUnlocked, "Claim is locked");
        _;
    }

    modifier salesUnlocked() {
        require(saleUnlocked, "Sales is locked!");
        _;
    }

    function airdrop(address[] calldata _addresses, uint256[] calldata _amounts)
        external
    {
        require(hasRole(SERVICE_ROLE, msg.sender), "Caller is not an service");
        require(
            _addresses.length == _amounts.length,
            "Arrays must have the same length"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            vcUSDToken(vcUSDAddress).mint(_addresses[i], _amounts[i]);
        }
    }

    function buyVcUSDBackend(uint256 _amount, address _recepient) external {
        require(hasRole(SERVICE_ROLE, msg.sender), "Caller is not an service");
        require(_amount > 0, "Amount must be above zero!");

        vcUSDToken(vcUSDAddress).burn(service_backend, _amount);

        ERC20(USDTAddress).safeTransfer(_recepient, _amount);

        emit vcUSDBuy(_recepient, _amount, block.timestamp);
    }

    function sellVcUsdBackend(uint256 _amount) external {
        require(hasRole(SERVICE_ROLE, msg.sender), "Caller is not an service");
        require(_amount > 0, "Amount must be above zero!");

        vcUSDToken(vcUSDAddress).mint(service_backend, _amount);

        emit vcUSDSell(service_backend, _amount, block.timestamp);
    }

    function buyVcUSD(uint256 _amount) external salesUnlocked nonReentrant {
        require(_amount > 0, "Amount must be above zero!");

        vcUSDToken(vcUSDAddress).burn(msg.sender, _amount);

        ERC20(USDTAddress).safeTransfer(msg.sender, _amount);

        emit vcUSDBuy(msg.sender, _amount, block.timestamp);
    }

    function sellVcUsd(uint256 _amount) external salesUnlocked nonReentrant {
        require(_amount > 0, "Amount must be above zero!");

        ERC20(USDTAddress).safeTransferFrom(msg.sender, address(this), _amount);

        vcUSDToken(vcUSDAddress).mint(msg.sender, _amount);

        emit vcUSDSell(msg.sender, _amount, block.timestamp);
    }

    function updateServiceAddress(address _service_backend) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");

        service_backend = _service_backend;
    }

    function updateSalesState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        saleUnlocked = _state;
    }

    function updateVcUSDAddress(address _vcUSDAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        vcUSDAddress = _vcUSDAddress;
    }

    function claim(
        bytes32 hashedMessage,
        uint256 _amount,
        uint256 _sequence,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        address _from
    ) external nonReentrant  refferalClaimUnlocked  {
        address service = recover(hashedMessage, _v, _r, _s);
        require(hasRole(SERVICE_ROLE, service), "Signed not by a service");
        
        
        //TO-DO _form to msg.sender
        bytes32 message = keccak256(
            abi.encodePacked(msg.sender, _amount, _sequence)
        );

        message = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );

        // return (message, service);
        
        require(hashedMessage == message, "Incorrect hashed message");

        require(
            !hashes[message],
            "Sequence amount already claimed or dublicated."
        );

        hashes[message] = true;

        WalletTokensalePrivate(_from).removeToken(
            msg.sender,
            _amount,
            USDTAddress
        );

        emit RefferalsClaimed(msg.sender, _amount, block.timestamp);

        
    }
    

    function removeToken(
        address _recepient,
        uint256 _amount,
        address tokenAddress
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        
        ERC20(tokenAddress).safeTransfer(_recepient, _amount);
    }

    function updateClaimState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        claimUnlocked = _state;
    }


    function recover(
        bytes32 hashedMsg,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
        address signer = ecrecover(hashedMsg, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }
}
