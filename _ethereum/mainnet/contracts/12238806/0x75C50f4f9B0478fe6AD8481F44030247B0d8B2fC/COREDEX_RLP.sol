// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./IWETH.sol";
import "./IDeltaToken.sol";
import "./IRebasingLiquidityToken.sol";
import "./UniswapV2Library.sol";
import "./ERC20Upgradeable.sol";

contract COREDEX_RLP is ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    
    uint256 public rlpPerLP;
    address public consumedToken;
    address public owner;
    address public pendingOwner;

    function initialize(string memory name, string memory symbol, uint256 initialSupply, address _consumedToken) public virtual initializer {
        __ERC20_init(name, symbol); // Name, symbol
        _mint(msg.sender, initialSupply);
        // Initially set it to 1LP = 1RLP
        rlpPerLP = 1 ether;
        consumedToken = _consumedToken;
        owner = 0xB2d834dd31816993EF53507Eb1325430e67beefa; // DELTA MULTISIG
    }


    function withdrawGenericERC20(address token, uint256 amountZeroEqualsAll) public onlyOwner {
        if(amountZeroEqualsAll == 0) { amountZeroEqualsAll = IERC20(token).balanceOf(address(this)); }
        IERC20(token).transfer(msg.sender, amountZeroEqualsAll);
    }

    function acceptOwnership() public {
        require(pendingOwner != address(0), "!pending");
        require(msg.sender == pendingOwner, "!auth");
        owner = msg.sender;
        delete pendingOwner;
    }

    function setPendingOwner(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }


    // @notice wraps all LP tokens of the caller, requires allowance
    // @dev intent of this function is to get the balance of the caller, and wrap his entire balance, update the basetoken supply, and issue the caller amount of tokens that we transfered from him
    function wrap() public returns (uint256) {
        return _wrap();
    }

    function _wrap() internal returns (uint256) {
        address _consumedToken = consumedToken;
        uint256 LPBalance = IERC20(_consumedToken).balanceOf(msg.sender);
        require(LPBalance > 0, "No tokens to wrap");

        safeTransferFrom(_consumedToken, msg.sender, owner, LPBalance);
        uint256 garnishedBalance = LPBalance.mul(rlpPerLP).div(1e18);

        _mint(msg.sender, garnishedBalance);
        return garnishedBalance;
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }





}


