pragma solidity =0.6.8;

import "./IUniswapV2Router02.sol";
import "./ReentrancyGuard.sol";

import "./ERC20.sol";
import "./TransferHelper.sol";

contract Tickets is ReentrancyGuard, ERC20 {
    address public sink;
    address admin;

    mapping( address => bool ) public pool;
    address[] public pooled;
    uint256 public rollover;
    uint256 private seed;

    uint256 public lastWin;
    uint256 public recoveryInterval;

    event Entry(uint256 amount, address indexed entry, uint chance);

    receive() external payable {
        if(msg.sender != admin && address(this).balance > msg.value)
           rollover += msg.value;
    }

    constructor(uint256 initialSupply) ERC20("Tickets", "TITS") public {
        admin = tx.origin;
        sink = msg.sender;
        _mint(msg.sender, initialSupply);
        recoveryInterval = 14 days;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "ONLY_ADMIN_CAN");
        admin = _admin;
    }
    //If the pot hasn't been won in two weeks (should be won daily) then recover it and start anew.
    function recovery() external {
        require(msg.sender == admin, "ONLY_ADMIN_CAN");
        require(block.timestamp > lastWin + recoveryInterval, "To soon");
        _emptyPool();
        _emptyPool();        
    }

    function mint(address minter, uint256 _amount) external {
        require(msg.sender == sink, "ONLY_SINK_CAN_MINT");
        _mint(minter, _amount);
    }

    function burn(uint _amount) external nonReentrant {
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
        //This is o(n) but will never be more than 1.
        for(uint i = 0 ; i < pooled.length ; i++)
        {   delete pool[pooled[i]];
            TransferHelper.safeTransfer(pooled[i], msg.sender, IERC20(pooled[i]).balanceOf(address(this)));
        }
        delete pooled;
        msg.sender.transfer(address(this).balance.sub(rollover));
        rollover = 0;
        lastWin = block.timestamp;
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