// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract Potion is Ownable, ERC20, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public lastMintedBlock;

    modifier blockThrottle{
        require(block.number > lastMintedBlock);
        _;
        lastMintedBlock = block.number;
    }

    constructor() ERC20("POTION","POTION") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function changeMinter(address _to) external onlyOwner(){
        require(_to != address(0),"Recipient address cannot be zero address");
         _grantRole(MINTER_ROLE, _to);
    }

    function mintTo(address _to) external onlyRole(MINTER_ROLE) blockThrottle{
        require(_to != address(0),"Recipient address cannot be zero address");
        _mint(_to,1 * 10**18);
    }

}