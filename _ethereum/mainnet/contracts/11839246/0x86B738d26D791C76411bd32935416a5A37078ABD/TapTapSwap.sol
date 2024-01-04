pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "./ERC20.sol";

contract TapTapSwap is AccessControl {

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    event Swapped(address indexed recipient, bytes8 trans, uint256 amount);

    mapping(bytes8 => bool) private claimed;

    ERC20 private baseToken;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `SIGNER_ROLE` to the
     * account that deploys the contract.
     */
    constructor(ERC20 _baseToken) public {
        require(address(_baseToken) != address(0));
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _msgSender());
        baseToken = _baseToken;
    }

    /**
     * @dev Claim an amount of base token based on amount, unique trans and signature must validate.
     */
    function claim(uint256 amount, bytes8 trans, uint8 v, bytes32 r, bytes32 s) external {
        require(claimed[trans] == false, "Transaction already claimed");

        // This recreates the message that was signed on the client.
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, trans, this)));

        address signer = ecrecover(message, v, r, s);
        require(hasRole(SIGNER_ROLE, signer), "Invalid signer");

        require(baseToken.transfer(msg.sender, amount));
        claimed[trans] = true;

        emit Swapped(msg.sender, trans, amount);
    }

    /**
     * @dev Returns if a given transaction has been claimed.
     */
    function hasClaimed(bytes8 trans) public view returns (bool) {
        return claimed[trans];
    }

    /**
     * @dev Builds a prefixed hash to mimic the behavior of eth_sign.
     */
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function drain() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(baseToken.transfer(msg.sender, baseToken.balanceOf(address(this))));
    }

    function setBaseToken(ERC20 _baseToken) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        baseToken = _baseToken;
    }
    
    function getBaseToken() external view returns (ERC20) {
        return baseToken;
    }
}
