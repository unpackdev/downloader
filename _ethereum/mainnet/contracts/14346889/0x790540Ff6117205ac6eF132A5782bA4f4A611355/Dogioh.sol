pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Dogioh is ERC20, AccessControl, ERC20Burnable {
    using SafeMath for uint256;

    // the amount of fee during every transfer, i.e.  2000 = 0,05%, 333 = 0,3%, 100 = 1%, 50 = 2%, 40 = 2.5%
    uint32 public feeDivisor;
    //address where the fees will be sent
    address public feeAddress;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public whitelistedReceiver;

    constructor(
        uint32 _feeDivisor,
        address _feeAddress
    ) ERC20("Dogioh Token", "Dogioh") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        feeDivisor = _feeDivisor;
        feeAddress = _feeAddress;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
    @notice burn is an only owner function that allows the owner to burn  tokens from an input account
    @param _from is the address where the tokens will be burnt
    @param _amount is the amount of token to be burnt
    **/
    function burn(address _from, uint256 _amount) public onlyRole(BURNER_ROLE) {
        _burn(_from, _amount);
    }

    /**
    @notice setFeeAddress is an only DEFAULT_ADMIN_ROLE function that allows the owner to change the feeAddress
    @param _feeAddress is the address that will receive the fee
    **/

    function setFeeAddress(address _feeAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        feeAddress = _feeAddress;
    }

        /**
    @notice addWhitelistedReceiver is an only DEFAULT_ADMIN_ROLE function that allows the owner to insert an address inside the whitelist of receiver
    **/
    function addWhitelistedReceiver(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistedReceiver[_address] = true;
    }

    /**
    @notice removeWhitelistedReceiver is an only DEFAULT_ADMIN_ROLE function that allows the owner to remove an address from the whitelist of receiver
    **/
    function removeWhitelistedReceiver(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistedReceiver[_address] = false;
    }

    /**
    @notice addWhitelisted is an only DEFAULT_ADMIN_ROLE function that allows the owner to insert an address inside the whitelist
    **/
    function addWhitelisted(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelisted[_address] = true;
    }

    /**
    @notice removeWhitelisted is an only DEFAULT_ADMIN_ROLE function that allows the owner to remove an address from the whitelist
    **/
    function removeWhitelisted(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelisted[_address] = false;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (whitelisted[msg.sender] == false || whitelisted[recipient] == false) {
            // calculate transfer fee and send to predefined wallet
            uint256 feeAmount = amount.div(
                feeDivisor
            );
            super.transfer(feeAddress, feeAmount);
            return
                super.transfer(
                    recipient,
                    amount
                        .sub(feeAmount)
                );
        } else return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (whitelisted[sender] == false || whitelisted[recipient] == false) {
            // calculate transfer fee and send to predefined wallet
            uint256 feeAmount = amount.div(
                feeDivisor
            );
            super.transferFrom(
                sender,
                feeAddress,
                feeAmount
            );

            return
                super.transferFrom(
                    sender,
                    recipient,
                    amount
                        .sub(feeAmount)
                );
        } else return super.transferFrom(sender, recipient, amount);
    }

    function setMinter(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _address);
    }

    function removeMinter(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ROLE, _address);
    }

    function setAdmin(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, _address);
        _grantRole(MINTER_ROLE, _address);
        _grantRole(BURNER_ROLE, _address);
    }

    function removeAdmin(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, _address);
        _revokeRole(BURNER_ROLE, _address);
        _revokeRole(MINTER_ROLE, _address);
    }

    function setBurner(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(BURNER_ROLE, _address);
    }

    function removeBurner(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(BURNER_ROLE, _address);
    }
}
