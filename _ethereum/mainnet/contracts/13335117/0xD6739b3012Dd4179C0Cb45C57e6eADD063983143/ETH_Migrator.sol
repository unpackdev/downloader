// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "./AccessControl.sol";
import "./ECDSA.sol";

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Migrator is AccessControl {
    using ECDSA for bytes32;
    
    // Roles
	bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    bytes32 public constant TOKEN_ADDRESS_SETTER_ROLE = keccak256("TOKEN_ADDRESS_SETTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
	bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");

    // Variables
    mapping (address => uint256) public usersStatus;
    address[] public tokensAddress;
    uint256 public minimumRequiredSignature;
    uint256 public startBlock;
    uint256 public migrationStatusBound = 63;

    constructor(address _admin, uint256 _minimumRequiredSignature, address _trusty_address, address _token_setter_address) {
		require(_admin != address(0), "Migrator::constructor: Zero address detected");
		_setupRole(DEFAULT_ADMIN_ROLE, _admin);
		_setupRole(TRUSTY_ROLE, _trusty_address);
		_setupRole(TOKEN_ADDRESS_SETTER_ROLE, _token_setter_address);
		minimumRequiredSignature = _minimumRequiredSignature;
	}

    function verify(bytes32 hash, bytes calldata sigs)
		internal
		view
		returns (address)
	{
        address oracle = hash.recover(sigs);
        require(hasRole(ORACLE_ROLE, oracle), "Migrator::verify: Signer is not valid");
		return oracle;
	}

    function migrate(uint256[] calldata amount, uint256[] calldata expireBlocks, uint256 migrationStatus, bytes[] calldata sigs)
        public 
    {
        require(startBlock < block.number, "Migrator::migrate: Migrator is not started yet");
        require(usersStatus[msg.sender] & migrationStatus == 0, "Migrator::migrate: You have used this option before");
        require(amount.length <= tokensAddress.length, "Migrator::migrate: Amount is not valid");
        require(migrationStatus <= migrationStatusBound, "Migrator::migrate: Migration status is invalid");
        
        address lastOracle;
		for (uint256 index = 0; index < minimumRequiredSignature; ++index) {
            require(expireBlocks[index] >= block.number, "Migrator::migrate: Signature is expired");
            bytes32 _hash = keccak256(abi.encodePacked(msg.sender, expireBlocks[index], migrationStatus, getChainID(), amount));
			address oracle = verify(_hash.toEthSignedMessageHash(), sigs[index]);
			require(oracle > lastOracle, "Migrator::verify: Signers are same");
			lastOracle = oracle;
		}

        for (uint256 index = 0; index < amount.length; ++index) {
            if (amount[index] != 0) {
                IERC20(tokensAddress[index]).transfer(msg.sender, amount[index]);
            }
        }
        usersStatus[msg.sender] = usersStatus[msg.sender] | migrationStatus;
        emit Migrate(msg.sender, amount, migrationStatus);
    }


    function withdrawERC20(address token, address to, uint256 amount)
        public
    {
        require(to != address(0), "Migrator::withdraw: Zero address detected");
        require(hasRole(WITHDRAWER_ROLE, msg.sender), "Caller is not an admin");
        IERC20(token).transfer(to, amount);
        emit Withdraw(token, to, amount);
    }


    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }


    function setTokensAddress(address[] calldata addresses) public {
        require(hasRole(TOKEN_ADDRESS_SETTER_ROLE, msg.sender), "Caller is not allowed to call this function");
        for(uint256 index = 0; index < addresses.length; ++index) {
            require(addresses[index] != address(0), "Migrator::setTokensAddress: Zero address detected");
        }
        tokensAddress = addresses;
        emit SetTokensAddress(addresses);
    }


    function setStartBlock(uint256 value) public {
        require(hasRole(TRUSTY_ROLE, msg.sender),  "Caller is not allowed to call this function");
        startBlock = value;
        emit SetStartBlock(value);
    }


    function setMinimumRequiredSignature(uint256 _minimumRequiredSignature)
		public
	{
		require(
			hasRole(TRUSTY_ROLE, msg.sender),
			 "Caller is not allowed to call this function"
		);
		minimumRequiredSignature = _minimumRequiredSignature;

		emit MinimumRequiredSignatureSet(_minimumRequiredSignature);
	}

    function setMigrationStatusBound(uint256 _migrationStatusBound) public {
        require(
			hasRole(TRUSTY_ROLE, msg.sender),
			 "Caller is not allowed to call this function"
		);
        migrationStatusBound = _migrationStatusBound;

        emit SetMigrationStatusBound(_migrationStatusBound);
    } 

    event Withdraw(address token, address to, uint256 amount);
    event MinimumRequiredSignatureSet(uint256 minimumRequiredSignature);
    event Migrate(address userAddress, uint256[] amount, uint256 migrationStatus);
    event SetTokensAddress(address[] addresses);
    event SetStartBlock(uint256 value);
    event SetMigrationStatusBound(uint256 _migrationStatusBound);
}