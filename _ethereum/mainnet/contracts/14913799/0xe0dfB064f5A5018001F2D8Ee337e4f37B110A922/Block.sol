//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";
import "./Delegatable.sol";
import "./IBlock.sol";

contract Block is
    ERC20Upgradeable,
    Delegatable,
    IBlock,
    ReentrancyGuardUpgradeable
{
    using ECDSA for bytes32;

    event Deposit(address indexed from, uint256 value);
    event ClaimWithhold(address indexed from, uint256 value);

    address public oracleAddress;

    uint256 public constant MINT_ROLE = 1;
    uint256 public constant BURN_ROLE = 2;

    mapping(address => uint256) public latestClaims;

    uint256 public constant MAX_SUPPLY = 1e9 * 1e18;

    function initialize(address _oracleAddress) public initializer {
        __ERC20_init("Block", "BLOCK");
        __Delegatable_init();
        __ReentrancyGuard_init_unchained();
        oracleAddress = _oracleAddress;
    }

    /*
    WRITE FUNCTIONS
    */

    function burnFrom(address account, uint256 amount)
        external
        virtual
        override
        onlyDelegate(BURN_ROLE)
    {
        _burn(account, amount);
    }

    function deposit(uint256 amount) external {
        require(
            block.number > latestClaims[msg.sender],
            "Deposit called too soon after last claim"
        );
        _burn(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function claim(
        address to,
        uint256 amount,
        uint256 withholdAmount,
        uint256 startBlockNumber,
        uint256 endBlockNumber,
        uint256 expTimestamp,
        bytes calldata signature
    ) public virtual override nonReentrant {
        require(
            _verify(
                _hashClaimMessage(
                    to,
                    amount,
                    startBlockNumber,
                    endBlockNumber,
                    expTimestamp
                ),
                signature
            ),
            "Invalid signature"
        );
        require(block.timestamp <= expTimestamp, "Claim expired");
        require(
            startBlockNumber == latestClaims[to] &&
                endBlockNumber > startBlockNumber &&
                endBlockNumber < block.number,
            "Invalid block range"
        );
        require(amount > withholdAmount, "Withhold amount is too large");
        latestClaims[to] = endBlockNumber;
        uint256 mintAmount = amount - withholdAmount;
        _mint(to, mintAmount);
        require(totalSupply() + mintAmount <= MAX_SUPPLY, "Max supply reached");
        if (withholdAmount > 0) {
            emit ClaimWithhold(to, withholdAmount);
        }
    }

    function mint(address to, uint256 amount)
        external
        virtual
        override
        onlyDelegate(MINT_ROLE)
    {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply reached");
        _mint(to, amount);
    }

    /*
    READ FUNCTIONS
    */

    function _verify(bytes32 messageHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return
            messageHash.toEthSignedMessageHash().recover(signature) ==
            oracleAddress;
    }

    function _hashClaimMessage(
        address to,
        uint256 amount,
        uint256 startBlockNumber,
        uint256 endBlockNumber,
        uint256 expTimestamp
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    to,
                    amount,
                    startBlockNumber,
                    endBlockNumber,
                    expTimestamp
                )
            );
    }

    /*
    OWNER FUNCTIONS
    */

    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }
}
