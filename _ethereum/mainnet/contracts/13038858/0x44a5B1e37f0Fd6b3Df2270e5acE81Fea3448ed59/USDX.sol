//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract USDX is ERC20,
                 Ownable,
                 ReentrancyGuard {

    /*
      Bitfield of allowed operations per token:
         0x01 -> Deposit
         0x02 -> Withdraw
     */
    mapping(address => uint8) public tokensAllowed;

    event Deposit(address indexed token, uint256 amount);
    event Withdraw(address indexed token, uint256 amount);
    event PoolUpdate(address indexed token, uint8 flags);

    constructor() ERC20("USDX", "USDX") Ownable() ReentrancyGuard() {

    }

    // Before calling deposit(), you must approve the amount yourself:
    //
    //   ERC20(token).approve(USDX, amount);
    //
    function deposit(address token, uint256 amount) external nonReentrant {
        require(depositAllowed(token), "Operation not allowed for this token");
        require(ERC20(token).transferFrom(msg.sender, address(this), amount));
        uint256 usdxAmount = normalizedAmount(token, amount);
        _mint(msg.sender, usdxAmount);
        emit Deposit(token, usdxAmount);
    }

    function withdraw(address token, uint256 amount) external nonReentrant {
        require(withdrawAllowed(token), "Operation not allowed for this token");
        uint256 usdxAmount = normalizedAmount(token, amount);
        _burn(msg.sender, usdxAmount);
        require(ERC20(token).transfer(msg.sender, amount));
        emit Withdraw(token, usdxAmount);
    }

    // Normalize the amount of a specified ERC20 to a USDX amount
    // using the difference in the number of decimals.
    function normalizedAmount(address token, uint256 amount) public view returns (uint256) {
        uint8 decimals = ERC20(token).decimals();
        if (decimals < this.decimals()) {
            amount *= 10 ** (this.decimals() - decimals);
        } else if (decimals > this.decimals()) {
            amount /= 10 ** (decimals - this.decimals());
        }
        return amount;
    }

    function depositAllowed(address token) public view returns (bool) {
        return 0 != tokensAllowed[token] & 0x01;
    }
    function withdrawAllowed(address token) public view returns (bool) {
        return 0 != tokensAllowed[token] & 0x02;
    }

    struct FlagUpdate {
        address token;
        uint8 flags;
    }

    // USDX's security relies on the sum of the security of the stables that are
    // allowed into it. In addition to the normal tokenomic considerations (who
    // can mint, what controls supply, etc.) several functions should be audited
    // for any unexpected behavior or hazards:
    //
    //  - transfer()
    //  - transferFrom()
    //  - decimals() should return a constant
    //
    function updateTokenUsability(FlagUpdate[] memory updates) public onlyOwner {
        for (uint i = 0; i < updates.length; i++) {
            FlagUpdate memory u = updates[i];
            tokensAllowed[u.token] = u.flags;
            emit PoolUpdate(u.token, u.flags);
        }
    }
}
