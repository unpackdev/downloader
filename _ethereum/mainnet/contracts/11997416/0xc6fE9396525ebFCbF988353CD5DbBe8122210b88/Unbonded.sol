pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract Unbonded is OwnableUpgradeSafe {
            
    using SafeMath for uint256;

    uint public TGE;
    uint public constant month = 30 days;
    uint constant decimals = 18;
    uint constant decMul = uint(10) ** decimals;
    
    address public communityAddress;

    uint public constant PRIVATE_POOL = 1000000 * decMul;
    uint public constant COMMUNITY_POOL = 1200000 * decMul;

    //  the current values should be updated according to values which  we expect to receive from client
    uint public currentPrivatePool;
    uint public currentCommunityPool;
    
    IERC20 public token;
    
    mapping(address => uint) public privateWhitelist;

    constructor(
        address _communityAddress,
        uint _currentPrivatePool,
        uint _currentCommunityPool
    ) public {
        __Ownable_init_unchained();

        communityAddress = _communityAddress;
        currentPrivatePool = _currentPrivatePool;
        currentCommunityPool = _currentCommunityPool;
    }

    /**
     * @dev Sets the AddXyz ERC-20 token contract address
     */
    function setTokenContract(address _tokenAddress) public onlyOwner {
        require (true == isContract(_tokenAddress), "require contract");
        token = IERC20(_tokenAddress);
    }

    /**
     * @dev Sets the current TGE from where the vesting period will be counted. Can be used only if TGE is zero.
     */
    function setTGE(uint _date) public onlyOwner {
        require(TGE == 0, "TGE has already been set");
        TGE = _date;
    }
    
    /**
     * @dev Sets each address from `addresses` as the key and each balance
     * from `balances` to the privateWhitelist. Can be used only by an owner.
     */
    function addToWhitelist(
        address[] memory addresses,
        uint[] memory balances
    )
        public
        onlyOwner
    {
        require(
            addresses.length == balances.length,
            "Invalid request length"
        );
        
        for (uint i = 0; i < addresses.length; i++) {
            privateWhitelist[addresses[i]] = balances[i];
        }
    }
    
    /**
     * @dev claim private tokens from the contract balance.
     * `amount` means how many tokens must be claimed.
     * Can be used only by an owner or by any whitelisted person
     */
    function claimPrivateTokens(uint amount) public {
        require(
            privateWhitelist[msg.sender] > 0,
            "Sender is not whitelisted"
        );
        require(
            privateWhitelist[msg.sender] >= amount,
            "Exceeded token amount"
        );
        require(
            currentPrivatePool >= amount,
            "Exceeded private pool"
        );
        require(amount > 0, "Zero amount claiming is forbidden");

        currentPrivatePool = currentPrivatePool.sub(amount);
        
        privateWhitelist[msg.sender] = privateWhitelist[msg.sender]
            .sub(amount);
        token.transfer(msg.sender, amount);
    }
    
    /**
     * @dev claim community tokens from the contract balance.
     * Can be used only by an owner or from communityAddress
     */
    function claimCommunityTokens() public {
        require(
            msg.sender == communityAddress ||
            msg.sender == owner(),
            "Unauthorised sender"
        );
        require(TGE > 0, "TGE must be set");
        
        // No vesting period
        uint initialClaimAmount = 480000 * decMul;
        uint amount = 0;
        uint256 periodsPass = now.sub(TGE).div(month);

        if (currentCommunityPool == COMMUNITY_POOL) {
            require(periodsPass >= 0, "Vesting period");
            currentCommunityPool = currentCommunityPool.sub(initialClaimAmount);
            amount = amount.add(initialClaimAmount);
        } else {
            require(periodsPass >= 1, "Vesting period");
        }
        periodsPass = periodsPass > 10 ? 10 : periodsPass;

        uint amountToClaim = COMMUNITY_POOL.div(10);
        for (uint i = 1; i <= periodsPass; i++) {
            if (
                currentCommunityPool <= COMMUNITY_POOL
                    .sub(amountToClaim.mul(i))
                    .sub(initialClaimAmount)
            ) {
                continue;
            }
            currentCommunityPool = currentCommunityPool.sub(amountToClaim);
            amount = amount.add(amountToClaim);
        }

        // 10% each month
        require(amount > 0, "nothing to claim");

        token.transfer(communityAddress, amount);
    }

    function isContract(address addr) private returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}