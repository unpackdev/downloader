pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./BaseERC20.sol";

contract RegistryToken01 is BaseERC20, Ownable {

    /* ============ Variables ============ */

    mapping (address => bool) public approvedMinters;

    /* ============ Events ============ */

    event MinterStatusChanged(
        address minter,
        bool approved
    );

    /* ============ Modifiers ============ */

    modifier onlyMinter() {
        require(
            approvedMinters[msg.sender] == true,
            "RegistryToken: only minter"
        );
        _;
    }

    /* ============ Constructor ============ */

    constructor()
        public
        BaseERC20(
            "Zora Registry Token",
            "ZRT",
             2**256-1
        )
    { }

    /* ============ Overrides ============ */

    function decimals()
        public
        pure
        override
        returns (uint8)
    {
        return 0;
    }

    /* ============ Permissioned ============ */

    /**
     * @dev Set who is an approved minter and who isn't
     *
     * @param minter Address of the minter
     * @param status Set status value (true/false)
     */
    function setMinterStatus(
        address minter,
        bool status
    )
        public
        onlyOwner
    {
        approvedMinters[minter] = status;

        emit MinterStatusChanged(minter, status);
    }

    /**
     * @dev Mint tokens. Can only be called by valid minter.
     *
     * @param to Destination to send tokens to
     * @param value Number of tokens to send
     */
    function mintTokens(
        address to,
        uint256 value
    )
        public
        onlyMinter
    {
        _mint(to, value);
    }

    /**
     * @dev Burn tokens. Can only be called by valid minter.
     *
     * @param from User to burn tokens from.
     * @param value Number of tokens to burn.
     */
    function burnTokens(
        address from,
        uint256 value
    )
        public
        onlyMinter
    {
        _burn(from, value);
    }

}