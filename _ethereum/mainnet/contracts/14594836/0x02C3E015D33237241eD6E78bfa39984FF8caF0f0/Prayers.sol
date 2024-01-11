// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

// import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./ISwapRouter.sol";

// Paryers is a simple contract that allows for staking CHURCH with a 24 hour lock period.
contract Prayers is ERC20, Ownable {
    IERC20 public immutable CHURCH = IERC20(0x71018cc3D0CCdc7E10C48550554cE4D4E3afd9C1);
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => uint128) public lockedUntil;
    uint128 public totalStakers;

    /* Events */
    event Stake(address user, uint256 amount);
    event Unstake(address user, uint256 amount);

    // Define the PRAYERS contract
    constructor() ERC20("Staked CHURCH", "PRAYERS") {
    }

    // Return info about church and prayers to web3
    function getInfo(address user) external view returns (uint256[] memory) {
      uint256[] memory info = new uint256[](6);
      info[0] = CHURCH.balanceOf(user);
      info[1] = balanceOf(user);
      info[2] = totalSupply();
      info[3] = CHURCH.allowance(user, address(this));
      info[4] = churchPerETH();
      info[5] = totalStakers;

      return info;
    }

    // Overriding transferFrom to ensure tokens can not be moved while locked
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
      address spender = _msgSender();
      _spendAllowance(from, spender, amount);
      require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
      require(block.timestamp >= lockedUntil[from], "Locked");
      _transfer(from, to, amount);
      return true;
    }

    // Overriding transfer to ensure tokens can not be moved while locked
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
      address owner = _msgSender();
      require(balanceOf(owner) >= amount, "ERC20: transfer amount exceeds balance");
      require(block.timestamp >= lockedUntil[msg.sender], "Locked");
      _transfer(owner, to, amount);
      return true;
    }

    // Fetch price of CHURCH
    function churchPerETH() public view returns (uint256){
      address[] memory path = new address[](2);
      path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
      path[1] = address(CHURCH);

      uint256[] memory amountsOut = ISwapRouter(routerAddress).getAmountsOut(10**18, path);
      return amountsOut[1];
    }

    // Allows Owner of contract to change the router address where price is computed
    function setRouter(address _address) public onlyOwner {
      routerAddress = _address;
    }

    // Locks CHURCH and mints PRAYERS
    function stake(uint256 _amount) public {
      require(_amount > 0, "Amount must be greater than 0");
      if (balanceOf(msg.sender) == 0)
        totalStakers += 1;

      _mint(msg.sender, _amount);

      CHURCH.transferFrom(msg.sender, address(this), _amount);
      lockedUntil[msg.sender] = uint128(block.timestamp + (77 hours));
      emit Stake(msg.sender, _amount);
    }

    // Claim back your CHURCH.
    function unstake(uint256 _amount) public {
      require(block.timestamp >= lockedUntil[msg.sender], "Locked");
      require(_amount > 0, "Amount must be greater than 0");

      uint256 totalShares = totalSupply();

      uint256 toTransfer = _amount * CHURCH.balanceOf(address(this)) / totalShares;
      _burn(msg.sender, _amount);
      CHURCH.transfer(msg.sender, toTransfer);

      if (balanceOf(msg.sender) == 0)
        totalStakers -= 1;

      emit Unstake(msg.sender, _amount);
    }
}

