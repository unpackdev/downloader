// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./ECDSA.sol";

contract UsdtDaoToken is ERC20, ERC20Permit, ERC20Votes, Ownable, ERC20Burnable {
    uint256 public immutable claimPeriodEnds;
    uint256 public immutable claimPeriodStart;
    address public immutable signer;
    
    uint256 private totalUsersClaimed;
    mapping(address=>bool) private claimed;
    
    event Claim(address indexed claimant, uint256 amount, uint256 claimIndex);

    /**
     * @dev Constructor.
     * @param _treasuryAddress The address of the Treasury.
     * @param _lpAddress The address of the LP Incentives.
     * @param _contributorsAddress The address of the LP Contributors.
     * @param _claimPeriodStart The claim period start unix time.
     * @param _claimPeriodEnds The claim period ends unix time.
     * @param _signer The signer.
     */
    constructor(address _treasuryAddress, address _lpAddress, address _contributorsAddress, uint256 _claimPeriodStart, uint256 _claimPeriodEnds, address _signer)
        ERC20("USDT DAO", "UDAO")
        ERC20Permit("USDT DAO") {
        
        claimPeriodEnds = _claimPeriodEnds;
        claimPeriodStart = _claimPeriodStart;
        signer = _signer;

        uint256 totalTokens = 99999 * 10**10 * (10**uint256(decimals()));

        _mint(address(this), totalTokens * 50 / 100); // 50% Airdrop
        _mint(_treasuryAddress, totalTokens * 30 / 100); // 30% Treasury
        _mint(_lpAddress, totalTokens * 10 / 100); // 10%  LP Incentives
        _mint(_contributorsAddress, totalTokens * 10 / 100); // 10% Contributors
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev Claims airdropped tokens.
     * @param _amount The amount of the claim being made.
     * @param _v - Must produce valid secp256k1 signature from the holder along with `r` and `s`
     * @param _r - Must produce valid secp256k1 signature from the holder along with `v` and `s`
     * @param _s - Must produce valid secp256k1 signature from the holder along with `r` and `v`
     */
    function claimTokens(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(block.timestamp > claimPeriodStart, "UsdtDao: Claim period not started.");
        require(block.timestamp < claimPeriodEnds, "UsdtDao: Claim period ended.");
        require(!claimed[msg.sender], "UsdtDao: Tokens already claimed by sender.");

        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _amount));
        bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
        require(ECDSA.recover(digest, _v, _r, _s) == signer, "UsdtDao: Invalid signer");
        
        uint256 amountToClaim;
        if(totalUsersClaimed < 10000) {
            amountToClaim = (_amount * 9 / 100); // Get 9%
        } else if(totalUsersClaimed < 25000) {
            amountToClaim = (_amount * 6 / 100); // Get 6%
        } else {
            amountToClaim = (_amount * 3 / 100); // Get 3%
        }
        
        claimed[msg.sender] = true;
        totalUsersClaimed++;
        emit Claim(msg.sender, amountToClaim, totalUsersClaimed);

        _transfer(address(this), msg.sender, amountToClaim);
    }

    /**
    * @dev withdraw the tokens from the contract
    * @param _withdrawAddress - The withdraw address
    * @param _amount - The withdrawal amount
    */
    function withdraw(address _withdrawAddress, uint256 _amount) external onlyOwner {
        require(block.timestamp > claimPeriodEnds, "UsdtDao: Claim period not yet ended");
        require(_withdrawAddress != address(0), "UsdtDao: address can't be the zero address");

        _transfer(address(this), _withdrawAddress, _amount);
    }

    /**
     * @dev Returns true if the address claimed.
     * @param _account The address to check if claimed.
     */
    function hasClaimed(address _account) external view returns (bool) {
        return claimed[_account];
    }

    /**
    * @dev Get the total users claimed number 
    * @return The total users claimed number 
    */
    function getTotalUsersClaimed() external view returns (uint256)  {
        return totalUsersClaimed;
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}