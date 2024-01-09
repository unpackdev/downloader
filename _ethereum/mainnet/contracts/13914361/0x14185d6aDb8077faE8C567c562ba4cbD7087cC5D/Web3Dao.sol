// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./VStrings.sol";

/**
 * @dev An ERC20 token for Web3Dao.
 */
contract Web3DaoToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    using VStrings for *;

    mapping(address=>bool) private claimed;
    event Claim(address indexed claimant, uint256 amount);

    // total supply be 2.1 Billion
    // 50% Airdrop To Web3 Users
    // 20% Staking Incentive
    // 15% WEB3 DAO Governance Treasury
    // 10% LP Tncentive
    // 5% Development Committee
    uint256 constant airdropSupply = 1_050_000_000e8;
    uint256 constant daoSupply = 1_050_000_000e8;//Staking/Governance Treasury/LP/Dev

    uint256 public constant claimPeriodEnds = 1656604800; // Jul 1, 2022

    bool public pause = false;
    address public signatory = address(0x0F3fFE1C51BB3f0489516B986f27f4387D21fe54);

    /**
     * @dev Constructor.
     * @param daoAddress The address of the DAO.
     */
    constructor(
        address daoAddress
    )
        ERC20("Web3 DAO", "WEB3")
        ERC20Permit("Web3 DAO")
    {
        _mint(address(this), airdropSupply);
        _mint(daoAddress, daoSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }

    function setPause( bool _state) external onlyOwner{
        pause = _state;
    }

    function setSignatory( address _sig) external onlyOwner{
        require(_sig!=address(0),"EROR");
        signatory = _sig;
    }

    function claimTokens(uint256 amount, uint8 v, bytes32 r, bytes32 s) public{
        require(!pause,"PAUSEING");

        string memory message = amount.toString().toSlice().concat("0x".toSlice());
        message = message.toSlice().concat(msg.sender.toAsciiString().toSlice());

        if(v<27){
            v += 27;
        }
        address sig = verifyString(message, v, r, s);
        require(sig==signatory,"INVALID SIGNATURE");

        require(!claimed[msg.sender], "Web3Dao: Tokens already claimed.");
        claimed[msg.sender] = true;
    
        emit Claim(msg.sender, amount);

        _transfer(address(this), msg.sender, amount);
    }

    /**
     * @dev Allows the owner to sweep unclaimed tokens after the claim period ends.
     * @param dest The address to sweep the tokens to.
     */
    function sweep(address dest) public onlyOwner {
        require(block.timestamp > claimPeriodEnds, "Web3Dao: Claim period not yet ended");
        _transfer(address(this), dest, balanceOf(address(this)));
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param account The address to check if claimed.
     */
    function hasClaimed(address account) public view returns (bool) {
        return claimed[account];
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    } 


    function verifyString(string memory message, uint8 v, bytes32 r,
                bytes32 s) public pure returns (address signer) {

        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";

        uint256 lengthOffset;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }

        // Maximum length we support
        require(length <= 999999);

        // The length of the message's length in base-10
        uint256 lengthLength = 0;

        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;

        // Move one digit of the message length to the right at a time
        while (divisor != 0) {

            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }

            // Found a non-zero digit or non-leading zero digit
            lengthLength++;

            // Remove this digit from the message length's current value
            length -= digit * divisor;

            // Shift our base-10 divisor over
            divisor /= 10;

            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;

            assembly {
                mstore8(lengthOffset, digit)
            }
        }

        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }

        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }

        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));

        return ecrecover(check, v, r, s);
    }
}