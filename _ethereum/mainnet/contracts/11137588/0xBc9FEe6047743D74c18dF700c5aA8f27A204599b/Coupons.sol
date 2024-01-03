pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./TransferHelper.sol";

contract Coupons is ERC20 {
    address public sink;
    address admin;

    mapping( address => bool ) public pool;
    address[] public pooled;
    uint256 public rollover;
    uint256 private seed;

    event Entry(uint256 amount, address indexed entry, uint chance);
    receive() external payable {
        if(msg.sender != admin && address(this).balance > msg.value)
           rollover += msg.value;
    }

    constructor(uint256 initialSupply) ERC20("Coupons", "CPN") public {
        admin = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "ONLY_ADMIN_CAN");
        admin = _admin;
    }

    function setSink(address _sink) external {
        require(msg.sender == admin, "ONLY_ADMIN_CAN");
        require(address(sink) == address(0), "ONLY_SET_ONCE");
        sink = _sink;
    }

    function mint(address minter, uint256 _amount) external {
        require(msg.sender == sink, "ONLY_SINK_CAN_MINT");
        _mint(minter, _amount);
    }

    function burn(uint _amount) external {
        require(msg.sender == tx.origin, "LIMITING_CONTRACT_INTERACTIONS");
        _burn(msg.sender, _amount);
        uint chances = _amount / 1 ether;
        uint chance = _random();
        if( chances > chance )
            _emptyPool();
        
        emit Entry(chances, msg.sender, chance);            
    }

    function fillPool(uint256 _amount, address _token) external {
        require(msg.sender == sink, "ONLY_SINK_CAN_FILL");        
        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
        if(pool[_token] == false) pooled.push(_token);
        pool[_token] = true;
    }

    function _emptyPool() private {
        for(uint i = 0 ; i < pooled.length ; i++)
        {   delete pool[pooled[i]];
            TransferHelper.safeTransfer(pooled[i], msg.sender, IERC20(pooled[i]).balanceOf(address(this)));
        }
        delete pooled;
        msg.sender.transfer(address(this).balance.sub(rollover));
        rollover = 0;
    }

    function _random() private returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, now, pooled.length, rollover, blockhash(block.number-1))));
        seed += (rollover % 3)+1;
        randomHash = uint(keccak256(abi.encodePacked(randomHash, seed)));
        return randomHash % 1000;
    }     

    function poolSize() external view returns (uint256) {
        return pooled.length;
    }

}