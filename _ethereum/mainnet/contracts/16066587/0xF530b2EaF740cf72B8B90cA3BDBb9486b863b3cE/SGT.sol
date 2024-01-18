//SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";
import "./AccessControl.sol";


contract SGT is ERC20Capped , Ownable , AccessControl  {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 private _totalSupply = 1e12;

    constructor(address owner , uint256 initAmount, uint256 cappedAmount) ERC20("SGT", "SGT") ERC20Capped(cappedAmount){
        require(initAmount <= cappedAmount, "ERC20Capped: init must <= cap");
        if (owner == address(0)) {
            owner = msg.sender;
        }
        ERC20._mint(owner , initAmount);
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        _setupRole(BURNER_ROLE, owner);
    }

    function decimals()
        public
        view
        virtual
        override
        returns (uint8)
    {
        return 8;
    }

    /**
     * @dev mint new token to address with fix voting power and expire time
     *
     * Requirements:
     *
     * - caller must have minter role
     */
    function mint(address account, uint256 amount) public
    {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        super._mint(account , amount);
    }

    /**
     * @dev burn a token id
     *
     * Requirements:
     *
     * - caller must have burner role
     */
    function burn(address account, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        // burn
        super._burn(account , amount);
    }
}
